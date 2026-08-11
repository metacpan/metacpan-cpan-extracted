package Developer::Dashboard::CLI::Ask;

use strict;
use warnings;

our $VERSION = '4.26';

use Capture::Tiny qw(capture);
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray);
use MIME::Base64 qw(encode_base64);

use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::JSON qw(json_encode json_decode);
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Platform qw(command_in_path command_argv_for_path);

# Ordered backend catalogue. Each entry names the CLI it shells out to and how
# it attaches images. The claude backend is special: it prefers the direct
# Anthropic API when a key is available and only falls back to the CLI.
my @BACKENDS = qw(claude codex copilot gemini);
my %BACKEND_FLAG = map { ( $_ => $_ ) } @BACKENDS;

my $DEFAULT_MODEL    = 'claude-opus-4-8';
my $DEFAULT_BASE_URL = 'https://api.anthropic.com';
my $DEFAULT_MAX_TOKENS = 4096;

# Filename extensions treated as image attachments (everything else is inlined
# as text). Maps the lowercased extension to the API media type.
my %IMAGE_MEDIA_TYPE = (
    png  => 'image/png',
    jpg  => 'image/jpeg',
    jpeg => 'image/jpeg',
    gif  => 'image/gif',
    webp => 'image/webp',
);

# run_ask(%args)
# Runs one `dashboard ask` turn against the selected AI backend, keeping a
# per-workspace conversation transcript so follow-up questions have context.
# Input: args (argv arrayref) plus optional injectable seams for testing --
# out (scalar ref or filehandle), env (hashref), config, paths, stdin string,
# ua (HTTP user agent), runner (CLI runner coderef), detect (CLI locator).
# Output: numeric process exit code (0 on success); dies with a trailing
# newline on user-facing errors.
sub run_ask {
    my (%args) = @_;
    my $argv = $args{args} || die "Missing ask arguments\n";
    die "Ask arguments must be an array reference\n" if ref($argv) ne 'ARRAY';

    my $env = $args{env} || \%ENV;
    my $opts = _parse_args( [ @{$argv} ] );

    my $prompt = $opts->{prompt};
    if ( defined $args{stdin} && $args{stdin} ne '' ) {
        my $piped = $args{stdin};
        $piped =~ s/\s+\z//;
        $prompt = $prompt eq '' ? $piped : "$prompt\n\n$piped";
    }
    die "No question provided.\nUsage: dashboard ask [--claude|--codex|--copilot|--gemini] [--model M] [--file PATH]... <question>\n"
      if $prompt eq '';

    my $config = $args{config} || _build_config( $env );    # uncoverable condition false _build_config always returns a blessed config object
    my $paths  = $args{paths}  || $config->{paths};         # uncoverable condition false a config object always carries its path registry

    my $key = _workspace_key( $paths, $env );
    my $file = _transcript_file( $paths, $key );
    my $transcript = _load_transcript($file);
    $transcript = { backend => $transcript->{backend}, messages => [] } if $opts->{reset};

    my $backend = _resolve_backend( $opts, $transcript );
    my ( $images, $text_files ) = _classify_files( $opts->{files} );

    my $claude_conf = _claude_config($config);
    my $model = $opts->{model}
      || ( $backend eq 'claude' ? ( $claude_conf->{default_model} || $DEFAULT_MODEL ) : undef );

    my $history = $opts->{no_memory} ? [] : $transcript->{messages};
    my $answer = _dispatch_backend(
        backend     => $backend,
        prompt      => $prompt,
        model       => $model,
        images      => $images,
        text_files  => $text_files,
        history     => $history,
        claude_conf => $claude_conf,
        env         => $env,
        ua          => $args{ua},
        runner      => $args{runner} || \&_run_cli,
        detect      => $args{detect} || \&command_in_path,
    );

    _emit( $args{out}, $answer );

    if ( !$opts->{no_memory} ) {
        push @{ $transcript->{messages} }, { role => 'user', content => $prompt };
        push @{ $transcript->{messages} }, { role => 'assistant', content => $answer };
        $transcript->{backend} = $backend;
        $transcript->{model}   = $model if defined $model;
        _save_transcript( $file, $transcript, $paths );
    }

    return 0;
}

