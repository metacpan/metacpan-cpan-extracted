package Developer::Dashboard::CLI::API;

use strict;
use warnings;

our $VERSION = '4.03';

use Digest::SHA qw(sha256_hex);
use Getopt::Long qw(GetOptionsFromArray);

use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::PathRegistry;

# run_api_command(%args)
# Dispatches dashboard api management commands for layered config/api.json
# files.
# Input: raw argv array reference under args.
# Output: numeric process exit code after printing table or JSON output.
sub run_api_command {
    my (%args) = @_;
    my $argv = $args{args} || die "Missing API command arguments\n";
    die "API command arguments must be an array reference\n" if ref($argv) ne 'ARRAY';

    my @argv = @{$argv};
    my $action = @argv && $argv[0] !~ /^-/ ? shift @argv : 'ls';
    $action = 'ls' if !defined $action || $action eq '';
    return _run_list_command(@argv) if $action eq 'ls';
    return _run_add_command(@argv)  if $action eq 'add';
    return _run_remove_command(@argv) if $action eq 'rm';

    die "Unknown api action: $action\nUsage: dashboard api [ls|add|rm]\n";
}

# _run_list_command(@argv)
# Renders the effective layered API registry, optionally filtered by one key.
# Input: CLI argument list after the ls action.
# Output: numeric process exit code.
sub _run_list_command {
    my (@argv) = @_;
    my $output = 'table';
    my $key    = '';
    GetOptionsFromArray(
        \@argv,
        'o|output=s' => \$output,
        'key=s'      => \$key,
    );
    die "Usage: dashboard api [ls] [--key <name>] [-o json|table]\n"
      if @argv || ( $output ne 'json' && $output ne 'table' );

    my $config = _build_config();
    my $registry = $config->api_registry;
    $registry = { $key => $registry->{$key} }
      if $key ne '' && exists $registry->{$key};
    $registry = {} if $key ne '' && !exists $registry->{$key};

    if ( $output eq 'json' ) {
        print json_encode( { api => $registry } );
        return 0;
    }

    print _api_table($registry);
    return 0;
}

# _run_add_command(@argv)
# Adds or updates one writable-layer API key secret and/or route.
# Input: CLI argument list after the add action.
# Output: numeric process exit code.
sub _run_add_command {
    my (@argv) = @_;
    my $key          = '';
    my $secret       = '';
    my $maybe_secret = '';
    my @routes;
    my $output = 'json';
    GetOptionsFromArray(
        \@argv,
        'key=s'          => \$key,
        'secret=s'       => \$secret,
        'maybe-secret=s' => \$maybe_secret,
        'route=s@'       => \@routes,
        'o|output=s'     => \$output,
    );
    die "Usage: dashboard api add --key <name> [--secret <raw>|--maybe-secret <raw>] [--route /ajax/... ]... [-o json|table]\n"
      if @argv || $key eq '' || ( $secret eq '' && $maybe_secret eq '' && !@routes ) || ( $output ne 'json' && $output ne 'table' );
    die "Use either --secret or --maybe-secret, not both\n"
      if $secret ne '' && $maybe_secret ne '';
    my $effective_secret = $secret ne '' ? $secret : $maybe_secret;
    for my $route (@routes) {
        die "Route must begin with /ajax/\n" if !defined $route || $route !~ m{\A/ajax(?:/|\z)};
    }

    my $config   = _build_config();
    my $visible  = $config->api_registry;
    my $writable = $config->writable_api_registry;
    my $current  = $visible->{$key};

    if ( @routes && ref($current) ne 'HASH' && $effective_secret eq '' ) {
        die "API key '$key' does not exist yet; add --secret or --maybe-secret first\n";
    }

    my $next = ref($current) eq 'HASH'
      ? {
        secret => $current->{secret},
        ajax   => [ @{ $current->{ajax} || [] } ],
      }
      : {
        secret => '',
        ajax   => [],
      };

    my $changed = 0;
    if ( $effective_secret ne '' ) {
        my $digest = sha256_hex($effective_secret);
        $changed = 1 if $next->{secret} ne $digest;
        $next->{secret} = $digest;
    }

    for my $route (@routes) {
        if ( !grep { $_ eq $route } @{ $next->{ajax} } ) {
            push @{ $next->{ajax} }, $route;
            $changed = 1;
        }
    }

    die "API key '$key' does not have a secret yet\n" if $next->{secret} eq '';

    $writable->{$key} = $next;
    my $file = $config->save_writable_api_registry($writable);

    return _render_mutation_result(
        action  => 'add',
        changed => $changed,
        file    => $file,
        key     => $key,
        entry   => $next,
        output  => $output,
    );
}

