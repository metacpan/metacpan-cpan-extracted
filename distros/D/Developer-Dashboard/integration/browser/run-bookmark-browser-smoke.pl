#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path cwd);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptions);
use IO::Socket::INET;
use LWP::UserAgent;
use Time::HiRes qw(sleep);

our $BROWSER_BINARY;

# main()
# Runs a fast browser-backed smoke check for one saved bookmark file.
# Input: command-line options for bookmark source, expectations, and browser/runtime settings.
# Output: zero on success or dies with explicit logs when the smoke run fails.
sub main {
    my %opts = (
        bookmark_id           => 'test',
        host                  => '127.0.0.1',
        port                  => 0,
        expect_page_fragment  => [],
        expect_dom_fragment   => [],
    );

    GetOptions(
        'bookmark-file=s'         => \$opts{bookmark_file},
        'bookmark-id=s'           => \$opts{bookmark_id},
        'host=s'                  => \$opts{host},
        'port=i'                  => \$opts{port},
        'expect-page-fragment=s@' => $opts{expect_page_fragment},
        'expect-dom-fragment=s@'  => $opts{expect_dom_fragment},
        'expect-ajax-path=s'      => \$opts{expect_ajax_path},
        'expect-ajax-body=s'      => \$opts{expect_ajax_body},
        'browser-binary=s'        => \$opts{browser_binary},
        'keep-temp!'              => \$opts{keep_temp},
        'help'                    => \$opts{help},
    ) or die _usage();

    if ( $opts{help} ) {
        print _usage();
        return 0;
    }

    _apply_default_sample(\%opts);

    my $repo_root = _repo_root();
    my $bookmark  = _bookmark_source(\%opts);
    my $bookmark_id = _extract_bookmark_id($bookmark) || $opts{bookmark_id};
    my $home = tempdir( 'dd-bookmark-home-XXXXXX', CLEANUP => $opts{keep_temp} ? 0 : 1, TMPDIR => 1 );
    my $project = tempdir( 'dd-bookmark-project-XXXXXX', CLEANUP => $opts{keep_temp} ? 0 : 1, TMPDIR => 1 );
    my $profile = tempdir( 'dd-bookmark-browser-XXXXXX', CLEANUP => $opts{keep_temp} ? 0 : 1, TMPDIR => 1 );
    my $runtime_root  = File::Spec->catdir( $project, '.developer-dashboard' );
    my $bookmark_root = File::Spec->catdir( $runtime_root, 'dashboards' );
    my $bookmark_path = File::Spec->catfile( $bookmark_root, $bookmark_id );
    my %cmd_env = ( HOME => $home );
    my $listen_port = $opts{port} || _find_free_port();
    my $server_started = 0;
    my $base_url;
    my $page_url;

    make_path( dirname($bookmark_path) );
    _write_text( $bookmark_path, $bookmark );
    _run_command(
        label   => 'init isolated git project',
        command => [ 'git', 'init', '-q', $project ],
    );

    eval {
        my $serve = _run_command(
            label   => 'dashboard serve',
            cwd     => $project,
            env     => \%cmd_env,
            command => [
                'perl',
                '-I' . File::Spec->catdir( $repo_root, 'lib' ),
                File::Spec->catfile( $repo_root, 'bin', 'dashboard' ),
                'serve',
                '--host', $opts{host},
                '--port', $listen_port,
            ],
        );
        $server_started = 1;
        $base_url = "http://$opts{host}:$listen_port";
        $page_url = "$base_url/app/$bookmark_id";

        _wait_for_http("$base_url/");

        my $page = _fetch_text($page_url);
        print "verified page fetch: $page_url\n";

        for my $fragment ( @{ $opts{expect_page_fragment} || [] } ) {
            _assert_contains( $page, $fragment, "page contains expected fragment: $fragment" );
        }

        if ( defined $opts{expect_ajax_path} ) {
            my $ajax_url  = $base_url . $opts{expect_ajax_path};
            my $ajax_body = _fetch_text($ajax_url);
            print "verified ajax fetch: $ajax_url\n";
            if ( defined $opts{expect_ajax_body} ) {
                _assert_contains( $ajax_body, $opts{expect_ajax_body}, "ajax response contains expected body: $opts{expect_ajax_body}" );
            }
        }

        my $dom = _run_browser_dom(
            url            => $page_url,
            user_data_dir  => $profile,
            browser_binary => $opts{browser_binary},
        );
        print "verified browser DOM: $page_url\n";

        for my $fragment ( @{ $opts{expect_dom_fragment} || [] } ) {
            _assert_contains( $dom, $fragment, "browser DOM contains expected fragment: $fragment" );
        }

        print "bookmark smoke passed\n";
        print "bookmark id: $bookmark_id\n";
        print "page url: $page_url\n";
        print "project root: $project\n";
        print "home root: $home\n";
        print "browser profile: $profile\n";
        1;
    } or do {
        my $error = $@ || "bookmark smoke failed\n";
        if ($server_started) {
            eval { _stop_dashboard( $repo_root, $project, \%cmd_env ) };
            warn $@ if $@;
        }
        die $error;
    };

    _stop_dashboard( $repo_root, $project, \%cmd_env ) if $server_started;
    return 0;
}

