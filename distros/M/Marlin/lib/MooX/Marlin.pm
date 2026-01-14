use 5.008008;
use strict;
use warnings;

package MooseX::Marlin;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.014000';

use Marlin ();
use Moo 2.004000;
use Moo::Role ();

BEGIN {
	eval {
		require PerlX::Maybe;
		*_maybe = \&PerlX::Maybe::maybe;
	} or eval q{
		sub _maybe ($$@) {
			if ( defined $_[0] and defined $_[1] ) {
				return @_;
			}
			(scalar @_ > 1) ? @_[2 .. $#_] : qw();
		}
	};
};

$_->inject_moo_metadata for values %Marlin::META;

sub import {
	no strict 'refs';
	my $class = shift;
	my $caller = caller;
	
	Moo->is_class( $caller )
		or Moo::Role->is_role( $caller )
		or Marlin::_croak("Package '$caller' does not use Moo");
}

sub Marlin::inject_moo_metadata {
	my $me = shift;
	
	# Recurse to any parents or roles
	for my $pkg ( @{ $me->parents }, @{ $me->roles } ) {
		Module::Runtime::use_package_optimistically( $pkg->[0] );
		Marlin->find_meta( $pkg->[0] )->inject_moo_metadata;
	}
	
	require Moo;
	require Method::Generate::Accessor;
	require Method::Generate::Constructor;
	my $makers = ( $Moo::MAKERS{$me->this} ||= {} );
	$makers->{is_class} = 1;
	$makers->{accessor} = Method::Generate::Accessor->new;
	$makers->{constructor} = Method::Generate::Constructor->new(
		package              => $me->this,
		accessor_generator   => $makers->{accessor},
	);
	
	for my $attr ( @{ $me->attributes } ) {
		$attr->inject_moo_metadata($makers) or next;
	}
	
	return $me->injected_metadata( Moo => $makers );
}

sub Marlin::Role::inject_moo_metadata {
	my $me = shift;
	
	# Recurse to any parents or roles
	for my $pkg ( @{ $me->parents }, @{ $me->roles } ) {
		Module::Runtime::use_package_optimistically( $pkg->[0] );
		Marlin->find_meta( $pkg->[0] )->inject_moo_metadata;
	}
	
	require Moo::Role;
	require Method::Generate::Accessor;
	my $makers = ( $Moo::Role::INFO{$me->this} ||= {} );
	$makers->{is_role} = 1;
	$makers->{accessor_maker} = Method::Generate::Accessor->new;
	
	for my $attr ( @{ $me->attributes } ) {
		$attr->inject_moorole_metadata($makers) or next;
	}
	
	return $me->injected_metadata( Moo => $makers );
}

sub Marlin::Attribute::inject_moo_metadata {
	my ( $me, $makers ) = @_;
	
	my $tc = $me->{isa} ? Types::Common::to_TypeTiny( $me->{isa} ) : Types::Common::Any();
	if ( Types::Common::is_CodeRef( $me->{coerce} ) and Types::Common::is_TypeTiny( $tc ) ) {
		$tc = $tc->plus_coercions( Types::Common::Any(), $me->{coerce} );
	}

	my %spec = (
		definition_context  => { context => "Marlin import", package => $me->{package}, toolkit => ref($me->{_marlin}), type => $makers->{is_role} ? 'role' : 'class' },
		is                  => $me->{is} || 'bare',
		init_arg            => exists( $me->{init_arg} ) ? $me->{init_arg} : $me->{slot},
		required            => !!$me->{required},
		type_constraint     => $tc,
		coerce              => !!$me->{coerce},
		_maybe reader       => $me->{reader},
		_maybe writer       => $me->{writer},
		_maybe accessor     => $me->{accessor},
		_maybe predicate    => $me->{predicate},
		_maybe clearer      => $me->{clearer},
		_maybe trigger      => $me->{trigger},
		_maybe builder      => $me->{builder},
		exists( $me->{default} ) ? ( default => $me->_moose_safe_default ) : (),
		lazy                => !!$me->{lazy},
		weak_ref            => !!$me->{weak_ref},
	);
	
	if ( $makers->{constructor} ) {
		no warnings 'redefine';
		local *Method::Generate::Constructor::assert_constructor = sub {};
		$makers->{constructor}->register_attribute_specs( $me->{slot}, \%spec );
	}
	
	if ( $makers->{is_role} ) {
		push @{ $makers->{attributes} ||= [] }, $me->{slot}, \%spec;
	}
	
	return $me->injected_metadata( Moo => [ $makers, $me->{slot}, \%spec ] );
}

sub Marlin::Attribute::inject_moorole_metadata {
	shift->inject_moo_metadata( @_ );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooX::Marlin - 🐮 ❤️ 🐟 inherit from Marlin classes in Moo

=head1 SYNOPSIS

  use v5.20.0;
  no warnings "experimental::signatures";
  
  package Person {
    use Types::Common -lexical, -all;
    use Marlin::Util -lexical, -all;
    use Marlin
      'name'  => { is => ro, isa => Str, required => true },
      'age'   => { is => rw, isa => Int, predicate => true };
  }
  
  package Employee {
    use Moo;
    use MooX::Marlin;
    extends 'Person';
    
    has employee_id => ( is => 'ro', required => 1 );
  }

=head1 WARNING

This appears to work, but it is not thoroughly tested.

=head1 DESCRIPTION

Loading this class will do a few things:

=over

=item *

Ensures you are using at least Moo 2.004000 (released in April 2020).

=item *

Loop through all Marlin classes and roles which have already been defined
(also any foreign classes like Class::Tiny ones which Marlin has learned
about by inheritance, etc) and inject metadata about them into Moo's innards,
enabling them to be used by Moo.

=item *

Tells Marlin to keep injecting metadata into Moo's innards for any Marlin
classes or roles that are loaded later.

=item *

Checks that the caller package is a Moo class or Moo role, and
complains otherwise. (Make sure to C<< use Moo >> or C<< use Moo::Role >>
I<before> you C<< use Moo::Marlin >>!)

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin/issues>.

=head1 SEE ALSO

L<Marlin>, L<Moo>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
