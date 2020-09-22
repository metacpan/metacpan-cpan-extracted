# NAME

Hash::Digger - Access nested hash structures without vivification

# VERSION

Version 0.0.3

# SYNOPSIS

Allows accessing hash structures without triggering autovivification.

    my %hash;

    $hash{'foo'}{'bar'} = 'baz';

    diggable \%hash, 'foo', 'bar';
    # Truthy

    diggable \%hash, 'xxx', 'yyy';
    # Falsey

    dig \%hash, 'foo', 'bar';
    # 'baz'

    dig \%hash, 'foo', 'bar', 'xxx';
    # undef

    exhume 'some default', \%hash, 'foo', 'bar';
    # 'baz'

    exhume 'some default', \%hash, 'foo', 'xxx';
    # 'some default'

    # Hash structure has not changed:
    use Data::Dumper;
    Dumper \%hash;
    # $VAR1 = {
    #           'foo' => {
    #                      'bar' => 'baz'
    #                    }
    #         };

# EXPORT

dig, diggable, exhume

# SUBROUTINES/METHODS

## diggable

Check if given path is diggable on the hash (\`exists\` equivalent)

## dig

Dig the hash and return the value. If the path is not valid, it returns undef.

## exhume

Dig the hash and return the value. If the path is not valid, it returns a default value.

# REPOSITORY

[https://github.com/juliodcs/Hash-Digger](https://github.com/juliodcs/Hash-Digger)

# AUTHOR

Julio de Castro, `<julio.dcs at gmail.com>`

# BUGS

Please report any bugs or feature requests to `bug-hash-digger at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Digger](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Digger).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::Digger

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-Digger](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-Digger)

- CPAN Ratings

    [https://cpanratings.perl.org/d/Hash-Digger](https://cpanratings.perl.org/d/Hash-Digger)

- Search CPAN

    [https://metacpan.org/release/Hash-Digger](https://metacpan.org/release/Hash-Digger)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Julio de Castro.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