# _find_free_port()
# Reserves one ephemeral local TCP port number for the smoke-run listener.
# Input: none.
# Output: integer TCP port number.
sub _find_free_port {
    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        Listen    => 1,
        ReuseAddr => 1,
    ) or die "Unable to reserve a free local TCP port: $!";
    my $port = $socket->sockport();
    close $socket or die "Unable to release reserved local TCP port $port: $!";
    return $port;
}

# _apply_default_sample(\%opts)
# Seeds the built-in ajax bookmark sample and matching assertions when no bookmark file was supplied.
# Input: option hash reference to update in place.
# Output: none.
sub _apply_default_sample {
    my ($opts) = @_;
    return if defined $opts->{bookmark_file};

    $opts->{bookmark_id} = 'test' if !defined $opts->{bookmark_id} || $opts->{bookmark_id} eq '';
    $opts->{bookmark_text} = <<'BOOKMARK';
BOOKMARK: test
:--------------------------------------------------------------------------------:
HTML: <script src="/js/jquery.js"></script>
<script>var foo = {};
$(document).ready(_ => {
    $.ajax({
        url: foo.bar,
        type: 'GET',
        dataType: 'text',
        success: function (response) {
            $('.display').text(response);
        },
        error: function (xhr, status, error) {
            console.error(error);
        }
    });
});
</script>
TEST2: <span class=display></span>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'foo.bar', file => 'foobar', code => q{
print 123
};
BOOKMARK

    push @{ $opts->{expect_page_fragment} }, q{set_chain_value(foo,'bar','/ajax/foobar?type=text')};
    push @{ $opts->{expect_dom_fragment} }, q{<span class="display">123</span>};
    $opts->{expect_ajax_path} = '/ajax/foobar?type=text';
    $opts->{expect_ajax_body} = '123';
}

# _bookmark_source(\%opts)
# Loads the bookmark content from an explicit file or from the built-in sample text.
# Input: option hash reference.
# Output: raw bookmark source text string.
sub _bookmark_source {
    my ($opts) = @_;
    return $opts->{bookmark_text} if defined $opts->{bookmark_text};

    my $path = $opts->{bookmark_file} or die "Missing --bookmark-file\n";
    open my $fh, '<', $path or die "Unable to read bookmark file $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh;
    return $text;
}

# _extract_bookmark_id($bookmark_text)
# Reads the saved bookmark id from the raw bookmark document when present.
# Input: raw bookmark source text.
# Output: bookmark id string or undef when the source does not declare one.
sub _extract_bookmark_id {
    my ($bookmark) = @_;
    return undef if !defined $bookmark;
    return $1 if $bookmark =~ /^BOOKMARK:\s*(.+?)\s*$/m;
    return undef;
}

# _repo_root()
# Resolves the checkout root relative to this script location.
# Input: none.
# Output: absolute repository root path string.
sub _repo_root {
    my $script = abs_path($0);
    my $root = File::Spec->catdir( dirname($script), '..', '..' );
    return abs_path($root);
}

