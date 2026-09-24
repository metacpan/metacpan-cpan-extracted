# Getopt::Pad

An Object::Pad based, POSIX compatible options processor on top of
Getopt::Long: options are declared as a typed spec, validated, and returned
as a runtime-generated Object::Pad object with one camelCase reader per
option and positional argument.

## Features

- Typed options (`bool`, `counter`, `string`, `int`, `float`, `file`, `dir`,
  `url`) with per-type constraints (`mustExist`, `min`/`max`) and a pluggable
  type registry
- Positional arguments with the same type pipeline, including a slurpy last
  argument
- Nested subcommands with per-level options and chained result objects
- Config files (YAML, JSON, pluggable formats) with command line > config >
  default precedence, an automatic `--config` option, and
  `--create-default-config` to write a starter config from the spec defaults
- Generated `--help` output: grouped options, annotations, examples,
  terminal-width wrapping, color on a tty. An automatic `--version` comes
  with it
- Shell completion for bash and zsh via `--create-completions`: commands,
  options, `valid` values and paths
- Errors go to STDERR followed by the failing level's help text, exit
  status 2. Spec mistakes croak at the developer instead

## Synopsis

```perl
use Getopt::Pad;

my $opt = GetOptions(
	options => {
		'owner|o' => {
			type     => 's',
			required => 1,
			help     => 'Target owner (user or organization)',
			group    => 'Target',
		},
		'private' => {
			type    => '!',
			default => 1,
			help    => 'Create the target repository as private',
			group   => 'Target',
		},
		'log-level' => {
			type    => 's',
			default => 'info',
			valid   => [qw(trace debug info warn error fatal)],
			help    => 'Logging level to use',
		},
	},
	args => [
		{ type => 'url', short => 'source-url', required => 1, help => 'The source address' },
	],
	description => 'Migrate one Git repository into Forgejo.',
);

say $opt->owner;       # readers are camelCase
say $opt->logLevel;    # 'log-level' -> logLevel
say $opt->sourceUrl;
```

Called with `--help`, this script prints:

```
# migrate [options] source-url
# Migrate one Git repository into Forgejo.

## Arguments
   <source-url>                [REQ] The source address [URL]

## Completion
   --create-completions <>     Print a completion script for this shell to
                               STDOUT and exit
                                   Valid   = [ bash, zsh ]

## Options
   --log-level <>              Logging level to use
                                   Valid   = [ trace, debug, info, warn, error, fatal ]
                                   Default = info

## Target
   --owner <>                  [REQ] Target owner (user or organization)
   --[no-]private              Create the target repository as private
                                   Default = 1
```

## Subcommands

Subcommands are plain nested hashrefs. Each level yields its own result
object:

```perl
my $opt = GetOptions(
	options  => { verbose => { type => '!' } },
	commands => {
		document => {
			commands => {
				create => {
					options => { format => { type => 's', valid => [qw(pdf docx)] } },
					args    => [{ short => 'title', required => 1 }],
				},
			},
		},
	},
);

# argv: --verbose document create --format pdf "My Doc"
$opt->command;                          # 'document'
$opt->subcommand->subcommand->format;   # 'pdf'
```

## Shell completion

`--create-completions bash` or `--create-completions zsh` prints a completion
script to STDOUT. Redirect it to wherever your shell picks completions up
from:

```sh
tool --create-completions bash > ~/.local/share/bash-completion/completions/tool
tool --create-completions zsh  > ~/.zsh/completions/_tool
```

The script is a thin shim that runs the program again on every tab, so it
never needs to be regenerated when the spec changes. It completes the
command names of the current level, the option spellings the help lists,
the values an option's `valid` list allows (a coderef is called on every
tab, so lists computed at run time stay current) and, for `file` and `dir`
options and args, the shell's own path completion.

## Examples

Runnable examples live in [`examples/`](examples/). Each parses your
arguments (its header comment lists invocations to try) and prints an
overview of the readers on the result object, indenting nested subcommand
results:

- [`01-basic.pl`](examples/01-basic.pl) - options, defaults, valid lists, positionals
- [`02-types.pl`](examples/02-types.pl) - every built-in option type
- [`03-commands.pl`](examples/03-commands.pl) - nested subcommands and chained results
- [`04-custom-type.pl`](examples/04-custom-type.pl) - a custom `even` type that only accepts even numbers
- [`05-custom-format.pl`](examples/05-custom-format.pl) - a custom TOML config format via TOML::Tiny

See the [Getopt::Pad documentation](https://metacpan.org/pod/Getopt::Pad)
(`perldoc Getopt::Pad` once installed) for the full spec reference,
including the contracts for custom option types and config formats.

## Installation

From CPAN:

```sh
cpanm Getopt::Pad
```

From a checkout:

```sh
perl Makefile.PL
make
make test
make install
```

Requires Perl >= 5.26, Object::Pad, Getopt::Long, Feature::Compat::Try and
JSON::PP. YAML::XS is recommended for YAML config files, Term::ReadKey for
detecting the terminal width (without it, or `COLUMNS`, help wraps at 100).

## License

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Copyright 2026 davenonymous
