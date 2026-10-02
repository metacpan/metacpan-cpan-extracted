package Langertha::Raider::Skill;
our $VERSION = '0.503';
# ABSTRACT: Generate a "how to use raider" documentation file from a live Langertha::Raider::CLI configuration

use Moose;
use namespace::autoclean;
use Path::Tiny;


has app => (
  is       => 'ro',
  isa      => 'Langertha::Raider::CLI',
  required => 1,
);


has name => (
  is      => 'ro',
  isa     => 'Str',
  default => 'raider',
);


has description => (
  is      => 'ro',
  isa     => 'Str',
  default => 'How to drive the `raider` CLI — an autonomous Perl command-line agent (Langertha::Raider::CLI) with filesystem, bash, and web tools.',
);

sub _active_web_providers {
  my @p = ('DuckDuckGo (keyless)');
  push @p, 'Brave'  if $ENV{BRAVE_API_KEY};
  push @p, 'Serper' if $ENV{SERPER_API_KEY};
  push @p, 'Google CSE' if $ENV{GOOGLE_API_KEY} && $ENV{GOOGLE_CSE_ID};
  return join(', ', @p);
}

# The tool table: the tools the app mounts -- the same set its prompt
# describes and its engine offers (ADR 0005) -- each with its signature and
# the first sentence of its description.
sub _tools_table {
  my ($self) = @_;
  my $app = $self->app;
  my @rows = map {
    my $purpose = $_->description // '';
    $purpose =~ s/\.(?:\s.*)?\z//s;
    [ '`'.$app->_tool_signature($_).'`', $purpose =~ s/\|/\\|/gr ];
  } $app->_mounted_tools;
  my @width = ( length 'Tool', length 'Purpose' );
  for my $row (@rows) {
    for my $col (0, 1) {
      $width[$col] = length $row->[$col] if length $row->[$col] > $width[$col];
    }
  }
  my $line = sub { '| '.join(' | ', map { sprintf '%-'.$width[$_].'s', $_[$_] } 0, 1)." |\n" };
  return $line->('Tool', 'Purpose')
    .'|'.join('|', map { '-' x ($_ + 2) } @width)."|\n"
    .join('', map { $line->(@$_) } @rows);
}


