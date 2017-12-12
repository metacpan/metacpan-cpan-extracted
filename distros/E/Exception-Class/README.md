# NAME

Exception::Class - A module that allows you to declare real exception classes in Perl

# VERSION

version 1.44

# SYNOPSIS

    use Exception::Class (
        'MyException',

        'AnotherException' => { isa => 'MyException' },

        'YetAnotherException' => {
            isa         => 'AnotherException',
            description => 'These exceptions are related to IPC'
        },

        'ExceptionWithFields' => {
            isa    => 'YetAnotherException',
            fields => [ 'grandiosity', 'quixotic' ],
            alias  => 'throw_fields',
        },
    );
    use Scalar::Util qw( blessed );
    use Try::Tiny;

    try {
        MyException->throw( error => 'I feel funny.' );
    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');

        if ( $_->isa('Exception::Class') ) {
            warn $_->error, "\n", $_->trace->as_string, "\n";
            warn join ' ', $_->euid, $_->egid, $_->uid, $_->gid, $_->pid, $_->time;

            exit;
        }
        elsif ( $_->isa('ExceptionWithFields') ) {
            if ( $_->quixotic ) {
                handle_quixotic_exception();
            }
            else {
                handle_non_quixotic_exception();
            }
        }
        else {
            $_->rethrow;
        }
    };

    # without Try::Tiny
    eval { ... };
    if ( my $e = Exception::Class->caught ) { ... }

    # use an alias - without parens subroutine name is checked at
    # compile time
    throw_fields error => "No strawberry", grandiosity => "quite a bit";

# DESCRIPTION