# _wait_for_http($url)
# Polls one URL until the dashboard listener responds successfully.
# Input: URL string.
# Output: none.
sub _wait_for_http {
    my ($url) = @_;
    my $ua = LWP::UserAgent->new( timeout => 2 );
    my $deadline = time() + 20;
    while ( time() < $deadline ) {
        my $response = $ua->get($url);
        return if $response->is_success;
        sleep 0.25;
    }
    die "Timed out waiting for HTTP success at $url\n";
}

# _fetch_text($url)
# Fetches one browser or ajax URL over HTTP.
# Input: URL string.
# Output: decoded response body string.
sub _fetch_text {
    my ($url) = @_;
    my $ua = LWP::UserAgent->new( timeout => 5 );
    my $response = $ua->get($url);
    die "HTTP fetch failed for $url: " . $response->status_line . "\n"
      if !$response->is_success;
    return $response->decoded_content( charset => 'none' );
}

# _run_browser_dom(%args)
# Dumps the browser DOM for one URL through headless Chromium.
# Input: named args with url, user_data_dir, and optional browser_binary override.
# Output: dumped DOM string.
sub _run_browser_dom {
    my (%args) = @_;
    my $browser = $args{browser_binary} || _browser_binary();
    my @command = (
        $browser,
        '--headless',
        '--disable-gpu',
        '--no-first-run',
        '--virtual-time-budget=3000',
        '--user-data-dir=' . $args{user_data_dir},
        '--dump-dom',
        $args{url},
    );
    my ( $stdout, $stderr, $exit ) = capture {
        system @command;
        return $? >> 8;
    };
    if ( $exit != 0 ) {
        die "Headless browser command failed ($exit)\nstdout:\n$stdout\nstderr:\n$stderr\n";
    }
    return $stdout;
}

# _browser_binary()
# Resolves one available headless Chromium-style browser binary.
# Input: none.
# Output: absolute browser executable path string.
sub _browser_binary {
    return $BROWSER_BINARY if defined $BROWSER_BINARY;
    for my $candidate ( qw(chromium chromium-browser google-chrome google-chrome-stable) ) {
        my ( $stdout, $stderr, $exit ) = capture {
            system 'sh', '-lc', "command -v $candidate";
            return $? >> 8;
        };
        next if $exit != 0;
        my $path = $stdout;
        $path =~ s/\s+\z//;
        next if $path eq '';
        $BROWSER_BINARY = $path;
        return $BROWSER_BINARY;
    }
    die "Unable to find a headless browser binary. Install chromium or pass --browser-binary.\n";
}

# _run_command(%args)
# Executes one external command with explicit logging and captured stdout/stderr.
# Input: named args for label, command arrayref, optional cwd, env, and allow_fail.
# Output: hashref containing stdout, stderr, and exit_code.
sub _run_command {
    my (%args) = @_;
    my $label   = $args{label}   || 'command';
    my $command = $args{command} || die "Missing command arrayref for $label\n";
    my $cwd     = $args{cwd};
    my $env     = $args{env} || {};
    my $allow_fail = $args{allow_fail};
    my $stdout = '';
    my $stderr = '';
    my $exit_code;
    my $original_cwd = cwd();

    print "==> $label\n";
    print "    " . join( ' ', map { _shell_quote($_) } @{$command} ) . "\n";

    my $ok = eval {
        local %ENV = ( %ENV, %{$env} );
        if ( defined $cwd ) {
            chdir $cwd or die "Unable to chdir to $cwd for $label: $!";
        }
        ( $stdout, $stderr, $exit_code ) = capture {
            system @{$command};
            return $? >> 8;
        };
        1;
    };
    my $error = $@;
    chdir $original_cwd or die "Unable to restore cwd to $original_cwd: $!";

    die $error if !$ok;

    print $stdout if length $stdout;
    print STDERR $stderr if length $stderr;

    if ( !$allow_fail && $exit_code != 0 ) {
        die "Command failed for $label with exit code $exit_code\n";
    }

    return {
        stdout    => $stdout,
        stderr    => $stderr,
        exit_code => $exit_code,
    };
}

