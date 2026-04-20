package Developer::Dashboard::ActionRunner;

use strict;
use warnings;

our $VERSION = '2.72';

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use Digest::SHA qw(sha256_hex);
use File::Spec;
use POSIX qw(setsid strftime);

use Developer::Dashboard::Codec qw(encode_payload decode_payload);
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::Platform qw(shell_command_argv);

# new(%args)
# Constructs an action runner bound to file and path registries.
# Input: files and paths objects.
# Output: Developer::Dashboard::ActionRunner object.
sub new {
    my ( $class, %args ) = @_;
    my $files = $args{files} || die 'Missing file registry';
    my $paths = $args{paths} || die 'Missing path registry';
    return bless {
        files => $files,
        paths => $paths,
    }, $class;
}

# run_page_action(%args)
# Executes a page action after applying trust checks and action kind routing.
# Input: page document, action hash, source string, and optional params hash.
# Output: result hash reference or dies on unsupported/untrusted actions.
sub run_page_action {
    my ( $self, %args ) = @_;
    my $page   = $args{page}   || die 'Missing page';
    my $action = $args{action} || die 'Missing action';
    my $source = $args{source} || 'saved';
    die 'Page action must be a hash' if ref($action) ne 'HASH';

    my $kind = $action->{kind} || 'builtin';
    if ( $kind eq 'builtin' ) {
        return $self->_run_builtin_action(
            action => $action,
            page   => $page,
            params => $args{params} || {},
        );
    }

    if ( $kind eq 'command' ) {
        die "Action '$action->{id}' is not trusted for source '$source'\n"
          if !$self->_is_action_trusted( page => $page, action => $action, source => $source );
        return $self->run_command_action(
            command    => $action->{command},
            cwd        => $action->{cwd},
            env        => $action->{env},
            timeout_ms => $action->{timeout_ms},
            background => $action->{background},
        );
    }

    die "Unsupported action kind '$kind'\n";
}

# encode_action_payload(%args)
# Encodes a self-contained action transport payload for a page action.
# Input: page document, action hash, and source string.
# Output: encoded action token string.
sub encode_action_payload {
    my ( $self, %args ) = @_;
    my $page   = $args{page}   || die 'Missing page';
    my $action = $args{action} || die 'Missing action';
    my $payload = {
        version      => 1,
        source       => $args{source} || 'saved',
        page_source  => $page->can('canonical_instruction') ? $page->canonical_instruction : '',
        action       => $action,
        trusted_id   => sha256_hex(
            join ':',
            $args{source} || 'saved',
            ( $page->as_hash->{id} || '' ),
            ( $action->{id} || '' ),
            ( $page->can('canonical_instruction') ? $page->canonical_instruction : '' ),
        ),
    };
    return encode_payload( json_encode($payload) );
}

# decode_action_payload($token)
# Decodes an encoded action transport token.
# Input: encoded action token string.
# Output: decoded action payload hash reference.
sub decode_action_payload {
    my ( $self, $token ) = @_;
    my $payload = Developer::Dashboard::JSON::json_decode( decode_payload($token) );
    die 'Action payload must be a hash' if ref($payload) ne 'HASH';
    return $payload;
}

# run_encoded_action(%args)
# Decodes and executes an encoded action transport payload.
# Input: encoded action token and optional params hash.
# Output: action result hash reference.
sub run_encoded_action {
    my ( $self, %args ) = @_;
    my $payload = $self->decode_action_payload( $args{token} || '' );
    my $page_class = 'Developer::Dashboard::PageDocument';
    my $page = $page_class->from_instruction( $payload->{page_source} || '' );
    return $self->run_page_action(
        action => $payload->{action},
        page   => $page,
        source => $payload->{source} || 'saved',
        params => $args{params} || {},
    );
}

# run_command_action(%args)
# Executes a local command action synchronously or in the background.
# Input: command, cwd, env, timeout_ms, and background options.
# Output: structured result hash reference.
sub run_command_action {
    my ( $self, %args ) = @_;
    my $cmd = $args{command} || die 'Missing command';
    my $cwd = $args{cwd} || cwd();
    if ( !File::Spec->file_name_is_absolute($cwd) && $self->{paths}->can($cwd) ) {
        $cwd = $self->{paths}->$cwd();
    }
    die "Action cwd '$cwd' does not exist" if !-d $cwd;

    my $env = ref( $args{env} ) eq 'HASH' ? { %{ $args{env} } } : {};
    my $timeout_ms = $args{timeout_ms} || 30_000;
    my $background = $args{background} ? 1 : 0;

    if ($background) {
        my $pid = fork();
        die "Unable to fork background action: $!" if !defined $pid;
        if ($pid) {
            return {
                background => 1,
                pid        => $pid,
                started_at => _now_iso8601(),
            };
        }
        setsid();
        open STDIN, '<', File::Spec->devnull() or die $!;
        open STDOUT, '>>', $self->{files}->dashboard_log or die $!;
        open STDERR, '>>', $self->{files}->dashboard_log or die $!;
        $self->_run_command(
            cmd        => $cmd,
            cwd        => $cwd,
            env        => $env,
            timeout_ms => $timeout_ms,
        );
        exit 0;
    }

    return $self->_run_command(
        cmd        => $cmd,
        cwd        => $cwd,
        env        => $env,
        timeout_ms => $timeout_ms,
    );
}

