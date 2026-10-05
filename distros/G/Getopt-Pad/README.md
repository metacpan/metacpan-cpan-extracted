# Getopt::Pad

Declarative command line parsing for Perl. You describe every option and
positional argument once, with its type, default, allowed values and help
text. `GetOptions` parses the command line, checks every value, and
returns an object with one method per option and argument
(`--log-level debug` becomes `$opt->logLevel`).

## Features

- **Typed values**: `flag`, `bool` (`--x` / `--no-x`), `counter` (`-vvv`),
  `string`, `int` and `float` (with `min` / `max`), `file` and `dir` (with
  `mustExist` or `createPathIfMissing`) and `url`. Custom types can be
  added.
- **Checks**: fixed lists of allowed values, lists computed at run time,
  and arbitrary checks, for command line, config file and default values
  alike.
- **Value shapes**: repeatable options (`multiple`, optionally
  comma-separated with `csv`), `key=value` mappings (`hash`) and lists of
  records (`objectlist`).
- **Positional arguments** with the value-taking types, including a last
  argument that takes all remaining words.
- **Subcommands**, nested to any depth, each with its own options,
  arguments and help. Options marked `inherit` work on every level.
- **Config files** in YAML or JSON (other formats can be added), for every
  command level, with the precedence command line > config file > default.
  `--create-default-config` writes a starter file.
- **Generated help**: grouped options, required markers, allowed values,
  defaults, examples, wrapped to the terminal and colored on a terminal.
  `--version` comes with it.
- **Shell completion** for bash and zsh via `--create-completions`:
  commands, options, allowed values and paths.
- **Clear errors**: a wrong command line prints the problem and the help,
  and exits with status 2. A mistake in the spec dies immediately and
  points at your `GetOptions` call.

## Synopsis

```perl
use v5.26;
use Getopt::Pad;

my $opt = GetOptions(
    description => 'Copy a directory to a backup location.',
    options     => {
        'target|t' => {
            type     => 'dir',
            required => 1,
            help     => 'Directory the backup is written to',
        },
        'keep' => {
            type    => 'int',
            default => 7,
            min     => 1,
            help    => 'Number of backups to keep',
        },
        'exclude|x' => {
            type     => 'string',
            multiple => 1,
            help     => 'Pattern of files to skip; repeat for more patterns',
        },
        'compress' => {
            type    => 'bool',
            default => 1,
            help    => 'Compress the backup; --no-compress turns it off',
        },
        'verbose|v' => {
            type => 'counter',
            help => 'Print more details; repeat for even more (-vv)',
        },
    },
    args => [
        { short => 'source', type => 'dir', required => 1, help => 'Directory to back up' },
    ],
);

# backup -t /mnt/backup -x '*.tmp' -x '*.log' -vv --no-compress photos
say $opt->source;                    # photos
say $opt->keep;                      # 7 (the default)
say join ', ', $opt->exclude->@*;    # *.tmp, *.log
say $opt->compress ? 'yes' : 'no';   # no
say $opt->verbose;                   # 2
```

Called with `--help`, this program prints:

```
# backup [options] source
# Copy a directory to a backup location.

## Arguments
   <source>                    [REQ] Directory to back up [Path]

## Completion
   --create-completions <>     Print a completion script for this shell to
                               STDOUT and exit
                                   Valid   = [ bash, zsh ]

## Options
   --[no-]compress             Compress the backup; --no-compress turns it
                               off
                                   Default = 1
   --exclude <>                Pattern of files to skip; repeat for more
                               patterns
   --keep <>                   Number of backups to keep
                                   Default = 7
   --target <>                 [REQ] Directory the backup is written to
                               [Path]
   --verbose                   Print more details; repeat for even more
                               (-vv)
```

## Documentation

Once installed, read the documentation with `perldoc`:

- `perldoc Getopt::Pad::Tutorial` - a step-by-step introduction
- `perldoc Getopt::Pad::Cookbook` - recipes for common tasks
- `perldoc Getopt::Pad` - the complete reference: every spec key, type,
  config file rule and error message
- `perldoc Getopt::Pad::Result` - the object `GetOptions` returns
- `perldoc Getopt::Pad::Type` - writing your own option types
- `perldoc Getopt::Pad::Config::Format` - adding config file formats

The same documentation is on [MetaCPAN](https://metacpan.org/pod/Getopt::Pad).

## Examples

Runnable examples live in [`examples/`](examples/). Each one prints the
values of its result object, so you can try different command lines; its
header comment lists command lines to try:

- [`01-basic.pl`](examples/01-basic.pl) - options, groups, defaults, a `valid` list and a required argument
- [`02-types.pl`](examples/02-types.pl) - one option per built-in type
- [`03-commands.pl`](examples/03-commands.pl) - nested commands, an inherited option and a JSON config file with command sections
- [`04-custom-type.pl`](examples/04-custom-type.pl) - a custom type that accepts only even numbers
- [`05-custom-format.pl`](examples/05-custom-format.pl) - a custom TOML config format via TOML::Tiny
- [`06-value-shapes.pl`](examples/06-value-shapes.pl) - `multiple`, `csv`, `hash` and `objectlist` options
- [`07-config.pl`](examples/07-config.pl) - config files: the autoload chain, `defaultPath` and `--create-default-config`
- [`08-checks.pl`](examples/08-checks.pl) - `valid` lists and coderefs, `lazyValid`, bounds, `mustExist`, `createPathIfMissing`, `typehint` and `hidden`

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

Requires Perl 5.26 or later, Object::Pad 0.818 or later, Getopt::Long
2.50 or later, Feature::Compat::Try and JSON::PP.

Optional: YAML::XS for YAML config files, and Term::ReadKey for wrapping
the help output to the width of the terminal. The help is wrapped to the
width in `COLUMNS` if it is set, else to the terminal width (with
Term::ReadKey), else to 100 columns.

## License

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Copyright 2026 davenonymous
