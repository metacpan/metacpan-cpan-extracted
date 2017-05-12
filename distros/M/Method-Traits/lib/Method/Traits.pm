package Method::Traits;
# ABSTRACT: Apply traits to your methods

use strict;
use warnings;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

use Carp                   ();
use Scalar::Util           ();
use MOP                    (); # this is how we do most of our work
use attributes             (); # this is where we store the traits
use B::CompilerPhase::Hook (); # multi-phase programming
use Module::Runtime        (); # trait provider loading

## ...

use Method::Traits::Trait;
use Method::Traits::Meta::Provider;

## --------------------------------------------------------
## Importers
## --------------------------------------------------------

sub import {
    my $class = shift;

    return unless @_;

    my @args = @_;
    if ( scalar(@args) == 1 && $args[0] eq ':for_providers' ) {
        # expand this to make it easier for providers
        $args[0] = 'Method::Traits::Meta::Provider';
    }

    $class->import_into( scalar caller, @args );
}

sub import_into {
    my ($class, $target, @providers) = @_;
    my $meta = Scalar::Util::blessed( $target ) ? $target : MOP::Class->new( $target );
    $class->schedule_trait_collection( $meta, @providers );
}

## --------------------------------------------------------
## Storage
## --------------------------------------------------------

our %PROVIDERS_BY_PKG; # this hold the set of available traits per package
our %TRAIT_BY_CODE;    # mapping of CODE address to Trait

## Per-Package Provider Management

sub add_trait_providers_for {
    my (undef, $meta, @providers) = @_;
    Module::Runtime::use_package_optimistically( $_ ) foreach @providers;
    push @{ $PROVIDERS_BY_PKG{ $meta->name } ||=[] } => @providers;
}

sub get_trait_providers_for {
    my (undef, $meta) = @_;
    return @{ $PROVIDERS_BY_PKG{ $meta->name } ||=[] };
}

## Per-CODE Trait Management

sub add_traits_for {
    my (undef, $method, @traits) = @_;
    push @{ $TRAIT_BY_CODE{ $method->body } ||=[] } => @traits;
}

sub get_traits_for {
    my (undef, $method) = @_;
    return @{ $TRAIT_BY_CODE{ $method->body } ||=[] };
}

## --------------------------------------------------------
## Trait collection
## --------------------------------------------------------

sub schedule_trait_collection {
    my ($class, $meta, @providers) = @_;

    # It does not make any sense to create
    # something that is meant to run in the
    # BEGIN phase *after* that phase is done
    # so catch this and error ...
    Carp::croak('Trait collection must be scheduled during BEGIN time, not (' . ${^GLOBAL_PHASE}. ')')
        unless ${^GLOBAL_PHASE} eq 'START';

    # add in the providers, so we can
    # get to them in other BEGIN blocks
    $class->add_trait_providers_for( $meta, @providers );

    # no need to install the collectors
    # if they have already been installed
    # as they are not different
    return
        if $meta->has_method_alias('FETCH_CODE_ATTRIBUTES')
        && $meta->has_method_alias('MODIFY_CODE_ATTRIBUTES');

    # now install the collectors ...
    $meta->alias_method(
        FETCH_CODE_ATTRIBUTES => sub {
            my ($pkg, $code) = @_;
            # return just the strings, as expected by attributes ...
            return map $_->original, $class->get_traits_for( MOP::Method->new( $code ) );
        }
    );
    $meta->alias_method(
        MODIFY_CODE_ATTRIBUTES => sub {
            my ($pkg, $code, @attrs) = @_;

            my $klass  = MOP::Class->new( $pkg );
            my $method = MOP::Method->new( $code );

            my @traits    = map Method::Traits::Trait->new( $_ ), @attrs;
            my @unhandled = $class->find_unhandled_traits( $klass, @traits );

            #use Data::Dumper;
            #warn "WE ARE IN $pkg for $code with " . join ', ' => @attrs;
            #warn "ATTRS: " . Dumper \@attrs;
            #warn "TRAITS: " . Dumper \@traits;
            #warn "UNHANDLED: " . Dumper \@unhandled;

            # bad traits are bad,
            # return the originals that
            # we do not handle
            return map $_->original, @unhandled if @unhandled;

            # NOTE:
            # ponder the idea of moving this
            # call to UNITCHECK phase, not sure
            # if that actually makes sense or not
            # so it will need to be explored.
            # - SL
            $method = $class->apply_all_trait_handlers( $klass, $method, \@traits );

            # store the traits we applied ...
            $class->add_traits_for( $method, @traits );

            #warn ${^GLOBAL_PHASE};

            # all is well, so let the world know that ...
            return;
        }
    );

    B::CompilerPhase::Hook::enqueue_CHECK {
        #warn "STEP 2";
        #warn "CHECK: " . ${^GLOBAL_PHASE};

        $meta->delete_method_alias('MODIFY_CODE_ATTRIBUTES');
    };
}

