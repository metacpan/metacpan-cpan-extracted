[![Actions Status](https://github.com/tecolicom/getoptlong/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/tecolicom/getoptlong/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/Getopt-Long-Bash.svg)](https://metacpan.org/release/Getopt-Long-Bash)
# NAME

getoptlong - Option parsing that does what you mean, for Bash

# SYNOPSIS

**Option definition:**

    declare -A OPTS=(
        [ &USAGE ]="command [options] file..."
        [ flag     | f                   # Flag     ]=
        [ counter  | c +                 # Counter  ]=0
        [ required | r :                 # Required ]=/dev/stdout
        [ optional | o ?                 # Optional ]=
        [ array    | A @                 # Array    ]=
        [ hash     | H %                 # Hash     ]=
        [ integer  | i :=i               # Integer  ]=1
        [ pattern  | p :=(^(fast|slow)$) # Regex    ]=fast
    )

**One-liner:**

    . getoptlong.sh OPTS "$@"

**Multi-step:**

    . getoptlong.sh -
    getoptlong init OPTS
    getoptlong parse "$@" && eval "$(getoptlong set)"

**Or:**

    eval "$(getoptlong OPTS)"

# VERSION

0.7.2

# DESCRIPTION

**getoptlong.sh** is a Bash library providing Perl's [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)-style
option parsing.

Options are defined in a Bash associative array: the key specifies the
option name, aliases, type, and other attributes; the value sets the
default. The library parses command-line arguments, sets variables, and
leaves non-option arguments in `$@`.

Two usage modes are available: **one-liner** for simple scripts (source
with array name and arguments), and **multi-step** for advanced control
(separate init, parse, and set calls).

Supports short (`-v`) and long (`--verbose`) options with bundling
(`-vvv`). **Option types**: _flag_, _required argument_, _optional
argument_, _array_, _hash_. **Modifiers**: _callback_, _pass-through_.
**Validation**: _integer_, _float_, _regex_. **Help message** generation.
**Multiple invocations** for subcommand support.

For a gentle introduction, see [Getopt::Long::Bash::Tutorial](https://metacpan.org/pod/Getopt%3A%3ALong%3A%3ABash%3A%3ATutorial).

# INSTALLATION

    cpanm -n Getopt::Long::Bash

# USAGE

## One-liner

Source with array name and arguments to parse in one step:

    . getoptlong.sh OPTS "$@"

Configuration parameters must be included in the options array
(e.g., `[&PREFIX]=OPT_`). Callback registration is not available
in this mode; use `!` modifier for automatic callback instead.

## Multi-step

Source the library first, then call init, parse, and set separately:

    . getoptlong.sh -
    getoptlong init OPTS
    getoptlong parse "$@" && eval "$(getoptlong set)"

This mode allows callback registration between init and parse.

**Note:** When sourcing without arguments (`. getoptlong.sh`),
the current shell's positional parameters are passed to the library.
If the first argument happens to match an existing associative array
name, it may cause unexpected behavior. Use `. getoptlong.sh -`
to safely source without side effects.

# OPTION DEFINITION

Options are defined as elements of an associative array. Each key
specifies the option's name, type, and modifiers, while the value
provides the default. Whitespace is allowed anywhere in the definition
for readability. Configuration parameters can also be included
with `&` prefix (e.g., `[&PREFIX]=OPT_`); see ["CONFIGURATION"](#configuration).
The key format is:

    [NAME[|ALIAS...][TYPE[MOD]][DEST][=VALIDATE] # DESC]=DEFAULT

## COMPONENTS

- **NAME**

    Long option name (`--name`). Hyphens become underscores in variables
    (`--dry-run` → `$dry_run`).

- **ALIAS**

    Additional names separated by `|` (e.g., `verbose|v|V`).

- **TYPE**

    Argument type specifier:

        (none) or +  Flag (counter)
        :            Required argument
        ?            Optional argument
        @            Array (multiple values)
        %            Hash (key=value pairs)

- **MOD (MODIFIER)**

    Special behavior flags (can be combined):

        !   Callback - calls function when option is parsed
        >   Pass-through - collects option and value into array

- **DEST**

    Custom variable name (e.g., `[opt|o:MYVAR]` stores in `$MYVAR`).

- **VALIDATE**

    Value validation: `=i` (integer), `=f` (float), `=<regex>`.
    See ["VALIDATION"](#validation).

- **DESC (DESCRIPTION)**

    Help message text (everything after `#`).

# OPTION TYPES

Each option type determines how arguments are handled and stored.

## COUNTER FLAG (`+` or none)

A flag takes no argument. First use sets to `1`, subsequent uses
increment (useful for verbosity levels). Use `--no-<name>` to reset to
empty string. Bundling supported: `-vvv` equals `-v -v -v`.

    [verbose|v]=        # $verbose: 1 when specified
    [debug|d+]=0        # $debug: increments (-d -d -d or -ddd)

Numeric initial value (like `0`) enables counter display in help.

There is no pure boolean type; all flags are counters. Use empty
string test for boolean evaluation: `[[ $verbose ]]` is true when
non-empty, false when empty.

## REQUIRED ARGUMENT (`:`)

The option requires an argument; error if missing. Use `--no-<name>` to
reset to empty string (useful for disabling defaults).

    [output|o:]=        # --output=file, --output file, -ofile, -o file

Short form `-o=value` is **not** supported (use `-ovalue` or `-o value`).

## OPTIONAL ARGUMENT (`?`)

The argument is optional. The variable has three possible states: a value
(`--config=file`), empty string (`--config` without value), or unset
(option not specified). Use `[[ -v config ]]` to check if the option
was specified.

    [config|c?]=        # --config=file or --config (sets to "")

`--config=value` sets to `value`, `--config` without value sets to
empty string. Short form `-c` sets to empty string; `-cvalue` form
is **not** supported.

## ARRAY (`@`)

Collects multiple values into an array. Multiple specifications accumulate.
A single option can contain delimited values (default: space, tab, comma;
see [DELIM](#configuration)). Access with `"${include[@]}"`.

    [include|I@]=       # --include a --include b or --include a,b

To reset existing values: use `--no-include` on the command line
(e.g., `--no-include --include /new/path`), or use `callback --before`
to automatically reset before each new value.

## HASH (`%`)

Collects `key=value` pairs into an associative array. Key without value
is treated as `key=1`. Multiple pairs can be specified: `--define A=1,B=2`
(see [DELIM](#configuration)). Access with `${define[KEY]}`, keys with
`${!define[@]}`.

    [define|D%]=        # --define KEY=VAL or --define KEY (KEY=1)

To reset existing values: use `--no-define` on the command line
(e.g., `--no-define --define KEY=val`), or use `callback --before`
to automatically reset before each new value.

# CALLBACKS

Callback functions are called when an option is parsed. The value is
stored in the variable as usual, and the callback is invoked for
additional processing such as validation or side effects. Callbacks
work the same way with pass-through options.

Calls a function when the option is parsed. Default function name is the
option name with hyphens converted to underscores; use `getoptlong callback`
to specify a custom function. Can combine with any type (`+!`, `:!`,
`?!`, `@!`, `%!`).

    [action|a!]=        # Calls action() when specified
    [file|f:!]=         # Calls file() with argument

## REGISTRATION

Register callbacks with `getoptlong callback`. If function name is
omitted or `-`, uses option name (hyphens to underscores). Additional
`args` are passed to the callback function after the option name and value.

    getoptlong callback <option> [function] [args...]
    getoptlong callback --before <option> [function] [args...]

## CALLBACK TIMING

Normal callbacks are called **after** value is set, receiving the option
name and value. Pre-processing callbacks (`--before`/`-b`) are called
**before** value is set, without the value argument.

    callback_func "option_name" "value" [args...]   # normal
    callback_func "option_name" [args...]           # --before

## ERROR HANDLING

Callbacks must handle their own errors. `EXIT_ON_ERROR` only applies
to parsing errors, not callback failures. Use explicit `exit` if needed.

    validate_file() {
        [[ -r "$2" ]] || { echo "Cannot read: $2" >&2; exit 1; }
    }
    getoptlong callback input-file validate_file

# PASS-THROUGH (> Modifier)

Collects options and values into an array instead of storing in a
variable. Useful for passing options to other commands. The actual
option form used (`--pass`, `-p`, `--no-pass`) is collected, and
for options with values, both option and value are added. Multiple
options can collect to the same array. If no array name is specified
after `>`, uses the option name. Can combine with callback:
`[opt|o:!>array]`.

    [pass|p:>collected]=    # Option and value added to collected array

After `--pass foo`: `collected=("--pass" "foo")`

# DESTINATION VARIABLE

By default, values are stored in variables named after the option.
A custom destination can be specified by adding the variable name after
TYPE/MODIFIER and before VALIDATE: `[NAME|ALIAS:!DEST=(REGEX)]`.
`PREFIX` setting applies to custom names too (see ["getoptlong init"](#getoptlong-init)).

    [count|c:COUNT]=1       # Store in $COUNT instead of $count
    [debug|d+DBG]=0         # Store in $DBG

# VALIDATION

Option values can be validated using type specifiers or regex patterns:
`=i` for integers, `=f` for floats, `=(` ... `)` for regex.

    [count:=i]=1            # Integer (positive/negative)
    [ratio:=f]=0.5          # Float (e.g., 123.45)
    [mode:=(^(a|b|c)$)]=a   # Regex: exactly a, b, or c

**Note:** For regex, the pattern extends to the last `)` in the
definition, including any `)` in the description. Avoid using `)`
in comments when using regex validation.

Validation occurs before the value is stored or callbacks are invoked.
For array options, each element is validated; for hash options, each
`key=value` pair is matched as a whole. Error on validation failure
(see [EXIT\_ON\_ERROR](#configuration)).

# HELP MESSAGE

By default, `--help` and `-h` options are automatically available.
They display a help message generated from option definitions and exit.
No configuration is required.

To customize or disable, use one of these methods (in order of precedence):

    [&HELP]="usage|u#Show usage"            # 1. &HELP key in OPTS
    getoptlong init OPTS HELP="manual|m"    # 2. HELP parameter in init
    [help|h # Custom help text]=            # 3. Explicit option definition
    getoptlong init OPTS HELP=""            # Disable help option

## SYNOPSIS (USAGE)

Set the usage line displayed at the top of help output:

    [&USAGE]="Usage: cmd [options] <file>"  # In OPTS array
    getoptlong init OPTS USAGE="..."        # Or via init parameter

## OPTION DESCRIPTIONS

Text after `#` in the option definition becomes the help description.
If omitted, a description is auto-generated. Default values are shown
as `(default: value)`.

    [output|o: # Output file path]=/dev/stdout

# COMMANDS

The `getoptlong` function provides the following subcommands.

## getoptlong init

Initialize with option definitions. Must be called before `parse`.
See ["CONFIGURATION"](#configuration) for available parameters.

    getoptlong init <array_name> [CONFIG...]

## getoptlong parse

Parse arguments. Returns 0 on success, non-zero on error. Always
quote `"$@"`. By default, script exits on error.

    getoptlong parse "$@"

To handle errors manually, disable `EXIT_ON_ERROR`
(see ["CONFIGURATION"](#configuration)) and check return value:

    getoptlong configure EXIT_ON_ERROR=
    if ! getoptlong parse "$@"; then
        echo "Parse error" >&2
        exit 1
    fi

## getoptlong set

    eval "$(getoptlong set)"

Outputs shell commands to set variables and update positional parameters.
Variables are actually set during `parse`; this updates `$@`.

## getoptlong callback

Register callback function for option. Use `-b`/`--before` to call
before value is set. If `func` is omitted, uses option name (hyphens
to underscores). Additional `args` are passed to the callback.

    getoptlong callback [-b|--before] <opt> [func] [args...]

## getoptlong configure

Change configuration at runtime. Safe to change: `EXIT_ON_ERROR`,
`SILENT`, `DEBUG`, `DELIM`. Changing `PREFIX` after init may cause issues.

    getoptlong configure KEY=VALUE ...

## getoptlong dump

Debug output to stderr showing option names, variables, and values.
Use `-a`/`--all` to show all internal state.

    getoptlong dump [-a|--all]

## getoptlong help

Display help message. Optional `SYNOPSIS` overrides `&USAGE`/`USAGE`.

    getoptlong help [SYNOPSIS]

# CONFIGURATION

Configuration parameters can be specified either as arguments to
`getoptlong init` or as keys in the options array with `&` prefix
(e.g., `[&PREFIX]=OPT_`). Keys in the options array take precedence.

- **PERMUTE**=_array_

    Array name to store non-option arguments. Default: `GOL_ARGV`.
    After parsing, non-option arguments are collected here instead of
    remaining in `$@`. Set to empty string to disable permutation;
    non-option arguments must then come after all options.

- **PREFIX**=_string_

    Prefix added to all variable names. Default: none.
    For example, with `PREFIX=OPT_`, option `--verbose` sets `$OPT_verbose`.

- **HELP**=_spec_

    Help option specification. Default: `help|h#show help`.
    Set to empty string to disable automatic help option.

- **USAGE**=_string_

    Synopsis line shown in help message.
    Default: `scriptname [ options ] args`.

        [&USAGE]="command [options] file..."

- **EXIT\_ON\_ERROR**

    Exit immediately on parse error. Default: enabled.
    Set to empty string to disable and handle errors manually by checking
    return value.

- **SILENT**

    Suppress error messages. Default: disabled.
    Set to non-empty value to enable.

- **DEBUG**

    Enable debug output. Default: disabled.
    Set to non-empty value to enable.

- **DELIM**=_string_

    Delimiter characters for array/hash values. Default: space, tab, comma.
    For example, `DELIM=,:` would split on comma and colon.

- **REQUIRE**=_version_

    Minimum required version. Script exits with error if current
    version is older than specified.

        [&REQUIRE]="0.2"

# MULTIPLE INVOCATIONS

`getoptlong init` and `parse` can be called multiple times for
subcommand support:

    # Parse global options
    getoptlong init GlobalOPTS PERMUTE=REST
    getoptlong parse "$@" && eval "$(getoptlong set)"

    # Parse subcommand options
    case "${REST[0]}" in
        commit)
            getoptlong init CommitOPTS
            getoptlong parse "${REST[@]:1}" && eval "$(getoptlong set)"
            ;;
    esac

# EXAMPLES

See `ex/` directory for sample scripts:

- `repeat.sh` - basic option types
- `prefix.sh` - PREFIX setting
- `dest.sh` - custom destination variables
- `subcmd.sh` - subcommand handling
- `cmap` - complex real-world example

# SEE ALSO

- [Getopt::Long::Bash::Tutorial](https://metacpan.org/pod/Getopt%3A%3ALong%3A%3ABash%3A%3ATutorial) - getting started guide
- [Getopt::Long::Bash](https://metacpan.org/pod/Getopt%3A%3ALong%3A%3ABash) - module information
- [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) - Perl module inspiration
- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong) - repository
- [https://qiita.com/kaz-utashiro/items/75a7df9e1a1e92797376](https://qiita.com/kaz-utashiro/items/75a7df9e1a1e92797376) - introduction article (Japanese)

# AUTHOR

Kazumasa Utashiro

# COPYRIGHT

Copyright 2025-2026 Kazumasa Utashiro

# LICENSE

MIT License