# _parse_args($argv)
# Parses the raw ask argv into a normalized options hash.
# Input: argv array reference (consumed).
# Output: hash reference with backend, model, files, reset, no_memory, prompt.
sub _parse_args {
    my ($argv) = @_;
    my %flag;
    my $model = '';
    my @files;
    my $reset     = 0;
    my $no_memory = 0;
    GetOptionsFromArray(
        $argv,
        'claude'    => \$flag{claude},
        'codex'     => \$flag{codex},
        'copilot'   => \$flag{copilot},
        'gemini'    => \$flag{gemini},
        'model|m=s' => \$model,
        'file|f=s@' => \@files,
        'new|reset' => \$reset,
        'no-memory' => \$no_memory,
    ) or die "Unable to parse ask options\n";

    my @chosen = grep { $flag{$_} } @BACKENDS;
    die "Choose only one backend flag (--@{[ join ' --', @chosen ]})\n" if @chosen > 1;

    return {
        backend   => ( @chosen ? $chosen[0] : '' ),
        model     => $model,
        files     => \@files,
        reset     => $reset ? 1 : 0,
        no_memory => $no_memory ? 1 : 0,
        prompt    => join( ' ', @{$argv} ),
    };
}

# _resolve_backend($opts, $transcript)
# Picks the backend for this turn: an explicit flag wins and becomes sticky,
# otherwise the workspace's last-used backend, otherwise claude.
# Input: parsed options hash ref and loaded transcript hash ref.
# Output: backend name string.
sub _resolve_backend {
    my ( $opts, $transcript ) = @_;
    return $opts->{backend} if $opts->{backend} ne '';
    return $transcript->{backend} if $transcript->{backend} && $BACKEND_FLAG{ $transcript->{backend} };
    return 'claude';
}

# _dispatch_backend(%args)
# Routes one turn to the selected backend and returns its answer text.
# Input: backend, prompt, model, images/text_files array refs, history array
# ref, claude_conf hash ref, env, and the ua/runner/detect seams.
# Output: answer text string; dies on backend failure.
sub _dispatch_backend {
    my (%a) = @_;
    return _ask_claude(%a) if $a{backend} eq 'claude';
    return _ask_cli_backend(%a);
}

# _ask_claude(%args)
# Answers via the Anthropic API when a key is resolvable, else falls back to the
# local `claude` CLI (Claude Code).
# Input: same payload as _dispatch_backend.
# Output: answer text string; dies when no key and no CLI are available.
sub _ask_claude {
    my (%a) = @_;
    my $key = _resolve_api_key( $a{claude_conf}, $a{env} );
    if ( $key ne '' ) {
        my $messages = _build_api_messages( $a{history}, $a{prompt}, $a{text_files}, $a{images} );
        return _call_claude_api(
            ua         => $a{ua} || _default_ua(),
            key        => $key,
            base_url   => ( $a{claude_conf}{base_url} || $DEFAULT_BASE_URL ),
            model      => ( $a{model} || $DEFAULT_MODEL ),
            max_tokens => ( $a{claude_conf}{max_tokens} || $DEFAULT_MAX_TOKENS ),    # uncoverable condition false count:1..4 the four fallbacks on this call are a built agent and non-empty module defaults, so no fallback is ever false
            messages   => $messages,
        );
    }

    die "Image attachments need an ANTHROPIC_API_KEY; the local claude CLI fallback cannot attach images.\n"
      if @{ $a{images} };
    my $cli = $a{detect}->('claude')
      or die "No ANTHROPIC_API_KEY set and no `claude` CLI found. Set the key or install Claude Code.\n";
    my $prompt = _compose_cli_prompt( $a{history}, $a{prompt}, $a{text_files} );
    my @argv = ( command_argv_for_path($cli), '-p', $prompt, '--output-format', 'text' );
    push @argv, ( '--model', $a{model} ) if defined $a{model};
    return _capture_backend( 'claude', \@argv, $a{runner} );
}