sub find_unhandled_traits {
    my ($class, $meta, @traits) = @_;

    # Now loop through the traits and look to
    # see if we have any ones we cannot handle
    # and collect them for later ...
    return grep {
        my $stop;
        foreach my $provider ( $class->get_trait_providers_for( $meta ) ) {
            #warn "PROVIDER: $provider looking for: " . $_->[0];
            if ( my $handler = $provider->can( $_->name ) ) {
                $_->handler( MOP::Method->new( $handler ) );
                $stop++;
                last;
            }
        }
        not( $stop );
    } @traits;
}

sub apply_all_trait_handlers {
    my (undef, $meta, $method, $traits) = @_;

    # now we need to loop through the traits
    # that we parsed and apply the trait function
    # to our method accordingly

    my $method_name = $method->name;

    foreach my $trait ( @$traits ) {
        my ($args, $handler) = ($trait->args, $trait->handler);
        $handler->body->( $meta, $method, @$args );
        if ( $handler->has_code_attributes('OverwritesMethod') ) {
            $method = $meta->get_method( $method_name );
            Carp::croak('Failed to find new overwriten method ('.$method_name.') in class ('.$meta->name.')')
                unless defined $method;
        }
    }

    return $method;
}

1;

__END__

=pod

=head1 NAME

Method::Traits - Apply traits to your methods

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    package Person;
    use strict;
    use warnings;

    use Method::Traits qw[ MyAccessor::Trait::Provider ];

    use parent 'UNIVERSAL::Object';

    our %HAS = (
        fname => sub { "" },
        lname => sub { "" },
    );

    sub first_name : Accessor('ro', 'fname');
    sub last_name  : Accessor('rw', 'lname');

    package MyAccessor::Trait::Provider;
    use strict;
    use warnings;

    use Method::Traits ':for_providers';

    sub Accessor : OverwritesMethod {
        my ($meta, $method, $type, $slot_name) = @_;

        my $method_name = $method->name;

        $meta->add_method( $method_name => sub {
            die 'ro accessor' if $_[1];
            $_[0]->{$slot_name};
        })
            if $type eq 'ro';

        $meta->add_method( $method_name => sub {
            $_[0]->{$slot_name} = $_[1] if $_[1];
            $_[0]->{$slot_name};
        })
            if $type eq 'rw';
    }

=head1 DESCRIPTION

Traits are subroutines that are run at compile time to modify the
behavior of a method. This can be something as drastic as replacing
the method body, or something as unintrusive as simply tagging the
method with metadata.

=head2 TRAITS

A trait is simply a callback which is associated with a given
subroutine and fired during compile time.

=head2 How are traits registered?

Traits are registered via a mapping of trait providers, which
are just packages containing trait subroutines, and the class in
which you intend to apply the traits.

This is done by passing in the provider package name when using
the L<Method::Traits> package, like so:

    package My::Class;
    use Method::Traits 'My::Trait::Provider';

This will make available all the traits in F<My::Trait::Provider>
for use inside F<My::Class>.

=head2 How are traits associated?

Traits are associated to a subroutine using the "attribute" feature
of Perl. When the "attribute" mechanism is triggered for a given
method, we extract the name of the attribute and then attempt to
find a trait of that name in the associated providers.

This means that in the following code:

    package My::Class;
    use Method::Traits 'My::Trait::Provider';

    sub foo : SomeTrait { ... }

We will encounter the C<foo> method and see that it has the
C<SomeTrait> "attribute". We will then look to see if there is a
C<SomeTrait> trait available in the F<My::Trait::Provider>
provider, and if found, will call that trait.

=head2 How are traits called?

The traits are called immediately when the "attribute" mechanism
is triggered. The trait callbacks receieve at least two arguments,
the first being a L<MOP::Class> instance representing the
subroutine's package, the next being the L<MOP::Method> instance
representing the subroutine itself, and then, if there are any
arguments passed to the trait, they are also passed along.

=head1 UNDER CONSTRUCTION

This module is still heavily under construction and there is a high likielihood
that the details will change, bear that in mind if you choose to use it.

=head1 METHODS

These are all class methods.

=head2 C<add_trait_providers_for( $meta, @providers )>

This will register the given C<@providers> with the package
pointed to by C<$meta>, which is a L<MOP::Class> instance.

=head2 C<get_trait_providers_for( $meta )>

This will return any C<@providers> registered with the package
pointed to by C<$meta>, which is a L<MOP::Class> instance.

=head2 C<add_traits_for( $method, @traits ) >

This will associate the given C<@traits> with the method pointed
to by the C<$method>, which is a L<MOP::Method> instance.

=head2 C<get_traits_for( $method )>

This will return any C<@traits> associated with the method pointed
to by the C<$method>, which is a L<MOP::Method> instance.

=head1 PERL VERSION COMPATIBILITY

For the moment I am going to require 5.14.5 because of the following quote
by Zefram in the L<Sub::WhenBodied> documentation:

  Prior to Perl 5.15.4, attribute handlers are executed before the body
  is attached, so see it in that intermediate state. (From Perl 5.15.4
  onwards, attribute handlers are executed after the body is attached.)
  It is otherwise unusual to see the subroutine in that intermediate
  state.

I am also using the C<${^GLOBAL_PHASE}> variable, which was introduced in
5.14.

It likely is possible using L<Devel::GlobalPhase> and C<Sub::WhenBodied>
to actually implment this all for pre-5.14 perls, but for now I am not
going to worry about that.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