# _run_remove_command(@argv)
# Removes one writable-layer API key or one route from it.
# Input: CLI argument list after the rm action.
# Output: numeric process exit code.
sub _run_remove_command {
    my (@argv) = @_;
    my $key    = '';
    my $route  = '';
    my $output = 'json';
    GetOptionsFromArray(
        \@argv,
        'key=s'      => \$key,
        'route=s'    => \$route,
        'o|output=s' => \$output,
    );
    die "Usage: dashboard api rm --key <name> [--route /ajax/... ] [-o json|table]\n"
      if @argv || $key eq '' || ( $output ne 'json' && $output ne 'table' );
    die "Route must begin with /ajax/\n" if $route ne '' && $route !~ m{\A/ajax(?:/|\z)};

    my $config   = _build_config();
    my $visible  = $config->api_registry;
    my $writable = $config->writable_api_registry;
    my $current  = $visible->{$key};
    my $w_current = $writable->{$key};
    my $changed  = 0;
    my $entry;

    if ( $route ne '' ) {
        die "Unknown API key '$key'\n" if ref($current) ne 'HASH';
        my @remaining = grep { $_ ne $route } @{ $current->{ajax} || [] };
        $changed = @remaining != @{ $current->{ajax} || [] } ? 1 : 0;
        $entry = {
            secret => $current->{secret},
            ajax   => \@remaining,
        };
        $writable->{$key} = $entry;
    }
    else {
        if ( exists $visible->{$key} ) {
            $writable->{$key} = { disabled => 1 };
            $changed = 1;
        }
        elsif ( exists $writable->{$key} ) {
            my $disabled = ref($w_current) eq 'HASH' && $w_current->{disabled} ? 1 : 0;
            $changed = $disabled ? 0 : 1;
        }
        $entry = undef;
    }

    my $file = $config->save_writable_api_registry($writable);
    return _render_mutation_result(
        action  => 'rm',
        changed => $changed,
        file    => $file,
        key     => $key,
        entry   => $entry,
        output  => $output,
    );
}

# _render_mutation_result(%args)
# Prints the add or remove summary in JSON or table form.
# Input: action, changed flag, file path, key name, optional entry hash ref,
# and output format.
# Output: numeric process exit code.
sub _render_mutation_result {
    my (%args) = @_;
    my $payload = {
        action  => $args{action},
        changed => $args{changed} ? 1 : 0,
        file    => $args{file},
        key     => $args{key},
    };
    $payload->{api} = { $args{key} => $args{entry} } if ref( $args{entry} ) eq 'HASH';

    if ( $args{output} eq 'json' ) {
        print json_encode($payload);
        return 0;
    }

    if ( ref( $args{entry} ) eq 'HASH' ) {
        print _api_table( { $args{key} => $args{entry} } );
    }
    else {
        print "Key   Status\n";
        print "----  -------\n";
        print sprintf "%-4s  %s\n", $args{key}, ( $args{changed} ? 'removed' : 'no-change' );
    }
    return 0;
}

