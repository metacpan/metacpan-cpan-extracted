[![Actions Status](https://github.com/kaz-utashiro/Getopt-EX-Hashed/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/kaz-utashiro/Getopt-EX-Hashed/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/Getopt-EX-Hashed.svg)](https://metacpan.org/release/Getopt-EX-Hashed)
# NAME

Getopt::EX::Hashed - Hash object automation for Getopt::Long

# VERSION

Version 1.0602

# SYNOPSIS

    # script/foo
    use App::foo;
    App::foo->new->run();

    # lib/App/foo.pm
    package App::foo;

    use Getopt::EX::Hashed; {
        Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );
        has start    => ' =i  s begin ' , default => 1;
        has end      => ' =i  e       ' ;
        has file     => ' =s@ f       ' , any => qr/^(?!\.)/;
        has score    => ' =i          ' , min => 0, max => 100;
        has answer   => ' =i          ' , must => sub { $_[1] == 42 };
        has mouse    => ' =s          ' , any => [ 'Frankie', 'Benjy' ];
        has question => ' =s          ' , any => qr/^(life|universe|everything)$/i;
    } no Getopt::EX::Hashed;

    sub run {
        my $app = shift;
        use Getopt::Long;
        $app->getopt or pod2usage();
        if ($app->answer == 42) {
            $app->question //= 'life';
            ...

# DESCRIPTION

**Getopt::EX::Hashed** is a module to automate the creation of a hash
object to store command line option values for **Getopt::Long** and
compatible modules including **Getopt::EX::Long**.  The module name
shares the **Getopt::EX** prefix, but it works independently from other
modules in **Getopt::EX**, so far.

The major objective of this module is integrating initialization and
specification into a single place.  It also provides a simple
validation interface.

Accessor methods are automatically generated when `is` parameter is
given.  If the same function is already defined, the program causes
fatal error.  Accessors are removed when the object is destroyed.
Problems may occur when multiple objects are present at the same time.

# FUNCTION

## **has**

Declare option parameters in the following form.  The parentheses are
for clarity only and may be omitted.

    has option_name => ( param => value, ... );

For example, to define the option `--number`, which takes an integer
value as a parameter, and also can be used as `-n`, do the following

    has number => spec => "=i n";

The accessor is created with the first name. In this
example, the accessor will be defined as `$app->number`.

If an array reference is given, multiple names can be declared at once.

    has [ 'left', 'right' ] => ( spec => "=i" );

If the name starts with plus (`+`), the given parameter updates the
existing setting.

    has '+left' => ( default => 1 );

As for the `spec` parameter, the label can be omitted if it is the
first parameter.

    has left => "=i", default => 1;

If the number of parameters is odd, the first parameter is treated as
having an implicit label: `action` if it is a code reference,
`spec` otherwise.

Following parameters are available.

- \[ **spec** => \] _string_

    Give option specification.  `spec =>` label can be omitted if and
    only if it is the first parameter.

    In _string_, option spec and alias names are separated by white
    space, and can show up in any order.

    To have an option called `--start` that takes an integer as its value
    and can also be used with the names `-s` and `--begin`, declare as
    follows.

        has start => "=i s begin";

    The above declaration will be compiled into the following string.

        start|s|begin=i

    which conforms to the `Getopt::Long` definition.  Of course, you can
    write it as:

        has start => "s|begin=i";

    If the name and aliases contain underscore (`_`), another alias name
    is defined with dash (`-`) in place of underscores.

        has a_to_z => "=s";

    The above declaration will be compiled into the following string.

        a_to_z|a-to-z=s

    If no option spec is needed, give an empty (or white space only)
    string as a value.  Without a spec string, the member will not be
    treated as an option.

- **alias** => _string_

    Additional alias names can be specified by the **alias** parameter too.
    There is no difference from the ones in the `spec` parameter.

        has start => "=i", alias => "s begin";

- **is** => `ro` | `rw`

    To produce an accessor method, the `is` parameter is necessary.  Set
    the value `ro` for read-only, `rw` for read-write.

    Read-write accessor has lvalue attribute, so it can be assigned to.
    You can use like this:

        $app->foo //= 1;

    This is much simpler than writing as in the following.

        $app->foo(1) unless defined $app->foo;

    If you want to make accessors for all following members, use
    `configure` to set the `DEFAULT` parameter.

        Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );

    If you don't like assignable accessors, configure the `ACCESSOR_LVALUE`
    parameter to 0.  Because accessors are generated at the time of `new`,
    this value is effective for all members.

- **default** => _value_ | _coderef_

    Set default value.  If no default is given, the member is initialized
    as `undef`.

    If the value is a reference to an ARRAY or HASH, a shallow copy is
    created for each `new` call.  This means the reference itself is
    copied, but the contents are shared.  Modifying the array or hash
    contents will affect all instances.

    If a code reference is given, it is called at the time of **new** to
    get default value.  This is effective when you want to evaluate the
    value at the time of execution, rather than declaration.  If you want
    to define a default action, use the **action** parameter.  If you want
    to set code reference as the initial value, you must specify a code
    reference that returns a code reference.

    If a reference to SCALAR is given, the option value is stored in the
    data indicated by the reference, not in the hash object member.  In
    this case, the expected value cannot be obtained by accessing the hash
    member.

- \[ **action** => \] _coderef_

    Parameter `action` takes code reference which is called to process
    the option.  `action =>` label can be omitted if and only if it
    is the first parameter.

    When called, hash object is passed as `$_`.

        has [ qw(left right both) ] => '=i';
        has "+both" => sub {
            $_->{left} = $_->{right} = $_[1];
        };

    You can use this for `"<>"` to handle non-option arguments.  In
    that case, the spec parameter does not matter and is not required.

        has ARGV => default => [];
        has "<>" => sub {
            push @{$_->{ARGV}}, $_[0];
        };

Following parameters are all for data validation.  First, `must` is a
generic validator and can implement anything.  Others are shortcuts
for common rules.

- **must** => _coderef_ | \[ _coderef_ ... \]

    Parameter `must` takes a code reference to validate option values.
    It takes the same arguments as `action` and returns a boolean.  With
    the following example, option **--answer** takes only 42 as a valid
    value.

        has answer => '=i',
            must => sub { $_[1] == 42 };

    If multiple code references are given, all code must return true.

        has answer => '=i',
            must => [ sub { $_[1] >= 42 }, sub { $_[1] <= 42 } ];

- **min** => _number_
- **max** => _number_

    Set the minimum and maximum limit for the argument.

- **any** => _arrayref_ | qr/_regex_/ | _coderef_

    Set the valid string parameter list.  Each item can be a string, a
    regex reference, or a code reference.  The argument is valid when it
    is the same as, or matches any item of the given list.  If the value
    is not an arrayref, it is taken as a single item list (regexpref or
    coderef usually).

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

## **new**

A class method that creates a new hash object.  Initializes all
members with their default values and creates accessor methods as
configured.  Returns a blessed hash reference.  The hash keys are
locked if LOCK\_KEYS is enabled.

## **optspec**

Returns the option specification list which can be passed to the
`GetOptions` function.

    GetOptions($obj->optspec)

`GetOptions` has the capability of storing values in a hash by
giving the hash reference as the first argument, but it is not
necessary.

## **getopt** \[ _arrayref_ \]

Calls the appropriate function defined in the caller's context to
process options.

    $obj->getopt

    $obj->getopt(\@argv);

The above examples are shortcuts for the following code.

    GetOptions($obj->optspec)

    GetOptionsFromArray(\@argv, $obj->optspec)

## **use\_keys** _keys_

When LOCK\_KEYS is enabled, accessing a non-existent member causes an
error.  Use this method to declare new member keys before accessing
them.

    $obj->use_keys( qw(foo bar) );

If you want to access arbitrary keys, unlock the object.

    use Hash::Util 'unlock_keys';
    unlock_keys %{$obj};

You can change this behavior by `configure` with `LOCK_KEYS`
parameter.

## **configure** **label** => _value_, ...

Use class method `Getopt::EX::Hashed->configure()` before
creating an object; this information is stored separately for each
calling package.  After calling `new()`, the package-level
configuration is copied into the object for its use.  Use
`$obj->configure()` to update object-level configuration.

The following configuration parameters are available.

- **LOCK\_KEYS** (default: 1)

    Lock hash keys.  This prevents typos or other mistakes from creating
    unintended hash entries.

- **REPLACE\_UNDERSCORE** (default: 1)

    Automatically create option aliases with underscores replaced by
    dashes.

- **REMOVE\_UNDERSCORE** (default: 0)

    Automatically create option aliases with underscores removed.

- **GETOPT** (default: 'GetOptions')
- **GETOPT\_FROM\_ARRAY** (default: 'GetOptionsFromArray')

    Set the function name called from the `getopt` method.

- **ACCESSOR\_PREFIX** (default: '')

    When specified, it will be prepended to the member name to make the
    accessor method.  If `ACCESSOR_PREFIX` is defined as `opt_`, the
    accessor for member `file` will be `opt_file`.

- **ACCESSOR\_LVALUE** (default: 1)

    If true, read-write accessors have the lvalue attribute.  Set to zero
    if you don't like that behavior.

- **DEFAULT**

    Set default parameters.  When `has` is called, DEFAULT parameters are
    inserted before the explicit parameters.  If a parameter appears in
    both, the explicit one takes precedence.  Incremental calls with `+`
    are not affected.

    A typical use of DEFAULT is `is` to prepare accessor methods for all
    following hash entries.  Declare `DEFAULT => []` to reset.

        Getopt::EX::Hashed->configure(DEFAULT => [ is => 'ro' ]);

## **reset**

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

Copyright 2021-2025 Kazumasa Utashiro

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