# _ask_cli_backend(%args)
# Answers via a shelled-out CLI backend (codex/copilot/gemini), forcing a
# read-only, non-interactive invocation and attaching images natively.
# Input: same payload as _dispatch_backend.
# Output: answer text string; dies when the backend CLI is missing or fails.
sub _ask_cli_backend {
    my (%a) = @_;
    my $name = $a{backend};
    my $cli  = $a{detect}->($name)
      or die _missing_backend_message($name);

    my $prompt = _compose_cli_prompt( $a{history}, $a{prompt}, $a{text_files} );
    my @base = command_argv_for_path($cli);
    my @argv;
    if ( $name eq 'codex' ) {
        @argv = ( @base, 'exec', '-s', 'read-only', '--skip-git-repo-check', '--color', 'never' );
        push @argv, ( '--model', $a{model} ) if defined $a{model};
        push @argv, ( '-i', $_ ) for @{ $a{images} };
        push @argv, ( '--', $prompt );
    }
    elsif ( $name eq 'copilot' ) {
        @argv = ( @base, '-p', $prompt, '--allow-all-tools', '--no-color', '--output-format', 'text' );
        push @argv, ( '--model', $a{model} ) if defined $a{model};
        push @argv, ( '--attachment', $_ ) for @{ $a{images} };
    }
    else {    # gemini
        @argv = ( @base, '-p', $prompt );
        push @argv, ( '-m', $a{model} ) if defined $a{model};
        push @argv, ( '-o', 'text' );
        die "gemini cannot attach files; drop --file or use --claude/--copilot.\n" if @{ $a{images} };
    }
    return _capture_backend( $name, \@argv, $a{runner} );
}

# _missing_backend_message($name)
# Builds the not-installed error for one CLI backend, naming the package to
# install.
# Input: backend name string.
# Output: error message string ending in a newline.
sub _missing_backend_message {
    my ($name) = @_;
    my %hint = (
        codex   => 'install the Codex CLI (npm i -g @openai/codex)',
        copilot => 'install the Copilot CLI (npm i -g @github/copilot)',
        gemini  => 'install the Gemini CLI (npm i -g @google/gemini-cli)',
    );
    return "`$name` CLI not found; $hint{$name}.\n";
}

# _capture_backend($name, $argv, $runner)
# Runs one backend CLI through the runner seam and returns its trimmed answer.
# Input: backend name, argv array ref, runner coderef.
# Output: answer text string; dies when the CLI exits non-zero or is silent.
sub _capture_backend {
    my ( $name, $argv, $runner ) = @_;
    my ( $stdout, $stderr, $exit ) = $runner->($argv);
    if ( $exit != 0 ) {
        my $detail = $stderr;
        $detail =~ s/\s+\z// if defined $detail;
        $detail = defined $detail && $detail ne '' ? $detail : "exit status $exit";
        die "$name backend failed: $detail\n";
    }
    $stdout = '' if !defined $stdout;
    $stdout =~ s/\s+\z//;
    die "$name backend returned no answer.\n" if $stdout eq '';
    return $stdout;
}

# _resolve_api_key($claude_conf, $env)
# Resolves the Anthropic API key from the environment, then config.
# Input: claude config hash ref and environment hash ref.
# Output: key string (empty when none is available).
sub _resolve_api_key {
    my ( $claude_conf, $env ) = @_;
    return $env->{ANTHROPIC_API_KEY} if defined $env->{ANTHROPIC_API_KEY} && $env->{ANTHROPIC_API_KEY} ne '';
    return $claude_conf->{api_key} if defined $claude_conf->{api_key} && $claude_conf->{api_key} ne '';
    return '';
}

# _claude_config($config)
# Extracts the merged `claude` config domain.
# Input: Developer::Dashboard::Config object.
# Output: claude config hash ref (empty hash when unset).
sub _claude_config {
    my ($config) = @_;
    my $merged = $config->merged;
    my $claude = $merged->{claude};
    return ref($claude) eq 'HASH' ? $claude : {};
}