**RECOMMENDATION 1**: If you are writing modern Perl code with [Moose](https://metacpan.org/pod/Moose) or
[Moo](https://metacpan.org/pod/Moo) I highly recommend using [Throwable](https://metacpan.org/pod/Throwable) instead of this module.

**RECOMMENDATION 2**: Whether or not you use [Throwable](https://metacpan.org/pod/Throwable), you should use
[Try::Tiny](https://metacpan.org/pod/Try::Tiny).

Exception::Class allows you to declare exception hierarchies in your modules
in a "Java-esque" manner.

It features a simple interface allowing programmers to 'declare' exception
classes at compile time. It also has a base exception class,
[Exception::Class::Base](https://metacpan.org/pod/Exception::Class::Base), that can be easily extended.

It is designed to make structured exception handling simpler and better by
encouraging people to use hierarchies of exceptions in their applications, as
opposed to a single catch-all exception class.

This module does not implement any try/catch syntax. Please see the "OTHER
EXCEPTION MODULES (try/catch syntax)" section for more information on how to
get this syntax.

You will also want to look at the documentation for [Exception::Class::Base](https://metacpan.org/pod/Exception::Class::Base),
which is the default base class for all exception objects created by this
module.

# DECLARING EXCEPTION CLASSES

Importing `Exception::Class` allows you to automagically create
[Exception::Class::Base](https://metacpan.org/pod/Exception::Class::Base) subclasses. You can also create subclasses via the
traditional means of defining your own subclass with `@ISA`.  These two
methods may be easily combined, so that you could subclass an exception class
defined via the automagic import, if you desired this.

The syntax for the magic declarations is as follows:

    'MANDATORY CLASS NAME' => \%optional_hashref

The hashref may contain the following options:

- isa

    This is the class's parent class. If this isn't provided then the class name
    in `$Exception::Class::BASE_EXC_CLASS` is assumed to be the parent (see
    below).

    This parameter lets you create arbitrarily deep class hierarchies.  This can
    be any other [Exception::Class::Base](https://metacpan.org/pod/Exception::Class::Base) subclass in your declaration _or_ a
    subclass loaded from a module.

    To change the default exception class you will need to change the value of
    `$Exception::Class::BASE_EXC_CLASS` _before_ calling `import`. To do this
    simply do something like this:

        BEGIN { $Exception::Class::BASE_EXC_CLASS = 'SomeExceptionClass'; }

    If anyone can come up with a more elegant way to do this please let me know.

    CAVEAT: If you want to automagically subclass an [Exception::Class::Base](https://metacpan.org/pod/Exception::Class::Base)
    subclass loaded from a file, then you _must_ compile the class (via use or
    require or some other magic) _before_ you import `Exception::Class` or
    you'll get a compile time error.

- fields

    This allows you to define additional attributes for your exception class. Any
    field you define can be passed to the `throw` or `new` methods as additional
    parameters for the constructor. In addition, your exception object will have
    an accessor method for the fields you define.

    This parameter can be either a scalar (for a single field) or an array
    reference if you need to define multiple fields.

    Fields will be inherited by subclasses.

- alias

    Specifying an alias causes this class to create a subroutine of the specified
    name in the _caller's_ namespace. Calling this subroutine is equivalent to
    calling `<class>->throw(@_)` for the given exception class.

    Besides convenience, using aliases also allows for additional compile time
    checking. If the alias is called _without parentheses_, as in `throw_fields
    "an error occurred"`, then Perl checks for the existence of the
    `throw_fields` subroutine at compile time. If instead you do `ExceptionWithFields->throw(...)`, then Perl checks the class name at
    runtime, meaning that typos may sneak through.

- description

    Each exception class has a description method that returns a fixed
    string. This should describe the exception _class_ (as opposed to any
    particular exception object). This may be useful for debugging if you start
    catching exceptions you weren't expecting (particularly if someone forgot to
    document them) and you don't understand the error messages.

The `Exception::Class` magic attempts to detect circular class hierarchies
and will die if it finds one. It also detects missing links in a chain, for
example if you declare Bar to be a subclass of Foo and never declare Foo.

# [Try::Tiny](https://metacpan.org/pod/Try::Tiny)

If you are interested in adding try/catch/finally syntactic sugar to your code
then I recommend you check out [Try::Tiny](https://metacpan.org/pod/Try::Tiny). This is a great module that helps
you ignore some of the weirdness with `eval` and `$@`. Here's an example of
how the two modules work together:

    use Exception::Class ( 'My::Exception' );
    use Scalar::Util qw( blessed );
    use Try::Tiny;

    try {
        might_throw();
    }
    catch {
        if ( blessed $_ && $_->isa('My::Exception') ) {
            handle_it();
        }
        else {
            die $_;
        }
    };

Note that you **cannot** use `Exception::Class->caught` with [Try::Tiny](https://metacpan.org/pod/Try::Tiny).

# Catching Exceptions Without [Try::Tiny](https://metacpan.org/pod/Try::Tiny)

`Exception::Class` provides some syntactic sugar for catching exceptions in a
safe manner:

    eval {...};

    if ( my $e = Exception::Class->caught('My::Error') ) {
        cleanup();
        do_something_with_exception($e);
    }

The `caught` method takes a class name and returns an exception object if the
last thrown exception is of the given class, or a subclass of that class. If
it is not given any arguments, it simply returns `$@`.

You should **always** make a copy of the exception object, rather than using
`$@` directly. This is necessary because if your `cleanup` function uses
`eval`, or calls something which uses it, then `$@` is overwritten. Copying
the exception preserves it for the call to `do_something_with_exception`.

Exception objects also provide a caught method so you can write:

    if ( my $e = My::Error->caught ) {
        cleanup();
        do_something_with_exception($e);
    }

## Uncatchable Exceptions

Internally, the `caught` method will call `isa` on the exception object. You
could make an exception "uncatchable" by overriding `isa` in that class like
this:

    package Exception::Uncatchable;

    sub isa { shift->rethrow }

Of course, this only works if you always call `Exception::Class->caught`
after an `eval`.

# USAGE RECOMMENDATION

If you're creating a complex system that throws lots of different types of
exceptions, consider putting all the exception declarations in one place. For
an app called Foo you might make a `Foo::Exceptions` module and use that in
all your code. This module could just contain the code to make
`Exception::Class` do its automagic class creation. Doing this allows you to
more easily see what exceptions you have, and makes it easier to keep track of
them.

This might look something like this:

    package Foo::Bar::Exceptions;

    use Exception::Class (
        Foo::Bar::Exception::Senses =>
            { description => 'sense-related exception' },

        Foo::Bar::Exception::Smell => {
            isa         => 'Foo::Bar::Exception::Senses',
            fields      => 'odor',
            description => 'stinky!'
        },

        Foo::Bar::Exception::Taste => {
            isa         => 'Foo::Bar::Exception::Senses',
            fields      => [ 'taste', 'bitterness' ],
            description => 'like, gag me with a spoon!'
        },

        ...
    );

You may want to create a real module to subclass [Exception::Class::Base](https://metacpan.org/pod/Exception::Class::Base) as
well, particularly if you want your exceptions to have more methods.

## Subclassing Exception::Class::Base

As part of your usage of `Exception::Class`, you may want to create your own
base exception class which subclasses [Exception::Class::Base](https://metacpan.org/pod/Exception::Class::Base). You should
feel free to subclass any of the methods documented above. For example, you
may want to subclass `new` to add additional information to your exception
objects.

# Exception::Class FUNCTIONS

The `Exception::Class` method offers one function, `Classes`, which is not
exported. This method returns a list of the classes that have been created by
calling the `Exception::Class` `import` method.  Note that this is _all_
the subclasses that have been created, so it may include subclasses created by
things like CPAN modules, etc. Also note that if you simply define a subclass
via the normal Perl method of setting `@ISA` or `use base`, then your
subclass will not be included.

# SUPPORT

Bugs may be submitted at [https://github.com/houseabsolute/Exception-Class/issues](https://github.com/houseabsolute/Exception-Class/issues).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for Exception-Class can be found at [https://github.com/houseabsolute/Exception-Class](https://github.com/houseabsolute/Exception-Class).

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [http://www.urth.org/~autarch/fs-donation.html](http://www.urth.org/~autarch/fs-donation.html).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Alexander Batyrshin <0x62ash@gmail.com>
- Leon Timmermans <fawaka@gmail.com>
- Ricardo Signes <rjbs@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
`LICENSE` file included with this distribution.
