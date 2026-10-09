package Developer::Dashboard::CLI::Ask;

use strict;
use warnings;

our $VERSION = '5.73';

use Capture::Tiny qw(capture tee);
use File::Find qw(find);
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray);
use MIME::Base64 qw(encode_base64);

use Developer::Dashboard::Config;
use Developer::Dashboard::FileSlurp qw(slurp_file);
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::JSON qw(json_encode json_decode);
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Platform qw(command_in_path command_argv_for_path);

# Ordered backend catalogue. Each entry names the CLI it shells out to and how
# it attaches images. The claude backend is special: it prefers the direct
# Anthropic API when a key is available and only falls back to the CLI.
my @BACKENDS = qw(claude codex copilot gemini nova);
my %BACKEND_FLAG = map { ( $_ => $_ ) } @BACKENDS;

my $DEFAULT_MODEL    = 'claude-opus-4-8';
my $DEFAULT_BASE_URL = 'https://api.anthropic.com';
my $DEFAULT_MAX_TOKENS = 4096;
my $NOVA_DEFAULT_MODEL    = 'nova-2-lite-v1';
my $NOVA_DEFAULT_BASE_URL = 'https://api.nova.amazon.com';
my $MAX_BACKEND_ERROR_DETAIL_BYTES = 4000;
my $MAX_TOOL_USE_ROUNDS = 10;
my $GREP_MATCH_LIMIT    = 200;

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

    # DD-1038: --help used to fall straight into GetOptionsFromArray as an
    # unrecognized option ("Unknown option: help", then die "Unable to
    # parse ask options") - the single most basic thing a CLI command can
    # support. Handled here, before any backend/transcript work, exactly
    # like --docs already is a step below.
    if ( $opts->{help} ) {
        _emit( $args{out}, _usage_text() );
        return 0;
    }

    # DD-938: --docs is a pure, cheap, static stdout path - print curated
    # onboarding context and return immediately, before any of the
    # backend/transcript/prompt machinery below ever runs. Never touches an
    # AI backend, never writes a file - the owner was explicit that this
    # replaces injecting the full (large) CLAUDE.md into every ask call,
    # not a variant of it.
    if ( $opts->{docs} ) {
        _emit( $args{out}, _docs_context() );
        return 0;
    }

    my $prompt = $opts->{prompt};
    if ( defined $args{stdin} && $args{stdin} ne '' ) {
        my $piped = $args{stdin};
        $piped =~ s/\s+\z//;
        $prompt = $prompt eq '' ? $piped : "$prompt\n\n$piped";
    }
    die "No question provided.\n" . _usage_text() if $prompt eq '';

    my $config = $args{config};
    $config = _build_config($env) if !$config;
    my $paths = $args{paths};
    $paths = $config->{paths} if !$paths;

    my $key = _workspace_key( $paths, $env );
    my $file = _transcript_file( $paths, $key );
    my $transcript = _load_transcript($file);
    $transcript = { backend => $transcript->{backend}, messages => [] } if $opts->{reset};

    # DD-938 (owner-corrected scope, live): a --docs flag or an injected
    # setup instruction is still one more thing an agent has to be told to
    # do. Since conversation memory is already scoped per workspace, the
    # workspace's genuinely first-ever ask call (no prior turns, and not a
    # --no-memory call that never persists anyway) is a zero-instruction
    # trigger: prepend the curated docs context once, here, so it travels
    # with turn one and is naturally present in every later turn's replayed
    # history without repeating it.
    if ( !@{ $transcript->{messages} } && !$opts->{no_memory} ) {
        $prompt = _docs_context() . "\n\n" . $prompt;
    }

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
        paths       => $paths,
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
    my $docs      = 0;
    my $help      = 0;
    GetOptionsFromArray(
        $argv,
        'claude'    => \$flag{claude},
        'codex'     => \$flag{codex},
        'copilot'   => \$flag{copilot},
        'gemini'    => \$flag{gemini},
        'nova'      => \$flag{nova},
        'model|m=s' => \$model,
        'file|f=s@' => \@files,
        'new|reset' => \$reset,
        'no-memory' => \$no_memory,
        'docs'      => \$docs,
        'help|h'    => \$help,
    ) or die "Unable to parse ask options\n";

    my @chosen = grep { $flag{$_} } @BACKENDS;
    die "Choose only one backend flag (--@{[ join ' --', @chosen ]})\n" if @chosen > 1;

    return {
        backend   => ( @chosen ? $chosen[0] : '' ),
        model     => $model,
        files     => \@files,
        reset     => $reset ? 1 : 0,
        no_memory => $no_memory ? 1 : 0,
        docs      => $docs ? 1 : 0,
        help      => $help ? 1 : 0,
        prompt    => join( ' ', @{$argv} ),
    };
}

