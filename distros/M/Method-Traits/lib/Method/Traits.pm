package Method::Traits;
# ABSTRACT: Apply traits to your methods

use strict;
use warnings;

our $VERSION   = '0.08';
our $AUTHORITY = 'cpan:STEVAN';

use Carp            ();
use Scalar::Util    ();
use MOP             (); # this is how we do most of our work
use Module::Runtime (); # trait provider loading

## ...

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

## --------------------------------------------------------
## Trait collection
## --------------------------------------------------------

our %PROVIDERS_BY_PKG;

sub import_into {
    my (undef, $package, @providers) = @_;

    Carp::confess('You must provide a valid package argument')
        unless $package;

    Carp::confess('The package argument cannot be a reference or blessed object')
        if ref $package;

    Carp::confess('You must supply at least one provider')
        unless scalar @providers;

    # conver this into a metaobject
    my $meta = MOP::Role->new( $package );

    # load the providers, and then ...
    Module::Runtime::use_package_optimistically( $_ ) foreach @providers;

    # ... save the provider/package mapping
    push @{ $PROVIDERS_BY_PKG{ $meta->name } ||=[] } => @providers;

    # no need to install the collectors
    # if they have already been installed
    # as they are not different
    return
        if $meta->has_method_alias('FETCH_CODE_ATTRIBUTES')
        && $meta->has_method_alias('MODIFY_CODE_ATTRIBUTES');

    # now install the collectors ...

    my %accepted; # shared state between these two methods ...

    $meta->alias_method(
        FETCH_CODE_ATTRIBUTES => sub {
            my (undef, $code) = @_;
            # return just the strings, as expected by attributes ...
            return $accepted{ $code } ? @{ $accepted{ $code } } : ();
        }
    );
    $meta->alias_method(
        MODIFY_CODE_ATTRIBUTES => sub {
            my ($pkg, $code, @attrs) = @_;

            my @providers  = @{ $PROVIDERS_BY_PKG{ $pkg } ||=[] }; # fetch complete set
            my @attributes = map MOP::Method::Attribute->new( $_ ), @attrs;

            my ( %attr_to_handler_map, @unhandled );
            foreach my $attribute ( @attributes ) {
                my $name = $attribute->name;
                my $h; $h = $_->can( $name ) and last foreach @providers;
                if ( $h ) {
                    $attr_to_handler_map{ $name } = $h;
                }
                else {
                    push @unhandled => $attribute->original;
                }
            }

            # return the bad traits as strings, as expected by attributes ...
            return @unhandled if @unhandled;

            my $klass  = MOP::Role->new( $pkg );
            my $method = MOP::Method->new( $code );

            foreach my $attribute ( @attributes ) {
                my ($name, $args) = ($attribute->name, $attribute->args);
                my $h = $attr_to_handler_map{ $name };

                $h->( $klass, $method, @$args );

                if ( MOP::Method->new( $h )->has_code_attributes('OverwritesMethod') ) {
                    $method = $klass->get_method( $method->name );
                    Carp::croak('Failed to find new overwriten method ('.$method->name.') in class ('.$meta->name.')')
                        unless defined $method;
                }
            }

            # store the traits we applied ...
            $accepted{ $method->body } = [ map $_->original, @attributes ];

            return;
        }
    );
}

1;

__END__

=pod

=head1 NAME

Method::Traits - Apply traits to your methods

=head1 VERSION

version 0.08

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

=head1 PERL VERSION COMPATIBILITY

For the moment I am going to require 5.14.4 because of the following quote
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