sub markdown {
  my ($self) = @_;
  my $app = $self->app;
  my $source  = $app->mission_source;
  my $instructions = $app->instructions;
  my $file    = $instructions->label;
  my $persona = $source eq '-M'  ? 'from -M ('.$file.' not used)'
              : $source eq $file ? 'custom (loaded from '.$instructions->file.')'
              :                    'Langertha (default viking persona)';
  $persona .= ', bare (no '.$file.' or skills, only explicit packs)' if $app->bare;
  my $config  = $app->config;
  my $yml_loaded = $config->file_exists && $config->data ? 'yes ('.$config->file.')' : 'no';
  my $model   = $app->has_model ? $app->model : '(engine default)';
  my $env     = $app->api_key_env // '(none)';
  my $web     = _active_web_providers();

  return <<"MD";
# Using `raider`

`raider` is a Perl CLI that wraps `Langertha::Raider` with a fixed toolbox
and keeps a persistent conversation with an LLM. This is how to drive it.

## Current live configuration

- Engine: **@{[ $app->engine_name ]}** (env: `$env`)
- Model: **$model**
- Persona: $persona
- Working root: `@{[ $app->root ]}`
- `@{[ $config->label ]}` loaded: $yml_loaded
- Web-search providers active: $web

## Minimal usage

```bash
raider                           # REPL in the current directory
raider "do this task"            # one-shot
echo "task" | raider             # from a pipe
raider --json "task" | jq .      # script-friendly output
```

Engine/model/api-key can be set via CLI:

```bash
raider -e openai -m gpt-4o-mini -k sk-...
raider -o temperature=0.1 -o response_size=4096
```

Otherwise the first `*_API_KEY` in the environment picks the engine, and a
cheap model is selected automatically.

## Tools the agent has

@{[ $self->_tools_table ]}
Filesystem tools are confined to the working root. `bash` inherits it.

## Telling the agent what to do

The agent runs until it stops emitting tool calls; then control returns to
the REPL prompt, where your next line continues the same conversation.
There is **no** ask/pause/abort tool — the agent just does things and
reports when done.

The default persona speaks in terse caveman style (no articles, no filler,
technical terms exact). Say "normal mode" to switch to prose.

Customize the persona and the rules with an instructions file in the
working directory, `.raider/instructions.md` or the legacy `.raider.md`, or
by running `/prompt` in the REPL (launches a sub-agent that edits the file
in use for you). With both present only `.raider/instructions.md` is read,
and raider warns about the other.

## Slash commands inside the REPL

| Command                  | Does                                                 |
|--------------------------|------------------------------------------------------|
| `/help`                  | Command list                                         |
| `/clear`                 | Reset conversation history and token counters        |
| `/metrics`               | Cumulative raid metrics                              |
| `/stats`                 | Tokens in / out / total this session                 |
| `/reload`                | Re-read the instructions file, hot-swap the mission  |
| `/prompt`                | Launch the prompt-builder (edits the instructions)   |
| `/skill [PATH]`          | Export plain-markdown how-to-use doc                 |
| `/skill-claude [PATH]`   | Export Claude Code SKILL.md with YAML frontmatter    |
| `/config`                | Show each setting and where it came from             |
| `/model [NAME]`          | Save NAME as model to the config file (next start)   |
| `/model list [FILTER]`   | List the engine's models                             |
| `/packs`                 | List the packs and which are active                  |
| `/pack on NAME`          | Enable a pack, reloads the mission                   |
| `/pack off NAME`         | Disable a pack, reloads the mission                  |
| `/pack NAME`             | Toggle a pack                                        |
| `/quit` `/exit` `:q`     | Leave                                                |

## Loading project skills

Profile flags preload per-tool agent files into the mission and persist
themselves to the config file after first use:

- `--claude` — loads `CLAUDE.md` and any `.claude/skills/*/SKILL.md`.
- `--openai` / `--codex` — loads `AGENTS.md`.
- `--skills DIR` — extra plain-markdown directory (repeatable).

When a well-known file is present but its profile isn't active, the startup
banner shows a `seeing FILE, ignoring (use --<profile> to load)` hint.

## Engine options via the config file

The config file is `.raider/config.yml` in the working root, else the
legacy `.raider.yml` there; both take the same keys. With both present only
`.raider/config.yml` is read, and raider warns about the other.

Flat form:

```yaml
temperature: 0.2
response_size: 2048
```

Per-engine with a shared default:

```yaml
default:
  temperature: 0.3
anthropic:
  temperature: 0.7
  response_size: 8192
```

CLI `-o key=value` overrides the file.

## Context window and rate limits

- `max_context_tokens = 40000`
- `context_compress_threshold = 0.7`
- `max_iterations = 10000`

At 70% of the token budget, `Langertha::Raider` compresses the history
automatically. Each raid prints `history N msgs, X/Y tok (Z%)` so you can
see how close you are.

## Environment variables for API keys

`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `DEEPSEEK_API_KEY`, `GROQ_API_KEY`,
`MISTRAL_API_KEY`, `GEMINI_API_KEY`, `MINIMAX_API_KEY`, `CEREBRAS_API_KEY`,
`OPENROUTER_API_KEY`.

Web-search extras: `BRAVE_API_KEY`, `SERPER_API_KEY`,
`GOOGLE_API_KEY` + `GOOGLE_CSE_ID`.
MD
}


sub claude_skill {
  my ($self) = @_;
  my $name = $self->name;
  my $desc = $self->description;
  $desc =~ s/"/\\"/g;
  my $frontmatter = <<"FM";
---
name: $name
description: |
  $desc
  Use this skill whenever the user invokes `raider`, asks about the
  `Langertha::Raider::CLI` CLI, wants to customize its persona via
  `.raider/instructions.md` or `.raider.md`,
  or is reading a transcript that contains `raider>` prompts and
  `bash`/`read_file`/`web_search` tool calls.
---

FM
  return $frontmatter . $self->markdown;
}


sub write_markdown {
  my ($self, $file) = @_;
  my $p = path($file);
  $p->parent->mkpath unless -d $p->parent;
  $p->spew_utf8($self->markdown);
  return $p;
}


sub write_claude_skill {
  my ($self, $file) = @_;
  $file //= path($self->app->root)->child('.claude/skills', $self->name, 'SKILL.md');
  my $p = path($file);
  $p->parent->mkpath unless -d $p->parent;
  $p->spew_utf8($self->claude_skill);
  return $p;
}


sub legacy_claude_skill {
  my ($self) = @_;
  my $p = path($self->app->root)->child('.claude/skills/app-raider/SKILL.md');
  return -f $p ? $p : ();
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Skill - Generate a "how to use raider" documentation file from a live Langertha::Raider::CLI configuration

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $skill = Langertha::Raider::Skill->new(app => $app);

    # Plain markdown for any AI tool / human
    my $md = $skill->markdown;

    # Claude Code SKILL.md with frontmatter, written to .claude/skills/...
    $skill->write_claude_skill('.claude/skills/raider/SKILL.md');

=head1 DESCRIPTION

Builds a self-describing how-to-use-raider document from a running
L<Langertha::Raider::CLI> instance. The generated text reflects the actual live
configuration: selected engine and model, which web-search providers are
currently enabled based on environment variables, which persona layer is
active (default Langertha, a custom F<.raider/instructions.md> or
F<.raider.md>, or a C<-M> mission),
and so on. Its tool table lists the tools the app mounts -- the same set
its prompt describes and its engine offers (ADR 0005) -- each with its
signature and the first sentence of its description, so the Perl tools
appear only when granted and the Hall tools only under a Hall.

Two output variants are supported:

=over

=item * L</markdown> — engine-agnostic markdown (no frontmatter). Drop into
any README-ish place or feed it to a non-Claude agent.

=item * L</claude_skill> — Claude Code SKILL.md with a proper YAML
frontmatter block. Write to C<.claude/skills/raider/SKILL.md> (or
wherever your skill directory lives) with L</write_claude_skill>.

=back

=head2 app

The L<Langertha::Raider::CLI> instance to describe. Required.

=head2 name

Skill name used in the Claude frontmatter. Defaults to C<raider>.

=head2 description

One-line description used in the Claude frontmatter.

=head2 markdown

Returns the plain markdown document (no frontmatter).

=head2 claude_skill

Returns the markdown with a Claude Code YAML frontmatter block prepended.

=head2 write_markdown

    $skill->write_markdown('/path/to/SKILL.md');

Writes the plain markdown to a file (creates parent dirs).

=head2 write_claude_skill

    $skill->write_claude_skill;                 # default path
    $skill->write_claude_skill('path/to/SKILL.md');

Writes the Claude SKILL.md (with frontmatter) to C<$path>. The default path
is C<< .claude/skills/<name>/SKILL.md >> relative to the app's working root.

=head2 legacy_claude_skill

Returns the L<Path::Tiny> of a Claude skill exported by an older release
under the former default name (C<.claude/skills/app-raider/SKILL.md> below
the working root), or nothing when there is none. The C<--claude> profile
would load it next to the current one, so the CLI points it out after an
export.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::CLI>

=item * L<Langertha::Raider>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
