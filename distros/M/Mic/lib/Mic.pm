package Mic;

use strict;
use 5.008_005;
use Carp;
use Params::Validate qw(:all);
use Mic::Assembler;

our $VERSION = '0.001004';
$VERSION = eval $VERSION;

my $Class_count = 0;
our %Bound_implementation_of;
our %Contracts_for;
our %Spec_for;
our %Util_class;

sub import {
    strict->import();
}

sub load_class {
    my ($class, $spec) = @_;

    $spec->{name} ||= "Mic::Class_${\ ++$Class_count }";
    $class->assemble($spec);
}

sub assemble {
    my (undef, $spec) = @_;

    my $assembler = Mic::Assembler->new(-spec => $spec);
    my $cls_stash;
    if ( ! $spec->{name} ) {
        my $depth = 0;
        my $caller_pkg = '';
        my $pkg = __PACKAGE__;

        do {
            $caller_pkg = (caller $depth++)[0];
        }
          while $caller_pkg =~ /^$pkg\b/;
        $spec = $assembler->load_spec_from($caller_pkg);
    }

    _check_imp_aliases($spec);
    my @args = %$spec;
    validate(@args, {
        interface => { type => HASHREF | SCALAR },
        implementation => { type => SCALAR },
        name => { type => SCALAR, optional => 1 },
    });
    return $assembler->assemble;
}

sub _check_imp_aliases {
    my ($spec) = @_;
    
    my @imp_aliases = qw[via impl];
    foreach my $k (@imp_aliases) {
        if (! exists $spec->{implementation} && exists $spec->{$k}) {
            $spec->{implementation} = $spec->{$k};
            delete @{$spec}{ @imp_aliases };
            last;
        }
    }
}

*setup_class = \&assemble;
*define_class = \&assemble;

sub builder_for {
    my ($class) = @_;

    return $Util_class{ $class }
      or confess "Unknown class: $class";
}

1;
__END__

=encoding utf-8

=head1 NAME

Mic - Simplified OOP with emphasis on modularity and loose coupling.

=head1 SYNOPSIS

    # The evolution of a simple Set class:

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

=head1 STATUS

This is an early release available for testing and feedback and as such is subject to change.

=head1 DESCRIPTION

Mic (Messages, Interfaces and Contracts) is a framework for simplifying the coding of OOP modules, with the following features:

=over

=item *

Reduces the tedium and boilerplate code typically involved in creating object oriented modules.

=item *

Makes it easy to create classes that are L<modular|http://en.wikipedia.org/wiki/Modular_programming> and loosely coupled.

=item *

Enables trivial swapping of implementations (see L<Mic::Bind>).

=item *

Encourages self documenting code.

=item *

Simplifies code verification via Eiffel style L<contracts|Mic::Contracts>.

=back


Modularity means there is an obvious separation between what the users of an object need to know (the interface for using the object) and implementation details that users
don't need to know about.

This separation of interface from implementation details is an important aspect of modular design, as it enables modules to be interchangeable (so long as they have the same interface).

It is not a coincidence that the Object Oriented concept as originally envisioned was mainly concerned with messaging,
where in the words of Alan Kay (who coined the term "Object Oriented Programming") objects are "like biological cells and/or individual computers on a network, only able to communicate with messages"
and "OOP to me means only messaging, local retention and protection and hiding of state-process, and extreme late-binding of all things."
(see L<The Deep Insights of Alan Kay|http://mythz.servicestack.net/blog/2013/02/27/the-deep-insights-of-alan-kay/>).

=head1 USAGE

=head2 Mic->define_class(HASHREF)

In the simplest scenario in which both interface and implementation are defined in the same file, a class can also be defined by calling the C<define_class()> class method, with a hashref that
specifies the class.

The class defined in the SYNOPSIS could also be defined like this (in one file)

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

For scenarios in which interfaces and implementations are defined in their own files, see L<Mic::Class> and L<Mic::Interface>.

=head2 Specification

The meaning of the keys in the specification hash are described next.

=head3 interface => HASHREF | STRING

The interface is a group of messages that objects belonging to this class should respond to.

It can be specified as a reference to a hash, in which the values of the hash are L<contracts|Mic::Contracts> on the keys.

It can also be specified as a string that names a L<Mic::Interface> package which defines the interface.

An exception is raised if this is empty or missing.

The messages named in this group must have corresponding subroutine definitions in a declared implementation,
otherwise an exception is raised.

The interface consists of the following subsections:

=head4 object => HASHREF

Specifies the names of each method that these objects can respond to, as well as their contracts.

=head4 class => HASHREF

Specifies the names of each class method that the class can respond to, as well as their contracts.

=head4 invariant => HASHREF

See L<Mic::Contracts> for more details about invariants.

=head4 extends => STRING | ARRAYREF

Specifies the names of one or more super-interfaces. This means the interface will include any methods from the super-interfaces that aren't declared locally.

=head3 implementation => STRING

The name of a package that defines the subroutines declared in the interface.

L<Mic::Impl> describes how implementations are configured.

=head3 impl => STRING

An alias of "implementation" above.

=head3 via => STRING

An alias of "implementation" above.

=head1 Interface Sharing

=head3 Mic::Interface

If two or more classes share a common interface, we can reduce duplication by factoring out that interface using L<Mic::Interface>, which expects an interface specified in the same way as C<interface> 

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

=head3 Mic->load_class(HASHREF)

Then implementations of this interface can be loaded via C<load_class>:

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

C<load_class> expects a hashref with the following keys:

=head4 interface

The name of an interface declared via C<declare_interface>.

=head4 implementation

The name of an implementation package.

=head4 name (optional)

The name of the class via which objects are created.

This is optional and if not given, a synthetic name is used. In either case this name is 
returned by C<load_class>

=head2 Introspection

Behavioural (method) and interface introspection are possible using C<$object-E<gt>can> and C<$object-E<gt>DOES> respectiively which if called with no argument will return a list (or array ref depending on context) of methods or interfaces supported by the object.

Also note that for any class C<Foo> created using Mic, and for any object created with C<Foo>'s constructor, the following will always return a true value

    $object->DOES('Foo')

=head1 BUGS

Please report any bugs or feature requests via the GitHub web interface at
L<https://github.com/arunbear/Mic/issues>.

=head1 ACKNOWLEDGEMENTS

Stevan Little (for creating Moose), Tye McQueen (for numerous insights on class building and modular programming).

=head1 AUTHOR

Arun Prasaad E<lt>arunbear@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Arun Prasaad

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU public license, version 3.

=head1 SEE ALSO

=cut