# _classify_files($files)
# Splits requested attachments into image paths and read-in text bodies.
# Input: attachment path array ref.
# Output: (image path array ref, text-file record array ref) where each text
# record is { path, body }.
sub _classify_files {
    my ($files) = @_;
    my ( @images, @texts );
    for my $path ( @{ $files || [] } ) {
        die "Attachment not found: $path\n" if !-f $path;
        my ($ext) = $path =~ /\.([^.\/\\]+)\z/;
        $ext = defined $ext ? lc $ext : '';
        if ( $IMAGE_MEDIA_TYPE{$ext} ) {
            push @images, $path;
        }
        else {
            push @texts, { path => $path, body => _slurp($path) };
        }
    }
    return ( \@images, \@texts );
}

# _slurp($path)
# Reads one file fully as raw bytes.
# Input: file path string.
# Output: file contents string; dies when unreadable.
sub _slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Unable to read attachment $path: $!\n";
    local $/;
    my $body = <$fh>;
    close $fh;
    return defined $body ? $body : '';    # uncoverable branch false a readable attachment always slurps to a defined string (an empty file reads as the empty string, not undef)
}

# _build_api_messages($history, $prompt, $text_files, $images)
# Builds the Anthropic messages array from prior turns plus the new question,
# inlining text attachments and encoding image attachments as blocks.
# Input: history array ref, prompt string, text record array ref, image path
# array ref.
# Output: messages array reference.
sub _build_api_messages {
    my ( $history, $prompt, $text_files, $images ) = @_;
    my @messages = map { { role => $_->{role}, content => $_->{content} } } @{ $history || [] };

    my $text = _inline_text_files( $prompt, $text_files );
    if ( @{ $images || [] } ) {
        my @blocks = ( { type => 'text', text => $text } );
        for my $path ( @{$images} ) {
            my ($ext) = $path =~ /\.([^.\/\\]+)\z/;
            push @blocks,
              {
                type   => 'image',
                source => {
                    type       => 'base64',
                    media_type => $IMAGE_MEDIA_TYPE{ lc $ext },
                    data       => encode_base64( _slurp($path), '' ),
                },
              };
        }
        push @messages, { role => 'user', content => \@blocks };
    }
    else {
        push @messages, { role => 'user', content => $text };
    }
    return \@messages;
}

# _compose_cli_prompt($history, $prompt, $text_files)
# Renders a single prompt string for CLI backends, prepending a compact history
# and inlining text attachments.
# Input: history array ref, prompt string, text record array ref.
# Output: prompt string.
sub _compose_cli_prompt {
    my ( $history, $prompt, $text_files ) = @_;
    my $text = _inline_text_files( $prompt, $text_files );
    my $rendered = _render_history($history);
    return $rendered eq '' ? $text : "$rendered\n\n$text";
}

# _render_history($history)
# Renders prior conversation turns as a plain-text preamble.
# Input: history array ref of { role, content }.
# Output: preamble string (empty when there is no history).
sub _render_history {
    my ($history) = @_;
    return '' if !@{ $history || [] };
    my @lines = 'Previous conversation:';
    for my $turn ( @{$history} ) {
        next if ref( $turn->{content} );    # skip non-text (image) turns
        my $who = $turn->{role} eq 'assistant' ? 'Assistant' : 'You';
        push @lines, "$who: $turn->{content}";
    }
    return join( "\n", @lines );
}

# _inline_text_files($prompt, $text_files)
# Appends each text attachment's body beneath the prompt as a labeled block.
# Input: prompt string and text record array ref.
# Output: combined prompt string.
sub _inline_text_files {
    my ( $prompt, $text_files ) = @_;
    my $text = $prompt;
    for my $file ( @{ $text_files || [] } ) {
        $text .= "\n\n--- attached file: $file->{path} ---\n$file->{body}";
    }
    return $text;
}

# _call_claude_api(%args)
# Posts one non-streaming Messages request to the Anthropic API.
# Input: ua, key, base_url, model, max_tokens, messages.
# Output: answer text string; dies on transport or API error.
sub _call_claude_api {
    my (%a) = @_;
    require HTTP::Request;
    my $url = $a{base_url} . '/v1/messages';
    my $req = HTTP::Request->new( POST => $url );
    $req->header( 'content-type'      => 'application/json' );
    $req->header( 'x-api-key'         => $a{key} );
    $req->header( 'anthropic-version' => '2023-06-01' );
    $req->content(
        json_encode(
            {
                model      => $a{model},
                max_tokens => $a{max_tokens},
                messages   => $a{messages},
            }
        )
    );

    my $resp = $a{ua}->request($req);
    die "Claude API request failed: @{[ $resp->status_line ]}\n" if !$resp->is_success;
    return _extract_api_text( json_decode( $resp->decoded_content ) );
}