# _usage_text()
# The real, complete usage text for `dashboard ask --help` - every
# backend flag (DD-1039: --nova already has a full working
# implementation but was never mentioned in any usage string, which is
# what made it look unsupported) and every other real option.
# Input: none.
# Output: usage text string, trailing newline included.
sub _usage_text {
    return <<'USAGE';
Usage: dashboard ask [--claude|--codex|--copilot|--gemini|--nova] [--model M] [--file PATH]... <question>

Backend selection (default: claude):
  --claude              Use Claude (Anthropic API, falling back to the local claude CLI)
  --codex               Use Codex
  --copilot             Use GitHub Copilot
  --gemini              Use Gemini
  --nova                Use Amazon Nova (requires NOVA_API_KEY)

Options:
  --model, -m MODEL     Override the backend's default model
  --file, -f PATH        Attach a file (repeatable) - images are attached natively, other files inlined as text
  --new, --reset          Start a fresh conversation, discarding this workspace's saved transcript
  --no-memory            Do not save this turn to the workspace transcript
  --docs                 Print curated onboarding context and exit, without contacting any backend
  --help, -h              Show this help and exit
USAGE
}

# _docs_context()
# Curated, purpose-built onboarding text for `dashboard ask --docs`
# (DD-938) - deliberately NOT the full CLAUDE.md (owner-specified: too
# large/expensive to inject on every ask call) and never written to any
# file. Makes a blank agent DD-*aware* (the DD-OOP-LAYERS stack, where a
# disposable helper script belongs) rather than DD-*expert*; `dashboard
# source --files` is the fallback for anything this summary doesn't cover.
# Input: none.
# Output: onboarding context string.
sub _docs_context {
    return <<'DOCS';
Developer Dashboard onboarding (dashboard ask --docs)

You are working on a machine with Developer Dashboard installed (two
entrypoints: `dashboard` and its short alias `d2`, same behavior). This is a
curated summary, not the whole product - use `dashboard source --files` to
list every installed file and read the real implementation for anything
this doesn't cover.

ENTRYPOINTS AND COMMAND RESOLUTION
- `dashboard <command> [args...]` and `d2 <command> [args...]` are
  equivalent. Skills nest with dots: `dashboard <skill>.<subcommand>`,
  arbitrarily deep (`dashboard nest.level1.level2.here`).
- `dashboard which <command>` prints the resolved file(s) actually backing
  any command - built-in, layered custom, or dotted skill - plus which
  per-layer hook files participate. Use this before guessing where a
  command's logic lives.
- Built-in command BODIES are not in a single binary: they are staged
  lazily as working copies under `~/.developer-dashboard/cli/dd/` from a
  shared source tree, resolved through the same layered lookup as
  everything else.

DD-OOP-LAYERS (the core architectural idea)
- Every `.developer-dashboard/` directory from `~` down through the
  current directory's parents participates in ONE inherited runtime stack:
  config, `.env` files, docker-compose layering, collectors, indicators,
  `local/lib/perl5`, static assets, and per-command hook directories all
  merge the same way. The DEEPEST layer is both the write target and the
  first lookup hit - a setting in a project-local layer overrides the same
  setting inherited from `~`.
- This is why `.env` and docker-compose config are never a single flat
  file to look for: they are resolved by walking the layer chain from the
  current directory upward.

WHERE A DISPOSABLE HELPER SCRIPT BELONGS
- If you need to write throwaway code to answer a request (e.g. "find
  every file containing 'foobar'"), do not scatter it into the workspace
  root or /tmp. Use DD's own dot-notation `cli/` convention:
  `$PWD/.d2/cli/<name>`, `$PWD/.developer-dashboard/cli/<name>`,
  `~/.d2/cli/<name>`, or `~/.developer-dashboard/cli/<name>` - matching
  where DD's own layered custom commands and skills already live.

SKILLS
- Installable repos under `<layer>/skills/<repo-name>/`, each with its own
  `cli/`, config, and isolated dependency tree. Dotted dispatch
  (`dashboard <skill>.<cmd>`) is how you invoke into one.

FINDING MORE
- `dashboard which <name>` - resolve any command to its real file(s).
- `dashboard source --files` - list every file DD installed under
  `~/perl5/{lib,bin}`, to grep/read directly.
- `dashboard ask "<question>"` (without --docs) - ask an AI backend a
  question directly, with per-workspace conversation memory; this is a
  generic ask wrapper, not itself DD-aware beyond this summary.
DOCS
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
    return _ask_nova(%a) if $a{backend} eq 'nova';
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
        my $ua = $a{ua};
        $ua = _default_ua() if !$ua;
        my $base_url = $a{claude_conf}{base_url};
        $base_url = $DEFAULT_BASE_URL if !$base_url;
        my $model = $a{model};
        $model = $DEFAULT_MODEL if !$model;
        my $max_tokens = $a{claude_conf}{max_tokens};
        $max_tokens = $DEFAULT_MAX_TOKENS if !$max_tokens;
        return _call_claude_api(
            ua         => $ua,
            key        => $key,
            base_url   => $base_url,
            model      => $model,
            max_tokens => $max_tokens,
            messages   => $messages,
            root       => $a{paths}->current_project_root,
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

# _ask_nova(%args)
# Answers via Amazon Nova's own standalone REST endpoint (DD-952) -
# api.nova.amazon.com/v1/chat/completions, bearer-token auth. This is
# architecturally identical to _ask_claude's direct-API path (see
# docs/dashboard-ask-backend-architecture.md), never AWS Bedrock/SigV4 -
# NOVA_API_KEY is a plain bearer token, not an AWS credential.
# Input: same payload as _dispatch_backend.
# Output: answer text string; dies when no NOVA_API_KEY is set or images
# are attached (Nova's image content-block shape is not implemented here).
sub _ask_nova {
    my (%a) = @_;
    my $key = $a{env}{NOVA_API_KEY};
    die "No NOVA_API_KEY set. Set it to use --nova.\n" if !defined $key || $key eq '';
    die "Image attachments are not supported with --nova.\n" if @{ $a{images} };
    my $messages = _build_api_messages( $a{history}, $a{prompt}, $a{text_files}, [] );
    my $ua = $a{ua};
    $ua = _default_ua() if !$ua;
    my $model = $a{model};
    $model = $NOVA_DEFAULT_MODEL if !$model;
    return _call_nova_api(
        ua       => $ua,
        key      => $key,
        base_url => $NOVA_DEFAULT_BASE_URL,
        model    => $model,
        messages => $messages,
    );
}

# _call_nova_api(%args)
# Posts one request to Nova's chat-completions endpoint and extracts the
# answer text.
# Input: ua, key, base_url, model, and messages array ref.
# Output: answer text string; dies on a non-success HTTP response or an
# unparseable/empty response body.
sub _call_nova_api {
    my (%a) = @_;
    require HTTP::Request;
    my $url = $a{base_url} . '/v1/chat/completions';
    my $req = HTTP::Request->new( POST => $url );
    $req->header( 'content-type'  => 'application/json' );
    $req->header( 'authorization' => "Bearer $a{key}" );
    $req->content(
        json_encode(
            {
                model    => $a{model},
                messages => $a{messages},
            }
        )
    );

    my $resp = $a{ua}->request($req);
    die "Nova API request failed: @{[ $resp->status_line ]}\n" if !$resp->is_success;
    return _extract_nova_api_text( json_decode( $resp->decoded_content ) );
}

# _extract_nova_api_text($data)
# Extracts the answer text from a Nova chat-completions response
# (OpenAI-chat-completions shape: {choices:[{message:{content}}]}), a
# genuinely different response body than Claude's {content:[...]} shape.
# Input: decoded response hash ref.
# Output: answer text string; dies when no text content is present.
sub _extract_nova_api_text {
    my ($data) = @_;
    die "Nova API returned no content.\n"
      if ref($data) ne 'HASH' || ref( $data->{choices} ) ne 'ARRAY' || !@{ $data->{choices} };
    my $content = $data->{choices}[0]{message}{content};
    die "Nova API returned no text.\n" if !defined $content || $content eq '';
    return $content;
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
        # DD-620: a runaway or misbehaving backend producing megabytes of
        # stderr must not turn into an equally huge, unwieldy exception
        # message - cap it and say how much was dropped.
        if ( length($detail) > $MAX_BACKEND_ERROR_DETAIL_BYTES ) {
            my $omitted = length($detail) - $MAX_BACKEND_ERROR_DETAIL_BYTES;
            $detail = substr( $detail, 0, $MAX_BACKEND_ERROR_DETAIL_BYTES )
              . " ... (truncated, $omitted more byte" . ( $omitted == 1 ? '' : 's' ) . ' omitted)';
        }
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
            push @texts, { path => $path, body => slurp_file( $path, raw => 1, missing_message => 'Unable to read attachment %s: %s', normalize_undef => 1 ) };
        }
    }
    return ( \@images, \@texts );
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
                    data       => encode_base64( slurp_file( $path, raw => 1, missing_message => 'Unable to read attachment %s: %s', normalize_undef => 1 ), '' ),
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
# Posts a Messages request to the Anthropic API, running a tool_use
# round-trip loop (DD-946) when the model asks to read_file/grep_repo this
# project before answering - see
# docs/dashboard-ask-backend-architecture.md for the full request/
# response shape. A plain question that never triggers a tool_use block
# returns after exactly one request, unchanged from the pre-DD-946
# behavior (AC-3).
# Input: ua, key, base_url, model, max_tokens, messages, root (project
# root the read_file/grep_repo tools are scoped to).
# Output: answer text string; dies on transport/API error or if the loop
# exceeds $MAX_TOOL_USE_ROUNDS without finishing.
sub _call_claude_api {
    my (%a) = @_;
    require HTTP::Request;
    my $url      = $a{base_url} . '/v1/messages';
    my @messages = @{ $a{messages} };
    my $tools    = _claude_tools();

    for ( 1 .. $MAX_TOOL_USE_ROUNDS ) {
        my $req = HTTP::Request->new( POST => $url );
        $req->header( 'content-type'      => 'application/json' );
        $req->header( 'x-api-key'         => $a{key} );
        $req->header( 'anthropic-version' => '2023-06-01' );
        $req->content(
            json_encode(
                {
                    model      => $a{model},
                    max_tokens => $a{max_tokens},
                    messages   => \@messages,
                    tools      => $tools,
                }
            )
        );

        my $resp = $a{ua}->request($req);
        die "Claude API request failed: @{[ $resp->status_line ]}\n" if !$resp->is_success;
        my $data = json_decode( $resp->decoded_content );
        die "Claude API returned no content.\n"
          if ref($data) ne 'HASH' || ref( $data->{content} ) ne 'ARRAY';

        return _extract_api_text($data) if ( $data->{stop_reason} || '' ) ne 'tool_use';

        push @messages, { role => 'assistant', content => $data->{content} };
        my @tool_results;
        for my $block ( @{ $data->{content} } ) {
            next if ref($block) ne 'HASH' || ( $block->{type} || '' ) ne 'tool_use';
            push @tool_results,
              {
                type        => 'tool_result',
                tool_use_id => $block->{id},
                content     => _execute_claude_tool( $block->{name}, $block->{input}, $a{root} ),
              };
        }
        push @messages, { role => 'user', content => \@tool_results };
    }
    die "Claude API tool_use loop exceeded $MAX_TOOL_USE_ROUNDS rounds without finishing.\n";
}

# _claude_tools()
# The two read-only tools offered on the direct-API tool_use loop
# (DD-946), each scoped to the current project root by
# _execute_claude_tool/_scoped_tool_path. No write or exec tool exists on
# this path (see docs/dashboard-ask-backend-architecture.md's scope note).
# Input: none.
# Output: tools array ref, in Anthropic Messages API tool shape.
sub _claude_tools {
    return [
        {
            name        => 'read_file',
            description => 'Read the full contents of one text file in this project. path must be relative to the project root; a path resolving outside the project root is refused.',
            input_schema => {
                type       => 'object',
                properties => { path => { type => 'string', description => 'File path, relative to the project root.' } },
                required   => ['path'],
            },
        },
        {
            name        => 'grep_repo',
            description => 'Search text file contents in this project for a Perl regular expression, returning matching path:line:text lines (capped). Optionally restrict the search to one subdirectory.',
            input_schema => {
                type       => 'object',
                properties => {
                    pattern => { type => 'string', description => 'Perl regular expression to search for.' },
                    path    => { type => 'string', description => 'Optional subdirectory to restrict the search to, relative to the project root.' },
                },
                required => ['pattern'],
            },
        },
    ];
}

# _execute_claude_tool($name, $input, $root)
# Runs one tool_use call locally. Never dies - a scope refusal, a missing
# file, or an unknown tool name is reported back to the model as ordinary
# tool_result content, the same way a real tool failure would be.
# Input: tool name string, input hash ref, project root string.
# Output: tool_result content string.
sub _execute_claude_tool {
    my ( $name, $input, $root ) = @_;
    return _execute_read_file( $input->{path}, $root ) if $name eq 'read_file';
    return _execute_grep_repo( $input->{pattern}, $input->{path}, $root ) if $name eq 'grep_repo';
    return "Unknown tool: $name";
}

# _execute_read_file($rel, $root)
# Reads one file, scoped to the project root (AC-2).
# Input: tool-supplied relative path string, project root string.
# Output: file contents string, or a refusal/not-found message string.
sub _execute_read_file {
    my ( $rel, $root ) = @_;
    my ( $abs, $err ) = _scoped_tool_path( $root, $rel );
    return $err if defined $err;
    return "File not found: $rel" if !-f $abs;
    my $body = eval { slurp_file( $abs, raw => 1, missing_message => 'Unable to read %s: %s', normalize_undef => 1 ) };
    return "Unable to read $rel: $@" if !defined $body;
    return $body;
}

# _execute_grep_repo($pattern, $rel, $root)
# Searches text file contents under the project root (or one subdirectory
# of it, itself scoped) for a regular expression.
# Input: pattern string, optional relative subdirectory string, project
# root string.
# Output: matching "path:line:text" lines joined by newline (capped at
# $GREP_MATCH_LIMIT), or a refusal/no-matches/bad-pattern message string.
sub _execute_grep_repo {
    my ( $pattern, $rel, $root ) = @_;
    return 'grep_repo requires a pattern.' if !defined $pattern || $pattern eq '';
    my ( $search_root, $err ) = _scoped_tool_path( $root, $rel );
    return $err if defined $err;
    my $re = eval { qr/$pattern/ };
    return "Invalid regular expression: $pattern" if !$re;

    my @matches;
    find(
        {
            no_chdir => 1,
            wanted   => sub {
                return if @matches >= $GREP_MATCH_LIMIT;
                return if !-f $_;
                return if m{/\.git/|/\.worktrees/|/local/lib/perl5/|/blib/};
                open my $fh, '<', $_ or return;
                my $n = 0;
                while ( my $line = <$fh> ) {
                    $n++;
                    last if @matches >= $GREP_MATCH_LIMIT;
                    next if $line !~ $re;
                    chomp $line;
                    push @matches, "$File::Find::name:$n:$line";
                }
            },
        },
        $search_root
    );
    return @matches ? join( "\n", @matches ) : 'No matches.';
}

# _scoped_tool_path($root, $rel)
# Resolves a tool-supplied path against the project root, refusing
# anything that would resolve outside it (AC-2). Normalizes '.'/'..'
# segments without touching the filesystem, so a nonexistent tool-supplied
# path can still be scope-checked before any -f/open is attempted.
# Input: project root string, tool-supplied relative path string (may be
# undef, meaning "the root itself").
# Output: (absolute path string, undef) on success, or (undef, refusal
# message string) when the path escapes the root.
sub _scoped_tool_path {
    my ( $root, $rel ) = @_;
    $rel = '' if !defined $rel;
    my $root_abs = _normalize_path_segments( File::Spec->rel2abs($root) );
    my $joined   = _normalize_path_segments( File::Spec->rel2abs( $rel, $root_abs ) );
    return ( $joined, undef ) if $joined eq $root_abs || index( $joined, "$root_abs/" ) == 0;
    return ( undef, "Refused: '$rel' resolves outside the project root ($root_abs)." );
}

# _normalize_path_segments($path)
# Collapses '.'/'..' segments in an absolute path string, purely
# lexically - no filesystem access, so it works on a path that does not
# exist.
# Input: absolute path string.
# Output: normalized absolute path string.
sub _normalize_path_segments {
    my ($path) = @_;
    my @out;
    for my $part ( split m{/}, $path ) {
        next if $part eq '' || $part eq '.';
        if ( $part eq '..' ) { pop @out; }
        else                 { push @out, $part; }
    }
    return '/' . join( '/', @out );
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
# Known limitation (DD-619, Q-029): collapsing every run of non-safe
# characters to a single '-' means two genuinely different refs that differ
# only in the characters being collapsed (e.g. "foo/bar" and "foo bar") can
# sanitize to the identical key and silently share transcript history. This
# is accepted as-is, deliberately: the collision is narrow (only refs
# differing exclusively in already-illegal characters) and the impact is
# shared conversation history, not data loss or a security issue. No
# collision-proofing (e.g. a hash suffix) or migration is planned.
# Input: PathRegistry object and environment hash ref.
# Output: sanitized key string.
sub _workspace_key {
    my ( $paths, $env ) = @_;
    my $ref = $env->{WORKSPACE_REF};
    $ref = $paths->current_project_root if _blank($ref);
    $ref = 'global'                     if _blank($ref);
    $ref =~ s/[^A-Za-z0-9._-]+/-/g;
    $ref =~ s/\A-+//;
    $ref =~ s/-+\z//;
    return $ref eq '' ? 'global' : $ref;
}

# _blank($val)
# True when a workspace-ref candidate is undef or the empty string - the
# single condition instance both of _workspace_key's fallback checks share
# (DD-946: restructured from two textually-identical inline `||` conditions
# to one shared sub, after Devel::Cover tracked those as two separate
# condition instances).
# Input: candidate value (may be undef).
# Output: boolean.
sub _blank {
    my ($val) = @_;
    # DD-942: PathRegistry::current_project_root (via project_root_for) only
    # ever returns undef or a genuinely non-empty directory string - every
    # `$dir` it can assign comes from -d checking a real, non-empty path
    # component, and dirname() of a non-empty string is never '' either. So
    # $val eq '' specifically (as opposed to !defined $val) can never be true
    # when this is called with current_project_root's result - confirmed by
    # reading PathRegistry.pm's own source rather than assumed. It CAN be
    # true on the first call (a defined-but-empty WORKSPACE_REF), which is
    # what keeps this a real, non-annotated condition rather than dead code.
    return !defined $val || $val eq '';
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
    # The open-failure branch is exercised by t/741-ask-io-coverage.t through a
    # CORE::GLOBAL::open override, so it runs for any uid.
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
    return $paths->atomic_write_secure( $tmp, $file, json_encode($data) );
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
# Default CLI runner: executes the argv, teeing its streams live to our own
# STDOUT/STDERR (DD-948: this is the caller's only progress feedback while
# a backend CLI runs) while still capturing them for the return value.
# Input: argv array reference.
# Output: (stdout, stderr, exit-code) list.
sub _run_cli {
    my ($argv) = @_;
    my ( $stdout, $stderr, $status ) = tee { system( @{$argv} ); };
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
        workspace_roots => [ grep { -d } map { "$home/$_" } qw(projects src work) ],
        project_roots   => [ grep { -d } map { "$home/$_" } qw(projects src work) ],
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

The direct-API C<--claude> path also runs a C<tool_use> round-trip loop
(DD-946) offering two read-only tools, C<read_file> and C<grep_repo>, both
scoped to the current project root -- so a repo-specific question can be
answered accurately even without the local C<claude> CLI's own incidental
Read/Grep access.

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
the active project root) and secured to owner-only permissions. On the
direct-API path, a question the model cannot answer from the prompt alone
triggers the C<tool_use> loop automatically -- there is no separate flag to
opt in, and a plain question that needs no repo search is unaffected.

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
