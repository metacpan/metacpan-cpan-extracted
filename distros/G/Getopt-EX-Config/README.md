[![Actions Status](https://github.com/kaz-utashiro/Getopt-EX-Config/workflows/test/badge.svg)](https://github.com/kaz-utashiro/Getopt-EX-Config/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Getopt-EX-Config.svg)](https://metacpan.org/release/Getopt-EX-Config)
# NAME

Getopt::EX::Config - Getopt::EX module configuration interface

# SYNOPSIS

    example -Mfoo::config(foo=yabaa,bar=dabba) ...

    example -Mfoo::config(foo=yabba) --config bar=dabba ... -- ...

    example -Mfoo::config(foo=yabba) --bar=dabba ... -- ...

    example -Mfoo --foo=yabaa --bar=dabba -- ...

# VERSION

Version 0.9902

# DESCRIPTION

This module provides an interface to define configuration information
for `Getopt::EX` modules.  In the traditional way, in order to set
options for a module, it was necessary to define dedicated command
line options for them.  To do so, it is necessary to avoid name
conflicts with existing command options or with other modules used
together.

Using this module, it is possible to define configuration information
only for the module and to define module-specific command options.

You can create config object like this:

    use Getopt::EX::Config;
    my $config = Getopt::EX::Config->new(
        char  => 0,
        width => 0,
        code  => 1,
        name  => "Franky",
    );

This call returns hash object and each member can be accessed like
`$config->{width}`.

You can set these configuration values by calling `config()` function
with module declaration.

    example -Mfoo::config(width,code=0) ...

Parameter list is given by key-value pairs, and `1` is assumed when
value is not given.  Above code set `width` to `1` and `code` to
`0`.

Also module specific options can be taken care of by calling
`deal_with` method from module startup funciton `intialize` or
`finalize`.

    sub finalize {
        our($mod, $argv) = @_;
        $config->deal_with($argv);
    }

Then you can use `--config` module option like this:

    example -Mfoo --config width,code=0 -- ...

The module startup function is executed between the `initialize()`
and `finalize()` calls.  Therefore, if you want to give priority to
module-specific options over the startup function, you must call
`deal_with` in the `finalize()` function.

If you want to make module private option, say `--width` to set `$config->{width}` value, `deal_with` method takes `Getopt::Long`
style option specifications.

    sub finalize {
        our($mod, $argv) = @_;
        $config->deal_with(
            $argv,
            "width!" => \$config->{width},
            "code!"  => \$config->{code},
            "name=s" => \$config->{name},
        );
    }

Then you can use module private option like this:

    example -Mcharcode --width --no-code --name=Benjy -- ...

# METHODS

- **new**(_key-value list_)
- **new**(_hash reference_)

    Return configuration object.

    Call with key-value list like this:

        my $config = Getopt::EX::Config->new(
            char  => 0,
            width => 0,
            code  => 1,
            name  => "Franky",
        );

    Or call with hash reference.

        my %config = (
            char  => 0,
            width => 0,
            code  => 1,
            name  => "Franky",
        );
        my $config = Getopt::EX::Config->new(\%config);

    In this case, `\%config` and `$config` should be identical.

- **deal\_with**

    You can get argument reference in `initialize()` or `finalize()`
    function declared in `Getopt::EX` module.  Call `deal_with` method
    with that reference.

        sub finalize {
            our($mod, $argv) = @_;
            $config->deal_with($argv);
        }

    You can define module specific options by giving [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) style
    definition with that call.

        sub finalize {
            our($mod, $argv) = @_;
            my @optdef = (
                "width!" => \$config->{width},
                "code!"  => \$config->{code},
                "name=s" => \$config->{name},
            );
            $config->deal_with($argv, @optdef);
        }

# SEE ALSO

[Getopt::EX](https://metacpan.org/pod/Getopt%3A%3AEX)

[Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)

# AUTHOR

Kazumasa Utashiro

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright ©︎ 2025 Kazumasa Utashiro

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