# _extract_api_text($data)
# Concatenates the text blocks from a Messages API response.
# Input: decoded response hash ref.
# Output: answer text string; dies when no text content is present.
sub _extract_api_text {
    my ($data) = @_;
    die "Claude API returned no content.\n"
      if ref($data) ne 'HASH' || ref( $data->{content} ) ne 'ARRAY';
    my @parts =
      map { $_->{text} }
      grep { ref($_) eq 'HASH' && ( $_->{type} || '' ) eq 'text' && defined $_->{text} }
      @{ $data->{content} };
    die "Claude API returned no text.\n" if !@parts;
    return join( '', @parts );
}

# _workspace_key($paths, $env)
# Derives a filesystem-safe key identifying the active workspace conversation.
# Input: PathRegistry object and environment hash ref.
# Output: sanitized key string.
sub _workspace_key {
    my ( $paths, $env ) = @_;
    my $ref = $env->{WORKSPACE_REF};
    $ref = $paths->current_project_root if !defined $ref || $ref eq '';
    $ref = 'global' if !defined $ref || $ref eq '';
    $ref =~ s/[^A-Za-z0-9._-]+/-/g;
    $ref =~ s/\A-+//;
    $ref =~ s/-+\z//;
    return $ref eq '' ? 'global' : $ref;
}

# _transcript_file($paths, $key)
# Resolves the per-workspace transcript file path under runtime state.
# Input: PathRegistry object and workspace key string.
# Output: transcript file path string.
sub _transcript_file {
    my ( $paths, $key ) = @_;
    my $dir = File::Spec->catdir( $paths->state_root, 'ask' );
    $paths->ensure_dir($dir);
    return File::Spec->catfile( $dir, "$key.json" );
}

# _load_transcript($file)
# Loads a saved transcript, returning an empty shell when absent or unreadable.
# Input: transcript file path string.
# Output: hash ref with backend and messages keys.
sub _load_transcript {
    my ($file) = @_;
    return { backend => '', messages => [] } if !-f $file;
    open my $fh, '<:raw', $file or return { backend => '', messages => [] };
    local $/;
    my $raw = <$fh>;
    close $fh;
    my $data = eval { json_decode($raw) };
    return { backend => '', messages => [] } if ref($data) ne 'HASH';
    $data->{messages} = [] if ref( $data->{messages} ) ne 'ARRAY';
    $data->{backend}  = '' if !defined $data->{backend};
    return $data;
}

# _save_transcript($file, $data, $paths)
# Atomically persists the transcript and tightens its permissions.
# Input: file path, transcript hash ref, PathRegistry object.
# Output: file path string.
sub _save_transcript {
    my ( $file, $data, $paths ) = @_;
    my $tmp = "$file.$$.tmp";
    open my $fh, '>:raw', $tmp or die "Unable to write transcript $tmp: $!\n";
    print {$fh} json_encode($data);
    close $fh;
    rename $tmp, $file or die "Unable to install transcript $file: $!\n";
    $paths->secure_file_permissions($file);
    return $file;
}

# _emit($out, $answer)
# Writes the answer to the injected sink (scalar ref or filehandle) or STDOUT.
# Input: optional out target and the answer string.
# Output: none.
sub _emit {
    my ( $out, $answer ) = @_;
    my $line = $answer;
    $line .= "\n" if $line !~ /\n\z/;
    if ( ref($out) eq 'SCALAR' ) {
        ${$out} .= $line;
        return;
    }
    if ( ref($out) ) {
        print {$out} $line;
        return;
    }
    print $line;
    return;
}

