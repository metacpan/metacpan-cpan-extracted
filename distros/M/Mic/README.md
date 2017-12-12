# NAME

Mic - Simplified OOP with emphasis on modularity and loose coupling.

# SYNOPSIS

    # A simple Set class:

    package Example::Synopsis::Set;

    use Mic::Class
        interface => {
            object => {
                add => {},
                has => {},
            },
            class => {
                new => {},
            }
        },

        implementation => 'Example::Synopsis::ArraySet',
        ;
    1;

    # And the implementation for this class:

    package Example::Synopsis::ArraySet;

    use Mic::Impl
        has => { SET => { default => sub { [] } } },
    ;

    sub has {
        my ($self, $e) = @_;
        scalar grep { $_ == $e } @{ $self->[SET] };
    }

    sub add {
        my ($self, $e) = @_;

        if ( ! $self->has($e) ) {
            push @{ $self->[SET] }, $e;
        }
    }

    1;


    # Now we can use it

    use Test::More tests => 2;
    use Example::Synopsis::Set;

    my $set = Example::Synopsis::Set::->new;

    ok ! $set->has(1);
    $set->add(1);
    ok $set->has(1);


    # But this has O(n) lookup and we can do better, so:

    package Example::Synopsis::HashSet;

    use Mic::Impl
        has => { SET => { default => sub { {} } } },
    ;

    sub has {
        my ($self, $e) = @_;
        exists $self->[SET]{$e};
    }

    sub add {
        my ($self, $e) = @_;
        ++$self->[SET]{$e};
    }

    1;


    # Now to make use of this we can either:

    package Example::Synopsis::Set;

    use Mic::Class
        interface => {
            object => {
                add => {},
                has => {},
            },
            class => {
                new => {},
            }
        },

        implementation => 'Example::Synopsis::HashSet'; # updated

    1;

    # Or just

    use Test::More tests => 2;
    use Mic::Bind 'Example::Synopsis::Set' => 'Example::Synopsis::HashSet';
    use Example::Synopsis::Set;

    my $set = Example::Synopsis::Set::->new;

    ok ! $set->has(1);
    $set->add(1);
    ok $set->has(1);

# STATUS

This is an early release available for testing and feedback and as such is subject to change.

# DESCRIPTION

Mic (Messages, Interfaces and Contracts) is a framework for simplifying the coding of OOP modules, with the following features:

