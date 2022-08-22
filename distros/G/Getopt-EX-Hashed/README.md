[![Actions Status](https://github.com/kaz-utashiro/Getopt-EX-Hashed/workflows/test/badge.svg)](https://github.com/kaz-utashiro/Getopt-EX-Hashed/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Getopt-EX-Hashed.svg)](https://metacpan.org/release/Getopt-EX-Hashed)
# NAME

Getopt::EX::Hashed - Hash store object automation for Getopt::Long

# VERSION

Version 1.05

# SYNOPSIS

    use App::foo;
    App::foo->new->run();

    package App::foo;

    use Getopt::EX::Hashed; {
        has start    => ' =i  s begin ' , default => 1;
        has end      => ' =i  e       ' ;
        has file     => ' =s@ f       ' , is => 'rw', any => qr/^(?!\.)/;
        has score    => ' =i          ' , min => 0, max => 100;
        has answer   => ' =i          ' , must => sub { $_[1] == 42 };
        has mouse    => ' =s          ' , any => [ 'Frankie', 'Benjy' ];
        has question => ' =s          ' , any => qr/^(life|universe|everything)$/i;
    } no Getopt::EX::Hashed;

    sub run {
        my $app = shift;
        use Getopt::Long;
        $app->getopt or pod2usage();
        if ($app->{start}) {
            ...

# DESCRIPTION

**Getopt::EX::Hashed** is a module to automate a hash object to store
command line option values for **Getopt::Long** and compatible modules
including **Getopt::EX::Long**.

Major objective of this module is integrating initialization and
specification into single place.

Module name shares **Getopt::EX**, but it works independently from
other modules in **Getopt::EX**, so far.

Accessor methods are automatically generated when appropriate parameter
is given.

# FUNCTION

- **has**

    Declare option parameters in a form of:

        has option_name => ( param => value, ... );

    If array reference is given, multiple names can be declared at once.

        has [ 'left', 'right' ] => ( spec => "=i" );

    If the name start with plus (`+`), given parameter updates values.

        has '+left' => ( default => 1 );

    As for `spec` parameter, label can be omitted if it is the first
    parameter.

        has left => "=i", default => 1;

    If the number of parameter is not even, default label is assumed to be
    exist at the head: `action` if the first parameter is code reference,
    `spec` otherwise.

    Following parameters are available.

    - \[ **spec** => \] _string_

        Give option specification.  `spec =>` label can be omitted if and
        only if it is the first parameter.

        In _string_, option spec and alias names are separated by white
        space, and can show up in any order.  Declaration

            has start => "=i s begin";

        will be compiled into string:

            start|s|begin=i

        which conform to `Getopt::Long` definition.  Of course, you can write
        as this:

            has start => "s|begin=i";

        If the name and aliases contain underscore (`_`), another alias name
        is defined with dash (`-`) in place of underscores.  So

            has a_to_z => "=s";

        will be compiled into:

            a_to_z|a-to-z:s

        If nothing special is necessary, give empty (or white space only)
        string as a value.  Otherwise, it is not considered as an option.

    - **alias** => _string_

        Additional alias names can be specified by **alias** parameter too.
        There is no difference with ones in `spec` parameter.

            has start => "=i", alias => "s begin";

    - **is** => `ro` | `rw`

        To produce accessor method, `is` parameter is necessary.  Set the
        value `ro` for read-only, `rw` for read-write.

        Read-write accessor has a lvalue attribute, so it can be assigned.
        You can use like this:

            $app->foo //= 1;

        which is simpler than:

            $app->foo(1) unless defined $app->foo;

        If you want to make accessor for all following members, use
        `configure` to set `DEFAULT` parameter.

            Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );

        If you don't like assignable accessor, configure `ACCESSOR_LVALUE`
        parameter to 0.  Because accessor is generated at the time of `new`,
        this value is effective for all members.

    - **default** => _value_ | _coderef_

        Set default value.  If no default is given, the member is initialized
        as `undef`.

        If the value is a reference for ARRAY or HASH, new reference with same
        member is assigned.  This means that member data is shared across
        multiple `new` calls.  Please be careful if you call `new` multiple
        times and alter the member data.

        If a code reference is given, it is called at the time of **new** to
        get default value.  This is effective when you want to evaluate the
        value at the time of execution, rather than declaration.  Use
        **action** parameter to define a default action.

    - \[ **action** => \] _coderef_

        Parameter `action` takes code reference which is called to process
        the option.  `action =>` label can be omitted if and only if it
        is the first parameter.

        When called, hash object is passed as `$_`.

            has [ qw(left right both) ] => '=i';
            has "+both" => sub {
                $_->{left} = $_->{right} = $_[1];
            };

        You can use this for `"<>"` to catch everything.  In that case,
        spec parameter does not matter and not required.

            has ARGV => default => [];
            has "<>" => sub {
                push @{$_->{ARGV}}, $_[0];
            };

    Following parameters are all for data validation.  First `must` is a
    generic validator and can implement anything.  Others are shortcut
    for common rules.

    - **must** => _coderef_ | \[ _coderef_ ... \]

        Parameter `must` takes a code reference to validate option values.
        It takes same arguments as `action` and returns boolean.  With next
        example, option **--answer** takes only 42 as a valid value.

            has answer =>
                spec => '=i',
                must => sub { $_[1] == 42 };

        If multiple code reference is given, all code have to return true.

            has answer =>
                spec => '=i',
                must =>[ sub { $_[1] >= 42 }, sub { $_[1] <= 42 } ];

    - **min** => _number_
    - **max** => _number_

        Set the minimum and maximum limit for the argument.

    - **any** => _arrayref_ | qr/_regex_/

        Set the valid string parameter list.  Each item is a string or a regex
        reference.  The argument is valid when it is same as, or match to any
        item of the given list.  If the value is not an arrayref, it is taken
        as a single item list (regexpref usually).

        Following declarations are almost equivalent, except second one is
        case insensitive.

            has question => '=s',
                any => [ 'life', 'universe', 'everything' ];

            has question => '=s',
                any => qr/^(life|universe|everything)$/i;

        If you are using optional argument, don't forget to include default
        value in the list.  Otherwise it causes validation error.

            has question => ':s',
                any => [ 'life', 'universe', 'everything', '' ];

# METHOD

- **new**

    Class method to get initialized hash object.

- **optspec**

    Return option specification list which can be given to `GetOptions`
    function.

        GetOptions($obj->optspec)

    `GetOptions` has a capability of storing values in a hash, by giving
    the hash reference as a first argument, but it is not necessary.

- **getopt** \[ _arrayref_ \]

    Call appropriate function defined in caller's context to process
    options.

        $obj->getopt

        $obj->getopt(\@argv);

    are shortcut for:

        GetOptions($obj->optspec)

        GetOptionsFromArray(\@argv, $obj->optspec)

- **use\_keys** _keys_

    Because hash keys are protected by `Hash::Util::lock_keys`, accessing
    non-existent member causes an error.  Use this function to declare new
    member key before use.

        $obj->use_keys( qw(foo bar) );

    If you want to access arbitrary keys, unlock the object.

        use Hash::Util 'unlock_keys';
        unlock_keys %{$obj};

    You can change this behavior by `configure` with `LOCK_KEYS`
    parameter.

- **configure** **label** => _value_, ...

    Use class method `Getopt::EX::Hashed->configure()` before
    creating an object; this information is stored in the area unique for
    calling package.  After calling `new()`, package unique configuration
    is copied in the object, and it is used for further operation.  Use
    `$obj->configure()` to update object unique configuration.

    There are following configuration parameters.

    - **LOCK\_KEYS** (default: 1)

        Lock hash keys.  This avoids accidental access to non-existent hash
        entry.

    - **REPLACE\_UNDERSCORE** (default: 1)

        Produce alias with underscores replaced by dash.

    - **REMOVE\_UNDERSCORE** (default: 0)

        Produce alias with underscores removed.

    - **GETOPT** (default: 'GetOptions')
    - **GETOPT\_FROM\_ARRAY** (default: 'GetOptionsFromArray')

        Set function name called from `getopt` method.

    - **ACCESSOR\_PREFIX** (default: '')

        When specified, it is prepended to the member name to make accessor
        method.  If `ACCESSOR_PREFIX` is defined as `opt_`, accessor for
        member `file` will be `opt_file`.

    - **ACCESSOR\_LVALUE** (default: 1)

        If true, read-write accessors have lvalue attribute.  Set zero if you
        don't like that behavior.

    - **DEFAULT**

        Set default parameters.  At the call for `has`, DEFAULT parameters
        are inserted before argument parameters.  So if both include same
        parameter, later one in argument list has precedence.  Incremental
        call with `+` is not affected.

        Typical use of DEFAULT is `is` to prepare accessor method for all
        following hash entries.  Declare `DEFAULT => []` to reset.

            Getopt::EX::Hashed->configure(DEFAULT => [ is => 'ro' ]);

- **reset**

    Reset the class to the original state.

# SEE ALSO

[Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)

[Getopt::EX](https://metacpan.org/pod/Getopt%3A%3AEX), [Getopt::EX::Long](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ALong)

# AUTHOR

Kazumasa Utashiro

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2021-2022 Kazumasa Utashiro

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
