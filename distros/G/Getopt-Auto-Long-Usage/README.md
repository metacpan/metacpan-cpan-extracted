# NAME

`Getopt::Auto::Long::Usage` - generate usage strings from Getopt::Long specs

# VERSION

Version 0.03

# SYNOPSIS

This is a pure perl module that generates simple usage / help messages by parsing [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) argument specs (and optionally using provided descriptions).

    print getoptlong2usage( Getopt_Long => \@conf [, ...] )

# DESCRIPTION

`Getopt::Auto::Long::Usage` strives to be compatible with [Getopt::LongUsage](https://metacpan.org/pod/Getopt%3A%3ALongUsage). In particular, it does not require supplementing existing arglist specs with additional data (e.g. descriptions are optional). However, the goal is to provide maximum maintainability with the least amount of code, not to achieve complete [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) coverage. So, there are some differences:

- the generated usage clearly distinguishes boolean flags from arguments requiring an option, and prints type information for the latter. For negatable boolean options (`longopt|s!`), it will print the corresponding `--no-longopt` flag (but not `--no-s`).
- there are no dependencies; the main function can be copied directly into your source code, if necessary
- it does not attempt to parse `GetOptions()` abbreviated / case-insensitive options, and in fact recommends that you disable those when using `Getopt::Long` for maintainability and predictability. One shortopt + one (or several) longopts, explicitly specified, will avoid nasty surprises (plus, suppose you decide to rewrite the code in some other language...)

The following example should print the generated help message either to stdout, if requested (`--help`) or to stderr, if argument parsing fails.

    use Getopt::Auto::Long::Usage;
    use Getopt::Long;
    my @getoptargs = qw{ help
                         delim:s
                         eval|e!
                       };
    my %_O_; my @getoptconf = (\%_O_, @getoptargs);

    sub usage {
      my ($rc) = @_;
      my @dsc = ( delim => 'instead of newline' );
      print getoptlong2usage(
        Getopt_Long => \@getoptconf, # all others optional
        cli_use => "Arguments: [OPTION]...\nOptions:";
        footer => "No other arguments may be supplied"
        descriptions => \@dsc
      );
      exit $rc if defined( $rc );
    }

    Getopt::Long::Configure( qw(
      no_ignore_case no_auto_abbrev no_getopt_compat
      gnu_compat bundling
    ));
    unless( GetOptions( @getoptconf ) ) {
      local *STDOUT = *STDERR; usage 1;
    }
    usage 0 if( $_O_{ help } );

# EXPORT

- `getoptlong2usage`
- `opts2bash` (import explicitly)
- `bashgetopt` (import explicitly; experimental -- see code)

# FUNCTIONS

## getoptlong2usage

    $usage = getoptlong2usage( Getopt_Long => \@getoptconf [,
      descriptions => \@dsc,  # this & all others: optional
      cli_use => '',
      footer => '',
      colon => ': ',
      indent => undef,
      pfx => '' ] )

`@getoptconf` is an arrayref containing all the arguments you would supply to `GetOptions()`, including the initial hashref in which `GetOptions()` stores results (and which is ignored). It's easiest to define `@getoptconf` separately and reuse it for both calls. See ["DESCRIPTION"](#description) for an example.

All other arguments are optional and shown with their defaults. _colon_ separates flags from descriptions. _pfx_ is an arbitrary string (like `'* '`). _indent_ sets _pfx_ to a number of spaces (don't use both). _cli\_use_ goes at the top, _footer_ at the bottom, and both will have a newline appended if they don't end with one.

## opts2bash

    opts2bash( opts => {}, ARGV => [],
      assoc => 0,
      name => q(_O_),
      bash => q/bash/,
      underline => q/_/,
      uc => 0
    )

Outputs a string that can be eval'd in bash to set bash variables to the corresponding values in perl. Bash variables are either prefixed by _name_, or _name_ can be an associative array (_assoc_ = 1). Calls `system('bash' ...)` underneath to quote perl values (_bash_ can override the interpreter and can contain flags, e.g. '`bash44 -x`').

This function can export, in Bash format, parameters (including positional ones: _ARGV_) parsed by perl. In fact, `bashgetopt()` uses it just for that.

## bashgetopt

    bashgetopt( argspec => '',
      descriptions => '',
      cli_use => "Arguments: [OPTION]...\nOptions:\n",
      footer => '',
      assoc => 0
    )

Generates a bash stub script that imports `Getopt::Long` and this module. The stub script contains a bash function `__perl_parse_args` (not invoked by default) that call perl to parse its arguments according to the provided argspec. You can use the generated output as scaffolding, or `eval` it in another bash script. Sample usage:

    perl -wE >x.sh '
      use Getopt::Auto::Long::Usage qw( bashgetopt );
      print bashgetopt( argspec => q(name|n=s help|h) )'
    # edit x.sh, uncomment lines
    chmod +x x.sh; x.sh --help
    x.sh --name 'My name' arg1 arg2

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Getopt::Auto::Long::Usage

# SEE ALSO

- `Getopt::Long::Descriptive`
- [bashaaparse](https://gitlab.com/kstr0k/bashaaparse/), my take on automatic arg parsing / usage generation for Bash scripts

# AUTHOR

Alin Mr., see source code at https://gitlab.com/kstr0k/perl-getopt-auto-long-usage

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Alin Mr.

This is free software, licensed under:

    The MIT (X11) License