# _run_builtin_action(%args)
# Executes one of the built-in safe dashboard actions.
# Input: action hash, page document, and optional params hash.
# Output: structured result hash reference.
sub _run_builtin_action {
    my ( $self, %args ) = @_;
    my $action = $args{action};
    my $page   = $args{page};
    my $id     = $action->{builtin} || $action->{id} || '';

    if ( $id eq 'page.source' ) {
        return {
            kind         => 'builtin',
            content_type => 'text/plain; charset=utf-8',
            body         => $page->canonical_instruction,
        };
    }

    if ( $id eq 'page.state' ) {
        return {
            kind         => 'builtin',
            content_type => 'application/json; charset=utf-8',
            body         => json_encode( $page->as_hash->{state} || {} ),
        };
    }

    if ( $id eq 'paths.list' ) {
        return {
            kind         => 'builtin',
            content_type => 'application/json; charset=utf-8',
            body         => json_encode(
                {
                    home       => $self->{paths}->home,
                    runtime    => $self->{paths}->runtime_root,
                    dashboards => $self->{paths}->dashboards_root,
                    config     => $self->{paths}->config_root,
                    cli        => $self->{paths}->cli_root,
                }
            ),
        };
    }

    die "Unsupported builtin action '$id'\n";
}

# _is_action_trusted(%args)
# Determines whether a page action may execute for the given source.
# Input: page document, action hash, and source string.
# Output: boolean trust flag.
sub _is_action_trusted {
    my ( $self, %args ) = @_;
    my $page   = $args{page};
    my $action = $args{action};
    my $source = $args{source} || '';
    return 1 if $action->{safe};
    return 1 if $source eq 'saved' || $source eq 'provider';

    my $permissions = $page->as_hash->{permissions} || {};
    return 0 if !$permissions->{allow_untrusted_actions};
    if ( ref( $permissions->{trusted_actions} ) eq 'ARRAY' ) {
        my %allowed = map { $_ => 1 } @{ $permissions->{trusted_actions} };
        return $allowed{ $action->{id} } ? 1 : 0;
    }
    return 0;
}

# _run_command(%args)
# Runs a shell command with cwd/env/timeout handling and captured output.
# Input: command string, cwd path, env hash, timeout_ms.
# Output: structured result hash reference.
sub _run_command {
    my ( $self, %args ) = @_;
    my $cmd        = $args{cmd};
    my $cwd        = $args{cwd};
    my $env        = $args{env} || {};
    my $timeout_ms = $args{timeout_ms} || 30_000;

    my $old = cwd();
    chdir $cwd or die "Unable to chdir to $cwd: $!";
    local @ENV{ keys %$env } = values %$env if %$env;

    my $timed_out = 0;
    my ( $stdout, $stderr, $exit_code ) = capture {
        local $SIG{ALRM} = sub { die "__ACTION_TIMEOUT__\n" };
        alarm( int( ( $timeout_ms + 999 ) / 1000 ) );
        my $ok = eval {
            system shell_command_argv($cmd);
            return $? >> 8;
        };
        if ($@) {
            die $@ if $@ !~ /__ACTION_TIMEOUT__/;
            $timed_out = 1;
            return 124;
        }
        alarm(0);
        return $ok;
    };
    alarm(0);
    chdir $old or die "Unable to restore cwd to $old: $!";

    return {
        background  => 0,
        command     => $cmd,
        cwd         => $cwd,
        env         => $env,
        exit_code   => $exit_code,
        stdout      => $stdout,
        stderr      => $stderr,
        timed_out   => $timed_out ? 1 : 0,
        content_type => 'application/json; charset=utf-8',
        started_at  => _now_iso8601(),
    };
}

# _now_iso8601()
# Returns the current UTC timestamp in ISO-8601 form.
# Input: none.
# Output: timestamp string.
sub _now_iso8601 {
    my @t = gmtime();
    return strftime( '%Y-%m-%dT%H:%M:%SZ', @t );
}

1;

__END__

=head1 NAME

Developer::Dashboard::ActionRunner - trusted action execution runtime

=head1 SYNOPSIS

  my $runner = Developer::Dashboard::ActionRunner->new(files => $files, paths => $paths);
  my $result = $runner->run_page_action(...);

=head1 DESCRIPTION

This module executes built-in and trusted command actions for dashboard pages,
including encoded action transport payloads.

=head1 METHODS

=head2 new, run_page_action, encode_action_payload, decode_action_payload, run_encoded_action, run_command_action

Construct and execute actions.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module validates and executes page actions. It decides whether a page action is a built-in dashboard action or an explicit command action, enforces the saved-page trust rules, captures command output, and returns structured result hashes for the page runtime and web routes.

=head1 WHY IT EXISTS

It exists because bookmark actions need one place that owns trust checks and command execution semantics. Without that boundary, the web layer, page renderer, and saved-action transport would each grow their own action policy and drift apart.

=head1 WHEN TO USE

Use this file when changing page action security, the transport payload for encoded actions, command backgrounding rules, or the way page actions report stdout, stderr, and exit codes back to callers.

=head1 HOW TO USE

Construct it with a file registry and path registry, then call C<run_page_action> for one decoded action hash or C<encode_action_payload> when a route needs a portable transport token. Keep action execution policy here instead of duplicating it in controllers or bookmark templates.

=head1 WHAT USES IT

It is used by C<Developer::Dashboard::Web::App>, by provider pages resolved through the page resolver, by saved page action buttons in the browser, and by action/web regression tests.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::ActionRunner -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/00-load.t t/21-refactor-coverage.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
