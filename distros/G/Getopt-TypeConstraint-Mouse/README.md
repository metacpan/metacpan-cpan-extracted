# NAME

Getopt::TypeConstraint::Mouse - A command line options processor uses Mouse's type constraints

# SYNOPSIS

in your script

    #!perl
    use Getopt::TypeConstraint::Mouse;

    my $options = Getopt::TypeConstraint::Mouse->get_options(
        foo => +{
            isa           => 'Str',
            required      => 1,
            documentation => 'Blah Blah Blah ...',
        },
        bar => +{
            isa           => 'Str',
            default       => 'Bar',
            documentation => 'Blah Blah Blah ...',
        },
    );

    print $options->{foo}, "\n";
    print $options->{bar}, "\n";

use it

    $ perl ./script.pl --for=Foo --bar=Bar
    Foo
    Bar

    $ perl ./script.pl
    Mandatory parameter 'foo' missing in call to (eval)

    usage: script.pl [-?] [long options...]
    	-? --usage --help  Prints this usage information.
    	--foo              Blah Blah Blah ...
    	--bar              Blah Blah Blah ..

# QUESTIONS

## What types are supported?

See [MouseX::Getopt#Supported-Type-TypeConstraints](https://metacpan.org/pod/MouseX::Getopt#Supported-Type-TypeConstraints) for details.

## What options are supported?

See [MouseX::Getopt#METHODS](https://metacpan.org/pod/MouseX::Getopt#METHODS) for details.

# SEE ALSO

- [MouseX::Getopt](https://metacpan.org/pod/MouseX::Getopt)
- [Smart::Options](https://metacpan.org/pod/Smart::Options)
- [Docopt](https://metacpan.org/pod/Docopt)
- [Getopt::Long::Descriptive](https://metacpan.org/pod/Getopt::Long::Descriptive)
- [Getopt::Compact::WithCmd](https://metacpan.org/pod/Getopt::Compact::WithCmd)

# LICENSE

Copyright (C) Hiroki Honda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroki Honda <cside.story@gmail.com>