# _api_table($registry)
# Renders one API registry hash as a readable table.
# Input: hash reference keyed by API client name.
# Output: table text string.
sub _api_table {
    my ($registry) = @_;
    $registry ||= {};
    my @rows;
    for my $key ( sort keys %{$registry} ) {
        my $entry = $registry->{$key};
        next if ref($entry) ne 'HASH';
        my @routes = @{ $entry->{ajax} || [] };
        @routes = ('') if !@routes;
        for my $route (@routes) {
            push @rows, [ $key, $entry->{secret} || '', $route ];
        }
    }
    return "Key  Secret  Route\n---  ------  -----\n" if !@rows;

    my @widths = ( 3, 6, 5 );
    for my $row (@rows) {
        for my $index ( 0 .. $#{$row} ) {
            my $length = length( defined $row->[$index] ? $row->[$index] : '' );
            $widths[$index] = $length if $length > $widths[$index];
        }
    }
    my @headers = qw(Key Secret Route);
    my $text = join( '  ', map { sprintf "%-*s", $widths[$_], $headers[$_] } 0 .. $#headers ) . "\n";
    $text .= join( '  ', map { '-' x $widths[$_] } 0 .. $#headers ) . "\n";
    for my $row (@rows) {
        $text .= join( '  ', map { sprintf "%-*s", $widths[$_], ( defined $row->[$_] ? $row->[$_] : '' ) } 0 .. $#{$row} ) . "\n";
    }
    return $text;
}

# _build_config()
# Builds the lightweight config loader used by the dashboard api helper.
# Input: none.
# Output: Developer::Dashboard::Config object.
sub _build_config {
    my $home = $ENV{HOME} || '';
    my $paths = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        workspace_roots => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],
        project_roots   => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],
    );
    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
    return Developer::Dashboard::Config->new( files => $files, paths => $paths );
}

1;

__END__

=head1 NAME

Developer::Dashboard::CLI::API - layered API-key manager for dashboard api

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::API qw();
  Developer::Dashboard::CLI::API::run_api_command( args => \@ARGV );

=head1 DESCRIPTION

This module powers the built-in C<dashboard api> command. It manages the
deepest writable F<config/api.json> layer while listing the effective merged
registry through C<DD-OOP-LAYERS>.

=head1 METHODS

=head2 run_api_command

Dispatch the public C<dashboard api> command.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module gives the dashboard a focused CLI for machine-auth API keys and
their saved C</ajax/...> route allowlists. It owns the writable-layer update
logic, including child-layer tombstones that can mask inherited API groups.

=head1 WHY IT EXISTS

It exists because the web backend now consumes layered F<config/api.json>
files, but operators still need a safe command surface that updates the right
layer without hand-editing JSON and without breaking OOP inheritance rules.

=head1 WHEN TO USE

Use this file when changing C<dashboard api> syntax, writable-layer update
rules, API-key hashing behavior, or table and JSON output for API
administration.

=head1 HOW TO USE

Call C<run_api_command(args =E<gt> \@ARGV)> from the staged helper. The module
defaults C<dashboard api> to C<ls>, supports C<add> and C<rm>, hashes raw
secrets from either C<--secret> or C<--maybe-secret> with SHA-256 before
persistence, accepts repeated C<--route> flags on C<add>, and writes only to the deepest
participating runtime layer under F<config/api.json>.

=head1 WHAT USES IT

It is used by the staged private C<api> helper, by CLI smoke tests, by module
coverage tests, and by operators who need to manage saved Ajax machine-auth
allowlists from the shell.

=head1 EXAMPLES

Example 1:

  dashboard api

List the effective merged API registry as a table.

Example 2:

  dashboard api add --key ci-bot --secret bot-secret --route /ajax/health

Create or update one writable-layer API key and allow it to call one saved
Ajax route.

Example 3:

  dashboard api rm --key ci-bot --route /ajax/health

Remove one route from the effective API group while preserving the current
secret digest.

Example 4:

  prove -lv t/05-cli-smoke.t t/15-cli-module-coverage.t

Rerun the focused CLI and module regression tests after changing this helper.

=for comment FULL-POD-DOC END

=cut
