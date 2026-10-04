#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

# DD-602: the CORE::GLOBAL::rename override must be installed before
# Developer::Dashboard::CLI::Ask is compiled so the module's own rename call
# in _save_transcript resolves through this intercept - matching
# DD-599/600/601's established pattern. $DD602_OBSERVED_RENAME_MODE records
# the permission mode of the SOURCE file at the exact moment of a rename
# whose target matches $DD602_WATCH_TARGET, proving the file was already
# secured before it became visible at that (predictable) final path.
our $DD602_WATCH_TARGET;
our $DD602_OBSERVED_RENAME_MODE;

BEGIN {
    *CORE::GLOBAL::rename = sub {
        my ( $from, $to ) = @_;
        $DD602_OBSERVED_RENAME_MODE = ( stat($from) )[2] & 07777
          if defined $DD602_WATCH_TARGET && $to eq $DD602_WATCH_TARGET;
        return CORE::rename( $from, $to );
    };
}

use lib 'lib';

use Capture::Tiny qw(capture_stderr);
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(getcwd);

use Developer::Dashboard::JSON qw(json_encode json_decode);
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::Config;

BEGIN { use_ok('Developer::Dashboard::CLI::Ask') or BAIL_OUT('Ask module failed to load'); }

my $M = 'Developer::Dashboard::CLI::Ask';

# ------------------------------------------------------------------
# Hermetic runtime: temp HOME, temp state root, and a temp working directory.
# The layered config root is derived from the CURRENT WORKING DIRECTORY's
# deepest .developer-dashboard layer, so the whole file runs from throwaway
# space and never reads or writes the repository's own runtime layer.
# ------------------------------------------------------------------
my $cwd_before = getcwd();
my $home       = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
delete local $ENV{ANTHROPIC_API_KEY};
delete local $ENV{WORKSPACE_REF};
chdir $home or die "Unable to chdir to $home: $!";
END { chdir $cwd_before if defined $cwd_before; }

my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );

# A fake HTTP user agent that records requests and replays a canned response.
{

    package AskFakeUA;
    sub new { return bless { requests => [], reply => $_[1] }, $_[0]; }

    sub request {
        my ( $self, $req ) = @_;
        push @{ $self->{requests} }, $req;
        return $self->{reply}->($req);
    }
}

# A minimal path-registry stand-in for the _workspace_key unit: the routine only
# needs current_project_root, and this lets the empty-project-root defence run.
{

    package AskStubPaths;
    sub new                  { return bless { root => $_[1] }, $_[0]; }
    sub current_project_root { return $_[0]->{root}; }
}

require HTTP::Response;

# api_reply($text)
# Builds a reply coderef producing a successful Messages API response.
# Input: answer text string.
# Output: coderef returning an HTTP::Response object.
sub api_reply {
    my ($text) = @_;
    return sub {
        my $resp = HTTP::Response->new( 200, 'OK' );
        $resp->content( json_encode( { content => [ { type => 'text', text => $text } ] } ) );
        return $resp;
    };
}

# rec_runner($store, $stdout, $stderr, $exit)
# Builds a CLI runner seam that records argv and replays canned streams.
# Input: argv store array ref, stdout, stderr, exit code.
# Output: coderef usable as the run_ask runner seam.
sub rec_runner {
    my ( $store, $stdout, $stderr, $exit ) = @_;
    return sub {
        my ($argv) = @_;
        push @{$store}, [ @{$argv} ];
        return ( $stdout, $stderr, $exit );
    };
}