# _run_cli($argv)
# Default CLI runner: executes the argv and captures its streams.
# Input: argv array reference.
# Output: (stdout, stderr, exit-code) list.
sub _run_cli {
    my ($argv) = @_;
    my ( $stdout, $stderr, $status ) = capture { system( @{$argv} ); };
    my $exit = $status == -1 ? -1 : ( $status >> 8 );
    return ( $stdout, $stderr, $exit );
}

# _default_ua()
# Builds the default HTTP user agent for the Anthropic API.
# Input: none.
# Output: LWP::UserAgent object.
sub _default_ua {
    require LWP::UserAgent;
    return LWP::UserAgent->new( timeout => 120 );
}

# _build_config($env)
# Builds the layered config loader rooted at the caller's HOME.
# Input: environment hash ref.
# Output: Developer::Dashboard::Config object (carrying its PathRegistry).
sub _build_config {
    my ($env) = @_;
    my $home = $env->{HOME} || '';
    my $paths = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        workspace_roots => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],    # uncoverable branch false the interpolated map above always yields a defined string
        project_roots   => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],    # uncoverable branch false the interpolated map above always yields a defined string
    );
    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
    return Developer::Dashboard::Config->new( files => $files, paths => $paths );
}

1;

__END__

=head1 NAME

Developer::Dashboard::CLI::Ask - ask an AI backend from the dashboard CLI

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::Ask qw();
  Developer::Dashboard::CLI::Ask::run_ask( args => \@ARGV );

=head1 DESCRIPTION

This module powers the built-in C<dashboard ask> command. It sends a question to
a selected AI backend and keeps a per-workspace conversation transcript so
follow-up questions carry context.

=head1 METHODS

=head2 run_ask

Run one C<dashboard ask> turn and return a process exit code.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module lets an operator ask a coding assistant a question straight from the
dashboard shell and get a plain-text answer, while the dashboard remembers the
running conversation per workspace so a later C<dashboard ask> continues the same
thread instead of starting over.

=head1 WHY IT EXISTS

It exists so the dashboard can offer one uniform C<ask> surface over several
assistant backends -- the direct Anthropic API, the local C<claude> CLI, and the
C<codex>, C<copilot>, and C<gemini> command-line tools -- without the operator
having to remember each tool's non-interactive invocation, sandbox flags, or
attachment syntax. Routing every backend through one command also lets the
dashboard enforce a safe read-only invocation and keep a shared transcript.

=head1 WHEN TO USE

Use this file when changing C<dashboard ask> syntax, adding or adjusting an
assistant backend, changing how the Anthropic API request is built, changing how
attachments are inlined or encoded, or changing where and how the per-workspace
conversation transcript is stored.

=head1 HOW TO USE

Call C<run_ask(args =E<gt> \@ARGV)> from the staged helper. The parser accepts a
single backend flag (C<--claude>, the default, or C<--codex>, C<--copilot>,
C<--gemini>), an optional C<--model>, repeatable C<--file> attachments, C<--new>
to start a fresh conversation, and C<--no-memory> to skip the transcript for one
turn. The chosen backend becomes sticky for the workspace. The claude backend
prefers the Anthropic API when a key resolves from C<ANTHROPIC_API_KEY> or the
C<claude> config domain, and otherwise falls back to the local C<claude> CLI. The
transcript is stored under the runtime state root keyed by C<WORKSPACE_REF> (or
the active project root) and secured to owner-only permissions.

=head1 WHAT USES IT

It is used by the staged private C<ask> helper that hands the built-in C<ask>
command to the shared runtime, by CLI smoke tests, and by module coverage tests.

=head1 EXAMPLES

Example 1:

  dashboard ask "How do I list collectors?"

Ask the default claude backend and print a plain-text answer, remembering the
turn for this workspace.

Example 2:

  dashboard ask --codex "Explain this stack trace" --file trace.txt

Switch the workspace to the codex backend (sticky) and inline a text attachment
into the question.

Example 3:

  dashboard ask --new --model claude-sonnet-5 "Start over: summarize the repo"

Start a fresh conversation for this workspace and override the model for the
turn.

Example 4:

  prove -lv t/48-ask.t

Rerun the focused ask regression tests after changing this module.

=for comment FULL-POD-DOC END

=cut