# _stop_dashboard($repo_root, $project, \%env)
# Stops the isolated dashboard runtime used by the smoke run.
# Input: repo root path, project root path, and env hashref.
# Output: none.
sub _stop_dashboard {
    my ( $repo_root, $project, $env ) = @_;
    _run_command(
        label      => 'dashboard stop',
        cwd        => $project,
        env        => $env,
        allow_fail => 1,
        command    => [
            'perl',
            '-I' . File::Spec->catdir( $repo_root, 'lib' ),
            File::Spec->catfile( $repo_root, 'bin', 'dashboard' ),
            'stop',
        ],
    );
}

# _write_text($path, $content)
# Writes one text file, creating parent directories as needed.
# Input: destination path string and text content string.
# Output: none.
sub _write_text {
    my ( $path, $content ) = @_;
    my $dir = dirname($path);
    make_path($dir) if !-d $dir;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
}

# _assert_contains($text, $fragment, $label)
# Fails fast when expected content is missing from captured text.
# Input: haystack string, required substring, and log label string.
# Output: none.
sub _assert_contains {
    my ( $text, $fragment, $label ) = @_;
    die "Assertion failed: $label\nMissing fragment:\n$fragment\n"
      if index( $text, $fragment ) < 0;
    print "ok: $label\n";
}

# _shell_quote($text)
# Escapes one shell argument for human-readable command logging.
# Input: plain text string.
# Output: single shell-quoted string.
sub _shell_quote {
    my ($text) = @_;
    return "''" if !defined $text || $text eq '';
    return $text if $text =~ /\A[-+_.,:\/A-Za-z0-9=]+\z/;
    $text =~ s/'/'"'"'/g;
    return "'$text'";
}

# _usage()
# Returns the command help text.
# Input: none.
# Output: usage string.
sub _usage {
    return <<'USAGE';
Usage: integration/browser/run-bookmark-browser-smoke.pl [options]

  --bookmark-file PATH
  --bookmark-id ID
  --host 127.0.0.1
  --port 17894
  --expect-page-fragment TEXT
  --expect-dom-fragment TEXT
  --expect-ajax-path /ajax/name?type=text
  --expect-ajax-body TEXT
  --browser-binary /path/to/chromium
  --keep-temp
  --help

With no --bookmark-file, the script runs a built-in legacy Ajax bookmark sample
that verifies the browser page, the emitted ajax path binding, the ajax handler
response, and the final Chromium DOM.
USAGE
}

exit main();

__END__

=head1 NAME

run-bookmark-browser-smoke.pl - fast browser-backed smoke runner for saved bookmark files

=head1 SYNOPSIS

  integration/browser/run-bookmark-browser-smoke.pl

  integration/browser/run-bookmark-browser-smoke.pl \
    --bookmark-file ~/.developer-dashboard/dashboards/test \
    --expect-page-fragment "set_chain_value(foo,'bar','/ajax/foobar?type=text')" \
    --expect-ajax-path /ajax/foobar?type=text \
    --expect-ajax-body 123 \
    --expect-dom-fragment '<span class="display">123</span>'

=head1 DESCRIPTION

This host-side smoke runner creates an isolated temporary dashboard runtime,
starts the checkout-local web app, loads one saved bookmark page through a real
headless browser, and verifies optional page, ajax, and final DOM fragments.

With no C<--bookmark-file>, it runs the built-in legacy jQuery/Ajax bookmark
sample that checks the exact C<foo.bar> binding flow used by the bookmark
regressions fixed in the 1.06 and 1.07 releases.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Integration helper script in the Developer Dashboard codebase. This file runs browser-driven bookmark smoke checks against a live Developer Dashboard web instance.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to make a repeatable host-or-container integration workflow explicit instead of burying release verification steps in ad-hoc shell history.

=head1 WHEN TO USE

Use this file when you are rerunning the documented integration workflow for its environment or debugging a release/install problem in that path.

=head1 HOW TO USE

Run the script as part of the documented integration plan for its environment. Treat failures here as release blockers, because these scripts represent the supported rerun path.

=head1 WHAT USES IT

It is used by maintainers running the documented install/runtime verification workflow for that environment, and by tests that validate the checked-in integration assets.

=head1 EXAMPLES

  perl integration/browser/run-bookmark-browser-smoke.pl

Run the script from the documented integration environment so it can find the expected tarball, browser, or container prerequisites.

=for comment FULL-POD-DOC END

=cut