# write_file($path, $body)
# Writes one raw file, creating it fresh.
# Input: path string and body string.
# Output: the path string.
sub write_file {
    my ( $path, $body ) = @_;
    open my $fh, '>:raw', $path or die "Unable to write $path: $!";
    print {$fh} $body;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

# ------------------------------------------------------------------
subtest 'run_ask seams: injected env/config/paths, piped stdin, and defaults' => sub {
    my @calls;
    my $out = '';
    my $rc  = $M->can('run_ask')->(
        args   => ['explain the collector loop'],
        env    => { HOME => $home, WORKSPACE_REF => 'seam-workspace' },
        config => $config,
        paths  => $paths,
        stdin  => "piped detail\n",
        out    => \$out,
        detect => sub { return $^X },
        runner => rec_runner( \@calls, "SEAMED ANSWER\n", '', 0 ),
    );

    is( $rc, 0, 'injected-seam run_ask turn exits 0' );
    like( $out, qr/SEAMED ANSWER/, 'answer reaches the injected sink' );
    my ($prompt) = grep { /explain the collector loop/ } @{ $calls[0] };
    like( $prompt, qr/explain the collector loop\n\npiped detail/, 'non-empty stdin is appended to the argv question' );

    # An explicitly empty stdin string is defined but must not append anything.
    my @empty_calls;
    my $empty_out = '';
    is(
        $M->can('run_ask')->(
            args   => ['second question'],
            env    => { HOME => $home, WORKSPACE_REF => 'seam-workspace' },
            config => $config,
            paths  => $paths,
            stdin  => '',
            out    => \$empty_out,
            detect => sub { return $^X },
            runner => rec_runner( \@empty_calls, "EMPTY STDIN ANSWER\n", '', 0 ),
        ),
        0,
        'empty stdin string still runs one turn',
    );
    my ($empty_prompt) = grep { /second question/ } @{ $empty_calls[0] };
    like( $empty_prompt, qr/\n\nsecond question\z/, 'empty stdin appends no piped block after the new question' );
    like( $empty_prompt, qr/Previous conversation:/, 'the sticky transcript is replayed into the follow-up prompt' );

    # No env, no config and no paths: run_ask must fall back to the process
    # environment and build its own layered config/path registry.
    my @default_calls;
    my $default_out = '';
    is(
        $M->can('run_ask')->(
            args   => ['third question'],
            out    => \$default_out,
            detect => sub { return $^X },
            runner => rec_runner( \@default_calls, "DEFAULT ENV ANSWER\n", '', 0 ),
        ),
        0,
        'run_ask builds its own env/config/paths when none are injected',
    );
    like( $default_out, qr/DEFAULT ENV ANSWER/, 'self-built runtime still emits the answer' );
    is( scalar @default_calls, 1, 'the self-built runtime shelled out exactly once' );
};

# ------------------------------------------------------------------
subtest '_build_config tolerates an environment without HOME' => sub {
    my $built = $M->can('_build_config')->( {} );
    isa_ok( $built, 'Developer::Dashboard::Config', 'config built from an empty environment' );
    isa_ok( $built->{paths}, 'Developer::Dashboard::PathRegistry', 'the built config carries a path registry' );
};

# ------------------------------------------------------------------
subtest '_resolve_backend stickiness and rejection of unknown backends' => sub {
    my $resolve = $M->can('_resolve_backend');
    is( $resolve->( { backend => 'codex' }, { backend => '' } ),      'codex',  'an explicit flag wins' );
    is( $resolve->( { backend => '' },      { backend => 'gemini' } ), 'gemini', 'a known sticky backend is reused' );
    is( $resolve->( { backend => '' },      { backend => 'not-a-backend' } ), 'claude', 'an unknown sticky backend falls back to claude' );
    is( $resolve->( { backend => '' },      { backend => '' } ),      'claude', 'an empty transcript falls back to claude' );
};

# ------------------------------------------------------------------
subtest '_resolve_api_key precedence over blank values' => sub {
    my $resolve = $M->can('_resolve_api_key');
    is( $resolve->( {}, { ANTHROPIC_API_KEY => 'sk-env' } ), 'sk-env', 'a non-empty environment key wins' );
    is( $resolve->( { api_key => 'sk-conf' }, { ANTHROPIC_API_KEY => '' } ), 'sk-conf', 'a blank environment key defers to config' );
    is( $resolve->( { api_key => '' }, {} ), '', 'a blank config key resolves to no key' );
    is( $resolve->( {},                {} ), '', 'no key anywhere resolves to no key' );
};

# ------------------------------------------------------------------
subtest '_capture_backend failure detail and silent-answer handling' => sub {
    my $capture = $M->can('_capture_backend');

    my $err = '';
    eval { $capture->( 'codex', ['argv'], sub { return ( undef, undef, 3 ); } ); 1 } or $err = $@;
    like( $err, qr/\Acodex backend failed: exit status 3\n\z/, 'an undefined stderr degrades to the exit status' );

    $err = '';
    eval { $capture->( 'codex', ['argv'], sub { return ( '', '  ', 2 ); } ); 1 } or $err = $@;
    like( $err, qr/\Acodex backend failed: exit status 2\n\z/, 'whitespace-only stderr degrades to the exit status' );

    $err = '';
    eval { $capture->( 'gemini', ['argv'], sub { return ( '', "boom happened\n", 1 ); } ); 1 } or $err = $@;
    like( $err, qr/\Agemini backend failed: boom happened\n\z/, 'real stderr is reported as the failure detail' );

    $err = '';
    eval { $capture->( 'copilot', ['argv'], sub { return ( undef, '', 0 ); } ); 1 } or $err = $@;
    like( $err, qr/\Acopilot backend returned no answer\.\n\z/, 'an undefined stdout counts as a silent backend' );

    is( $capture->( 'copilot', ['argv'], sub { return ( "  trimmed  \n", '', 0 ); } ), '  trimmed', 'a successful run returns the trimmed answer' );

    # DD-620: a runaway backend's megabytes of stderr must not turn into an
    # equally huge exception message.
    $err = '';
    my $huge_stderr = ( 'x' x 100_000 ) . "\n";
    eval { $capture->( 'claude', ['argv'], sub { return ( '', $huge_stderr, 1 ); } ); 1 } or $err = $@;
    like( $err, qr/\Aclaude backend failed: x{4000} \.\.\. \(truncated, \d+ more bytes omitted\)\n\z/,
        'oversized stderr is capped with a truncation marker naming the omitted byte count' );
    ok( length($err) < length($huge_stderr), 'the capped error message is genuinely smaller than the raw stderr' );

    $err = '';
    my $small_stderr = 'x' x 100 . "\n";
    eval { $capture->( 'claude', ['argv'], sub { return ( '', $small_stderr, 1 ); } ); 1 } or $err = $@;
    like( $err, qr/\Aclaude backend failed: x{100}\n\z/, 'stderr under the cap is reported verbatim with no truncation marker' );

    $err = '';
    # DD-620's cap is 4000 bytes (private $MAX_BACKEND_ERROR_DETAIL_BYTES in
    # CLI/Ask.pm - not accessible from here, so the boundary is duplicated).
    my $one_over_stderr = 'x' x 4001;
    eval { $capture->( 'claude', ['argv'], sub { return ( '', $one_over_stderr, 1 ); } ); 1 } or $err = $@;
    like( $err, qr/\Aclaude backend failed: x{4000} \.\.\. \(truncated, 1 more byte omitted\)\n\z/,
        'exactly one omitted byte uses the singular "byte" wording' );
};

# ------------------------------------------------------------------
subtest '_classify_files splits attachments and tolerates missing lists' => sub {
    my $classify = $M->can('_classify_files');

    my ( $images, $texts ) = $classify->(undef);
    is_deeply( [ $images, $texts ], [ [], [] ], 'an undefined attachment list yields nothing to attach' );

    my $dir = File::Spec->catdir( $home, 'attachments' );
    mkdir $dir or die "Unable to create $dir: $!";
    my $png    = write_file( File::Spec->catfile( $dir, 'shot.PNG' ),  "\x89PNG\r\n\x1a\nbytes" );
    my $text   = write_file( File::Spec->catfile( $dir, 'notes.txt' ), "line one\n" );
    my $bare   = write_file( File::Spec->catfile( $dir, 'CHANGELOG' ), '' );

    ( $images, $texts ) = $classify->( [ $png, $text, $bare ] );
    is_deeply( $images, [$png], 'an uppercase image extension is still classified as an image' );
    is( scalar @{$texts}, 2, 'both non-image attachments are inlined as text' );
    is( $texts->[0]{body}, "line one\n", 'a text attachment keeps its body' );
    is( $texts->[1]{path}, $bare,        'an extensionless attachment is treated as text' );
    is( $texts->[1]{body}, '',           'an empty attachment inlines as the empty string' );

    my $err = '';
    eval { $classify->( [ File::Spec->catfile( $dir, 'absent.txt' ) ] ); 1 } or $err = $@;
    like( $err, qr/\AAttachment not found: /, 'a missing attachment is a user-facing error' );
};

# ------------------------------------------------------------------
subtest 'message builders tolerate absent history, images and text files' => sub {
    my $build   = $M->can('_build_api_messages');
    my $render  = $M->can('_render_history');
    my $inline  = $M->can('_inline_text_files');

    my $bare = $build->( undef, 'plain question', undef, undef );
    is_deeply( $bare, [ { role => 'user', content => 'plain question' } ], 'no history, images or files yields one text turn' );

    my $png = File::Spec->catfile( $home, 'attachments', 'shot.PNG' );
    my $rich = $build->(
        [ { role => 'assistant', content => 'earlier answer' } ],
        'rich question',
        [ { path => 'notes.txt', body => "line one\n" } ],
        [$png],
    );
    is( scalar @{$rich},                2,             'history plus the new turn are both present' );
    is( $rich->[1]{content}[0]{type},   'text',        'the new turn opens with the text block' );
    like( $rich->[1]{content}[0]{text}, qr/attached file: notes\.txt/, 'text attachments are inlined into the text block' );
    is( $rich->[1]{content}[1]{source}{media_type}, 'image/png', 'the image block carries the mapped media type' );
    ok( length $rich->[1]{content}[1]{source}{data}, 'the image block carries base64 data' );

    is( $render->(undef), '', 'an undefined history renders as no preamble' );
    like( $render->( [ { role => 'assistant', content => 'earlier answer' } ] ), qr/^Previous conversation:\nAssistant: earlier answer\z/, 'assistant turns are labelled in the preamble' );
    is( $inline->( 'q', undef ), 'q', 'an undefined text-file list leaves the prompt untouched' );
};

# ------------------------------------------------------------------
subtest '_extract_api_text guards malformed content blocks' => sub {
    my $extract = $M->can('_extract_api_text');

    my $err = '';
    eval { $extract->( [] ); 1 } or $err = $@;
    like( $err, qr/\AClaude API returned no content\.\n\z/, 'a non-hash payload has no content' );

    $err = '';
    eval { $extract->( { content => 'not-an-array' } ); 1 } or $err = $@;
    like( $err, qr/\AClaude API returned no content\.\n\z/, 'a non-array content field has no content' );

    is(
        $extract->(
            {
                content => [
                    'a bare scalar block',
                    { text    => 'untyped block' },
                    { type    => 'thinking', text => 'ignored' },
                    { type    => 'text', text => 'first ' },
                    { type    => 'text', text => 'second' },
                ]
            }
        ),
        'first second',
        'only well-formed text blocks are concatenated',
    );

    $err = '';
    eval { $extract->( { content => [ { type => 'text' } ] } ); 1 } or $err = $@;
    like( $err, qr/\AClaude API returned no text\.\n\z/, 'a text block without text is not an answer' );
};

# ------------------------------------------------------------------
subtest '_workspace_key falls back through blank workspace references' => sub {
    my $key = $M->can('_workspace_key');
    is( $key->( AskStubPaths->new(undef), {} ), 'global', 'no reference and no project root yields the global key' );
    is( $key->( AskStubPaths->new(''), { WORKSPACE_REF => '' } ), 'global', 'a blank reference and blank project root yield the global key' );
    is( $key->( AskStubPaths->new(undef), { WORKSPACE_REF => '/home/dev/proj one/' } ), 'home-dev-proj-one', 'an explicit reference is sanitized into a filename-safe key' );
};

# ------------------------------------------------------------------
subtest 'transcript load and save edge cases' => sub {
    my $load = $M->can('_load_transcript');
    my $save = $M->can('_save_transcript');

    my $dir = File::Spec->catdir( $home, 'transcripts' );
    mkdir $dir or die "Unable to create $dir: $!";

    my $no_backend = write_file( File::Spec->catfile( $dir, 'no-backend.json' ), json_encode( { messages => [ { role => 'user', content => 'x' } ] } ) );
    my $loaded = $load->($no_backend);
    is( $loaded->{backend}, '', 'a transcript without a backend key loads as an empty backend' );
    is( scalar @{ $loaded->{messages} }, 1, 'its messages survive the load' );

    my $with_backend = write_file( File::Spec->catfile( $dir, 'with-backend.json' ), json_encode( { backend => 'codex', messages => [] } ) );
    is( $load->($with_backend)->{backend}, 'codex', 'a stored backend is preserved' );

    my $unreadable = write_file( File::Spec->catfile( $dir, 'unreadable.json' ), json_encode( { backend => 'codex', messages => [] } ) );
  SKIP: {
        chmod 0000, $unreadable or skip 'chmod not honored on this filesystem', 1;
        if ( open my $probe, '<', $unreadable ) {
            close $probe or die "Unable to close probe on $unreadable: $!";
            skip 'this process can read a mode-0000 transcript, so the degrade path cannot occur', 1;
        }

        is_deeply( $load->($unreadable), { backend => '', messages => [] }, 'an unreadable transcript degrades to an empty shell' );
    }

    chmod 0600, $unreadable or die "Unable to restore $unreadable: $!";

    my $saved = File::Spec->catfile( $dir, 'saved.json' );
    is( $save->( $saved, { backend => 'claude', messages => [] }, $paths ), $saved, 'a saved transcript returns its path' );
    is( $load->($saved)->{backend}, 'claude', 'the saved transcript reloads' );

    # DD-602: the transcript's PREDICTABLE final path must never become
    # visible with loose permissions - a bare stat() after _save_transcript
    # returns can't prove this (a later chmod always leaves the final state
    # correct even with the bug), so this intercepts the rename that makes
    # the file visible under its final name and checks the SOURCE file's
    # permissions at that exact moment: by the time anything could observe
    # the file at its predictable path, it must already be secured.
    {
        my $old_umask = umask(0);
        my $rename_target = File::Spec->catfile( $paths->state_root, 'rename-observed.json' );
        local $DD602_WATCH_TARGET = $rename_target;
        local $DD602_OBSERVED_RENAME_MODE;
        $save->( $rename_target, { backend => 'claude', messages => [] }, $paths );
        umask($old_umask);
        ok( defined $DD602_OBSERVED_RENAME_MODE, 'DD-602: _save_transcript renamed a source file into the predictable final path (rename observed)' );
        is( sprintf( '%04o', $DD602_OBSERVED_RENAME_MODE // -1 ), '0600',
            'DD-602: the source file was already 0600 BEFORE the rename that made it visible at its final, predictable path - even under umask(0)' );
    }

    # DD-602: force the close-stage die. The temp path is fully predictable
    # ("$file.$$.tmp", no wall-clock component) so it can be symlinked to
    # /dev/full directly, without needing an override point. /dev/full always
    # fails a write with ENOSPC; the transcript payload here is far smaller
    # than Perl's IO buffer, so print() itself returns true (buffered, not
    # yet flushed to the device) and the error only surfaces at close().
    SKIP: {
        skip 'requires a writable /dev/full to force a write failure', 1
          if !-e '/dev/full' || !-w '/dev/full';

        my $write_target = File::Spec->catfile( $paths->state_root, 'write-blocked.json' );
        my $pending_path = "$write_target.$$.tmp";
        skip "unable to symlink /dev/full: $!", 1
          if !symlink( '/dev/full', $pending_path );

        my $write_fail = eval { $save->( $write_target, { backend => 'claude', messages => [] }, $paths ); 1 } ? '' : $@;
        like( $write_fail, qr/\AUnable to close \Q$pending_path\E/,
            '_save_transcript dies when the pending write cannot be flushed to the device at close (via the shared atomic_write_secure helper, DD-610)' );
        unlink $pending_path;
    }

    my $readonly = File::Spec->catdir( $dir, 'readonly' );
    mkdir $readonly or die "Unable to create $readonly: $!";

    # Declared out here because later blocks in this scope reuse it.
    my $err = '';
  SKIP: {
        chmod 0500, $readonly or skip 'chmod not honored on this filesystem', 1;

        # Probe by attempting to create a file in it - -w is mode-bit arithmetic
        # and answers true for uid 0 whatever the mode.
        my $wprobe = File::Spec->catfile( $readonly, '.write-probe' );
        my $pfh;
        my $can_write = open( $pfh, '>', $wprobe ) ? do { close $pfh; unlink $wprobe; 1 } : 0;
        skip 'this process can write into a mode-0500 directory, so the write failure cannot occur', 1
          if $can_write;

        $err = '';
        eval { $save->( File::Spec->catfile( $readonly, 'blocked.json' ), { backend => 'claude', messages => [] }, $paths ); 1 } or $err = $@;
        like( $err, qr/\AUnable to write /, 'an unwritable state directory is a user-facing error' );
    }

    chmod 0700, $readonly or die "Unable to restore $readonly: $!";

    my $blocked_target = File::Spec->catdir( $dir, 'target-is-a-directory.json' );
    mkdir $blocked_target or die "Unable to create $blocked_target: $!";
    $err = '';
    eval { $save->( $blocked_target, { backend => 'claude', messages => [] }, $paths ); 1 } or $err = $@;
    like( $err, qr/\AUnable to rename /, 'a rename that cannot land is a user-facing error (via the shared atomic_write_secure helper, DD-610)' );
    unlink glob( File::Spec->catfile( $dir, 'target-is-a-directory.json.*.tmp' ) );
};

# ------------------------------------------------------------------
subtest '_run_cli reports an unexecutable command distinctly' => sub {
    my $run = $M->can('_run_cli');
    my @missing;
    my $teed = capture_stderr { @missing = $run->( ['dd-ask-no-such-command-42'] ) };
    my ( $missing_out, $missing_err, $missing_exit ) = @missing;
    is( $missing_exit, -1, 'a command that cannot be executed reports -1' );
    like( $missing_err, qr/Can't exec "dd-ask-no-such-command-42"/, 'the exec failure is reported in the captured standard error' );
    like( $teed, qr/Can't exec "dd-ask-no-such-command-42"/, 'the live tee echoes the exec failure instead of leaking it into the test output' );

    my ( $stdout, $stderr, $exit ) = $run->( [ $^X, '-e', 'print "ran\n"' ] );
    is( $exit,   0,       'a real command reports its shifted exit status' );
    is( $stdout, "ran\n", 'a real command has its stdout captured' );
};

# ------------------------------------------------------------------
subtest '_ask_claude API defaults and CLI fallback argv' => sub {
    my $ask = $M->can('_ask_claude');

    # Injected agent, empty claude config and no model: every request field must
    # come from the module defaults.
    my $ua = AskFakeUA->new( api_reply('DEFAULTED ANSWER') );
    is(
        $ask->(
            backend     => 'claude',
            prompt      => 'default question',
            model       => undef,
            images      => [],
            text_files  => [],
            history     => [],
            claude_conf => {},
            env         => { ANTHROPIC_API_KEY => 'sk-defaults' },
            ua          => $ua,
            paths       => $paths,
        ),
        'DEFAULTED ANSWER',
        'the API answer is returned when a key resolves',
    );
    my $req = $ua->{requests}[0];
    is( $req->uri->as_string, 'https://api.anthropic.com/v1/messages', 'the default base URL is used' );
    my $sent = json_decode( $req->content );
    is( $sent->{model},      'claude-opus-4-8', 'the default model is used' );
    is( $sent->{max_tokens}, 4096,              'the default max_tokens is used' );

    # No injected agent: the module must build its own LWP agent and surface the
    # transport failure from the configured base URL.
    my $err = '';
    eval {
        $ask->(
            backend     => 'claude',
            prompt      => 'configured question',
            model       => 'claude-configured',
            images      => [],
            text_files  => [],
            history     => [],
            claude_conf => { base_url => 'http://127.0.0.1:1', max_tokens => 32 },
            env         => { ANTHROPIC_API_KEY => 'sk-configured' },
            paths       => $paths,
        );
        1;
    } or $err = $@;
    like( $err, qr/\AClaude API request failed: /, 'a self-built agent surfaces the transport failure' );

    # CLI fallback: the model flag is only appended when a model is known.
    my @with_model;
    is(
        $ask->(
            backend     => 'claude',
            prompt      => 'cli question',
            model       => 'claude-cli',
            images      => [],
            text_files  => [],
            history     => [],
            claude_conf => {},
            env         => {},
            detect      => sub { return $^X },
            runner      => rec_runner( \@with_model, "CLI ANSWER\n", '', 0 ),
        ),
        'CLI ANSWER',
        'the CLI fallback answers when no key resolves',
    );
    is_deeply( [ grep { $_ eq '--model' } @{ $with_model[0] } ], ['--model'], 'a known model is passed to the claude CLI' );

    my @without_model;
    is(
        $ask->(
            backend     => 'claude',
            prompt      => 'cli question',
            model       => undef,
            images      => [],
            text_files  => [],
            history     => [],
            claude_conf => {},
            env         => {},
            detect      => sub { return $^X },
            runner      => rec_runner( \@without_model, "CLI ANSWER\n", '', 0 ),
        ),
        'CLI ANSWER',
        'the CLI fallback answers without a model too',
    );
    is_deeply( [ grep { $_ eq '--model' } @{ $without_model[0] } ], [], 'an unknown model appends no model flag' );
};

done_testing;

__END__

=pod

=head1 NAME

t/113-cli-ask-coverage.t - branch and condition coverage for the ask CLI module

=head1 PURPOSE

This test drives the decision paths of the C<dashboard ask> implementation that
the behavioural ask tests never reach: the fallback seams of C<run_ask> (process
environment, self-built layered config and path registry), blank-value handling
in backend and API-key resolution, malformed Anthropic response payloads,
attachment classification without extensions or content, transcript files that
cannot be read, written or renamed, an unexecutable backend command, and the
Anthropic request defaults used when the claude config domain is empty.

=head1 WHY IT EXISTS

The ask module is graded on all four Devel::Cover metrics, and its defensive
sides -- an undefined stderr from a failing backend CLI, a transcript whose JSON
carries no backend key, a state directory that refuses a write, an empty
attachment, a workspace reference that is present but blank -- are exactly the
paths a behavioural test never takes. Without this file those decisions ship
unexercised, so a later edit could break the fallback while every existing ask
test stays green.

=head1 WHEN TO USE

Use this file when changing option parsing, backend selection, API-key
resolution, Anthropic request construction, response parsing, attachment
classification, or transcript persistence in the ask CLI module. Extend it
whenever a new branch or condition is added there, and consult it first when the
coverage gate reports a regression for that module.

=head1 HOW TO USE

Run C<prove -lv t/113-cli-ask-coverage.t> while iterating. Every subtest calls
the module through its injectable seams -- C<env>, C<config>, C<paths>, C<out>,
C<stdin>, C<ua>, C<runner> and C<detect> -- or calls one private routine
directly, so no assistant CLI is ever executed and no network request leaves the
host except a deliberately refused connection to a closed loopback port. The
file runs from a temporary HOME, a temporary runtime state root and a temporary
working directory, so the repository's own runtime layer is never touched. To
confirm the coverage contribution, run the suite under
C<HARNESS_PERL_SWITCHES=-MDevel::Cover> and check that the ask module reports
100.0 for branch and condition.

=head1 WHAT USES IT

The repository test suite, the all-metric coverage gate, and developers changing
the ask CLI module use this file as the executable contract for its defensive
paths.

=head1 EXAMPLES

Example 1:

  prove -lv t/113-cli-ask-coverage.t

Run the ask coverage closure checks on their own.

Example 2:

  prove -lr t

Run them as part of the full repository suite before release.

Example 3:

  cover -delete
  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t
  cover -report text -select_re '^lib/' -coverage branch -coverage condition

Confirm the ask module still reports 100.0 on branch and condition after a
change.

=cut
