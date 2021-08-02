[![Actions Status](https://github.com/kaz-utashiro/Getopt-EX-Hashed/workflows/test/badge.svg)](https://github.com/kaz-utashiro/Getopt-EX-Hashed/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Getopt-EX-Hashed.svg)](https://metacpan.org/release/Getopt-EX-Hashed)
# NAME

Getopt::EX::Hashed - Hash store object automation

# VERSION

Version 0.9906

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
command line option values.  Major objective of this module is
integrating initialization and specification into single place.
Module name shares **Getopt::EX**, but it works independently from
other modules included in **Getopt::EX**, so far.

In the current implementation, using **Getopt::Long**, or compatible
module such as **Getopt::EX::Long** is assumed.  It is configurable,
but no other module is supported now.

# FUNCTION

## **has**

Declare option parameters in a form of:

    has option_name => ( param => value, ... );

If array reference is given, multiple names can be declared at once.

    has [ 'left', 'right' ] => ( spec => "=i" );

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

        start|s|begin=i

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

- **action** => _coderef_

    Parameter **action** takes code reference which called to process the
    option.  When called, hash object is passed through `$_`.

        has [ qw(left right both) ] => spec => '=i';
        has "+both" => action => sub {
            $_->{left} = $_->{right} = $_[1];
        };

    You can use this for `"<>"` too.  In that case, spec parameter
    does not matter and not required.

        has ARGV => default => [];
        has "<>" => action => sub {
            push @{$_->{ARGV}}, $_[0];
        };

    In fact, **default** parameter takes code reference too.  It is stored
    in the hash object and the code works almost same.  But the hash value
    can not be used for option storage.

    Because **action** function intercept the option assignment, it can be
    used to verify the parameter.

        has age =>
            spec => '=i',
            action => sub {
                my($name, $i) = @_;
                (0 <= $i and $i <= 150) or
                    die "$name: have to be in 0 to 150 range.\n";
                $_->{$name} = $i;
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

        GetOptions($obj->optspec)

- **optspec**

    Return option specification list which can be given to `GetOptions`
    function.  GetOptions has a capability of storing values in a hash, by
    giving the hash reference as a first argument, but it is not expected.

- **use\_keys**

    Because hash keys are protected by `Hash::Util::lock_keys`, accessing
    non-existing member causes an error.  Use this function to declare new
    member key before use.

        $obj->use_keys( qw(foo bar) );

    If you want to access arbitrary keys, unlock the object.

        use Hash::Util 'unlock_keys';
        unlock_keys %{$obj};

- **reset**

    Reset the class to original state.  Because the hash object keeps all
    information, this does not effect to the existing object.  It returns
    the object itself, so you can reset the class after creating a object
    like this:

        my $obj = Getopt::EX::Hashed->new->reset;

    This is almost equivalent to the next code:

        my $obj = Getopt::EX::Hashed->new;
        Getopt::EX::Hashed->reset;

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