- Reduces the tedium and boilerplate code typically involved in creating object oriented modules.
- Makes it easy to create classes that are [modular](http://en.wikipedia.org/wiki/Modular_programming) and loosely coupled.
- Enables trivial swapping of implementations (see [Mic::Bind](https://metacpan.org/pod/Mic::Bind)).
- Encourages self documenting code.
- Simplifies code verification via Eiffel style [contracts](https://metacpan.org/pod/Mic::Contracts).

Modularity means there is an obvious separation between what the users of an object need to know (the interface for using the object) and implementation details that users
don't need to know about.

This separation of interface from implementation details is an important aspect of modular design, as it enables modules to be interchangeable (so long as they have the same interface).

It is not a coincidence that the Object Oriented concept as originally envisioned was mainly concerned with messaging,
where in the words of Alan Kay (who coined the term "Object Oriented Programming") objects are "like biological cells and/or individual computers on a network, only able to communicate with messages"
and "OOP to me means only messaging, local retention and protection and hiding of state-process, and extreme late-binding of all things."
(see [The Deep Insights of Alan Kay](http://mythz.servicestack.net/blog/2013/02/27/the-deep-insights-of-alan-kay/)).

# USAGE

## Mic->define\_class(HASHREF)

In the simplest scenario in which both interface and implementation are defined in the same file, a class can also be defined by calling the `define_class()` class method, with a hashref that
specifies the class.

The class defined in the SYNOPSIS could also be defined like this

    package Example::Usage::Set;

    use Mic;

    Mic->define_class({
        interface => { 
            object => {
                add => {},
                has => {},
            },
            class => { new => {} }
        },

        via => 'Example::Usage::HashSet',
    });

    package Example::Usage::HashSet;

    use Mic::Impl
        has => { SET => { default => sub { {} } } },
    ;

    sub has {
        my ($self, $e) = @_;
        exists $self->[SET]{$e};
    }

    sub add {
        my ($self, $e) = @_;
        ++$self->[SET]{$e};
    }

    1;

For scenarios in which interfaces and implementations are defined in their own files, see [Mic::Class](https://metacpan.org/pod/Mic::Class) and [Mic::Interface](https://metacpan.org/pod/Mic::Interface).

## Specification

The meaning of the keys in the specification hash are described next.

### interface => HASHREF | STRING

The interface is a group of messages that objects belonging to this class should respond to.

It can be specified as a reference to a hash, in which the values of the hash are [contracts](https://metacpan.org/pod/Mic::Contracts) on the keys.

It can also be specified as a string that names a [Mic::Interface](https://metacpan.org/pod/Mic::Interface) package which defines the interface.

An exception is raised if this is empty or missing.

The messages named in this group must have corresponding subroutine definitions in a declared implementation,
otherwise an exception is raised.

The interface consists of the following subsections:

#### object => HASHREF

Specifies the names of each method that these objects can respond to, as well as their contracts.

#### class => HASHREF

Specifies the names of each class method that the class can respond to, as well as their contracts.

#### invariant => HASHREF

See [Mic::Contracts](https://metacpan.org/pod/Mic::Contracts) for more details about invariants.

#### extends => STRING | ARRAYREF

Specifies the names of one or more super-interfaces. This means the interface will include any methods from the super-interfaces that aren't declared locally.

### implementation => STRING

The name of a package that defines the subroutines declared in the interface.

[Mic::Impl](https://metacpan.org/pod/Mic::Impl) describes how implementations are configured.

### impl => STRING

An alias of "implementation" above.

### via => STRING

An alias of "implementation" above.

# Interface Sharing

### Mic::Interface

If two or more classes share a common interface, we can reduce duplication by factoring out that interface using [Mic::Interface](https://metacpan.org/pod/Mic::Interface), which expects an interface specified in the same way as `interface` 

Suppose we wanted to use both versions of the set class (from the synopsis) in the same program.

The first step is to extract the common interface:

    package Example::Usage::SetInterface;

    use Mic::Interface
        object => {
            add => {},
            has => {},
        },
        class => { new => {} }
    ;

    1;

### Mic->load\_class(HASHREF)

Then implementations of this interface can be loaded via `load_class`:

    use Test::More tests => 4;
    use Example::Usage::SetInterface;

    my $HashSetClass = Mic->load_class({
        interface      => 'Example::Usage::SetInterface',
        implementation => 'Example::Synopsis::HashSet',
    });

    Mic->load_class({
        interface      => 'Example::Usage::SetInterface',
        implementation => 'Example::Synopsis::ArraySet',
        name           => 'ArraySet',
    });

    my $a_set = 'ArraySet'->new;
    ok ! $a_set->has(1);
    $a_set->add(1);
    ok $a_set->has(1);

    my $h_set = $HashSetClass->new;
    ok ! $h_set->has(1);
    $h_set->add(1);
    ok $h_set->has(1);

`load_class` expects a hashref with the following keys:

#### interface

The name of an interface declared via `declare_interface`.

#### implementation

The name of an implementation package.

#### name (optional)

The name of the class via which objects are created.

This is optional and if not given, a synthetic name is used. In either case this name is 
returned by `load_class`

## Introspection

Behavioural (method) and interface introspection are possible using `$object->can` and `$object->DOES` respectiively which if called with no argument will return a list (or array ref depending on context) of methods or interfaces supported by the object.

Also note that for any class `Foo` created using Mic, and for any object created with `Foo`'s constructor, the following will always return a true value

    $object->DOES('Foo')

# BUGS

Please report any bugs or feature requests via the GitHub web interface at
[https://github.com/arunbear/Mic/issues](https://github.com/arunbear/Mic/issues).

# ACKNOWLEDGEMENTS

Stevan Little (for creating Moose), Tye McQueen (for numerous insights on class building and modular programming).

# AUTHOR

Arun Prasaad <arunbear@cpan.org>

# COPYRIGHT

Copyright 2014- Arun Prasaad

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU public license, version 3.

# SEE ALSO
