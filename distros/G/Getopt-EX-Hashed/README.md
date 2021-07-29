[![Actions Status](https://github.com/kaz-utashiro/Getopt-EX-Hashed/workflows/test/badge.svg)](https://github.com/kaz-utashiro/Getopt-EX-Hashed/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Getopt-EX-Hashed.svg)](https://metacpan.org/release/Getopt-EX-Hashed)
# NAME

Getopt::EX::Hashed - Hash store object automation

# SYNOPSIS

    use App::foo;
    App::foo->new->run();

    package App::foo;

    use Getopt::EX::Hashed;
    has start => ( spec => "=i s begin", default => 1 );
    has end   => ( spec => "=i e" );
    no  Getopt::EX::Hashed;

    sub run {
        my $app = shift;
        use Getopt::Long;
        $app->getopt or pod2usage();
        if ($app->{start}) {
            ...

# DESCRIPTION

**Getopt::EX::Hashed** is a module to automate a hash object to store
command line option values.  Major objective of this module is to
integrate initialization and specification into single place.  Module
name shares **Getopt::EX**, but it works independently from other
modules included in **Getopt::EX**, so far.

In the current implementation, using **Getopt::Long**, or compatible
module such as **Getopt::EX::Long** is assumed.  It is configurable,
but no other module is supported now.

# FUNCTION

## **has**

Declare option parameters in a form of:

    has option_name => ( param => value, ... );

If array reference is given, multiple names can be declared at once.

    has [ 'left', 'right' ] => ( param => value, ... );

If the name start with plus (`+`), given parameters are added to
current value.

    has '+left' => ( default => 1 );

Following parameters are available.

- **spec** => _string_

    Give option specification.  Option spec and alias names are separated
    by white space, and can show up in any order.

    Declaration

        has start => ( spec => "=i s begin" );

    will be compiled into string:

        start|s|begin:i

    which conform to `Getopt::Long` definition.  Of course, you can write
    as this:

        has start => ( spec => "s|begin=i" );

    If the name and aliases contain underscore (`_`), another alias name
    is defined with dash (`-`) in place of underscores.  So

        has a_to_z => ( spec => "=s" );

    will be compiled into:

        a_to_z|a-to-z:s

    If nothing special is necessary, give empty (or white space only)
    string as a value.  Otherwise, it is not considered as an option.

- **alias** => _string_

    Additional alias names can be specified by **alias** parameter too.
    There is no difference with ones in **spec** parameter.

- **default** => _value_

    Set default value.  If no default is given, the member is initialized
    as `undef`.

    If the value is code reference, hash object is passed by `$_`.

        has [ qw(left right both) ] => spec => '=i';
        has "+both" => default => sub {
            $_->{left} = $_->{right} = $_[1];
        } ;

    You can use this for `"<>"` too, and spec parameter is not
    required in this case.

        has ARGV => default => [];
        has "<>" => default => sub {
            push @{$_->{ARGV}}, $_[0];
        };

# METHOD

- **new**

    Class method to get initialized hash object.

- **configure**

    There should be some configurable variables, but not fixed yet.

- **getopt**

    Call `GetOptions` function defined in caller's context with
    appropriate parameters.

        $obj->getopt

    is just a shortcut for:

        GetOptions($obj, $obj->optspec)

- **optspec**

    Return option specification list which can be given to `GetOptions`
    function with the hash object.

- **use\_keys**

    Because hash keys are protected by `Hash::Util::lock_keys`, accessing
    non-existing member causes an error.  Use this function to declare new
    member key before use.

        $obj->use_keys( qw(foo bar) );

    If you want to access arbitrary keys, unlock the object.

        use Hash::Util 'unlock_keys';
        unlock_keys %{$obj};

# SEE ALSO

[Getopt::Long](https://metacpan.org/pod/Getopt::Long)

[Getopt::EX](https://metacpan.org/pod/Getopt::EX), [Getopt::EX::Long](https://metacpan.org/pod/Getopt::EX::Long)

# AUTHOR

Kazumasa Utashiro

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2021 Kazumasa Utashiro

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
