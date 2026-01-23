use 5.008008;
use strict;
use warnings;

package MooseX::Marlin;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.021000';

use Marlin                ();
use Marlin::Util          ();
use Moose 2.2004          ();
use Moose::Object         ();
use Moose::Util           ();
use Scalar::Util          ();
use Types::Common         ();

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

$_->inject_moose_metadata for values %Marlin::META;

sub import {
	no strict 'refs';
	my $class = shift;
	my $caller = caller;
	
	my $caller_meta = Moose::Util::find_meta($caller)
		or Marlin::Util::_croak("Package '$caller' does not use Moose");
	
	if ( $caller_meta->isa('Class::MOP::Class') ) {
		for my $method ( qw/ new does BUILDARGS BUILDALL DEMOLISHALL DESTROY / ) {	
			if ( not exists &{"${caller}::${method}"} ) {
				*{"${caller}::${method}"} = \&{"Moose::Object::${method}"};
			}
		}
	}
	
	Marlin->find_meta( $_ ) for @_;
}

my $made_shim = 0;
sub Marlin::inject_moose_metadata {
	my $me = shift;
	
	if ( $me->this eq 'Marlin' or $me->this eq 'Marlin::Role' ) {
		# return;
	}
	
	# Recurse to any parents or roles
	for my $pkg ( @{ $me->parents }, @{ $me->roles } ) {
		Marlin::Util::_maybe_load_module( $pkg->[0] );
		if ( my $m = Marlin->find_meta( $pkg->[0] ) ) {
			$m->inject_moose_metadata unless $m == $me;
		}
	}
	
	return if Moose::Util::find_meta( $me->this );
	
	eval q{{{
		package Marlin::Meta::Class;
		use Moose;
		extends 'Moose::Meta::Class';
		around _immutable_options => sub {
			my ( $next, $self, @args ) = ( shift, shift, @_ );
			return $self->$next( replace_constructor => 1, @args );
		};
		__PACKAGE__->meta->make_immutable;
		1;
	}}} unless $made_shim++;
	
	my $metaclass = Marlin::Meta::Class->initialize( $me->this, package => $me->this );
	
	require Class::MOP;
	Class::MOP::store_metaclass_by_name( $me->this, $metaclass );
	
	$me->canonicalize_attributes;
	for my $attr ( @{ $me->attributes } ) {
		$attr->inject_moose_metadata($metaclass) or next;
	}
	
	$metaclass->superclasses( map $_->[0], @{ $me->parents } );
	
	require Moose::Util::TypeConstraints;
	my $tc = Moose::Util::TypeConstraints::find_or_create_isa_type_constraint( $me->this );
	my $tt = $me->make_type_constraint( $me->short_name );
	$tc->{coercion} = $tt->coercion->moose_coercion if $tt->has_coercion;
	
	return $me->injected_metadata( Moose => $metaclass );
}

sub Marlin::Role::inject_moose_metadata {
	my $me = shift;
	
	# Recurse to other roles
	for my $pkg ( @{ $me->roles } ) {
		Marlin::Util::_maybe_load_module( $pkg->[0] );
		if ( my $m = Marlin->find_meta( $pkg->[0] ) ) {
			$m->inject_moose_metadata unless $m == $me;
		}
	}
	
	return if Moose::Util::find_meta( $me->this );
	
	require Moose::Meta::Role;
	my $metarole = Moose::Meta::Role->initialize( $me->this );
	
	require Class::MOP;
	Class::MOP::store_metaclass_by_name( $me->this, $metarole );
	
	$me->canonicalize_attributes;
	for my $attr ( @{ $me->attributes } ) {
		$attr->inject_mooserole_metadata( $metarole ) or next;
	}
	
	require Moose::Util::TypeConstraints;
	my $tc = Moose::Util::TypeConstraints::find_or_create_isa_type_constraint( $me->this );
	$tc->{coercion} = $me->make_type_constraint( $me->this )->coercion->moose_coercion;
	
	return $me->injected_metadata( Moose => $metarole );
}

my $missing_mxa_warning;
sub INJECT_ALIASES {
	my ( $me, $meta_attr ) = @_;
	
	if ( not eval { require MooseX::Aliases; 1 } ) {
		if ( not $missing_mxa_warning++ ) {
			require Carp;
			Carp::carp('MooseX::Aliases is not installed');
		}
		return;
	}
	
	require Moose::Util;
	if ( $meta_attr->can('associated_role') ) {
		Moose::Util::ensure_all_roles(
			Moose::Util::find_meta($meta_attr->associated_role),
			'MooseX::Aliases::Meta::Trait::Role',
		);
	}
	else {
		my $meta = Moose::Util::find_meta($meta_attr->associated_class);
		$meta->make_mutable;
		Moose::Util::ensure_all_roles(
			$meta,
			'MooseX::Aliases::Meta::Trait::Class',
		);
		$meta->make_immutable;
	}
	
	Moose::Util::ensure_all_roles(
		$meta_attr,
		'MooseX::Aliases::Meta::Trait::Attribute',
	);
	
	$meta_attr->{alias} = [ @{ $me->{alias} } ];
};

sub Marlin::Attribute::inject_moose_metadata {
	my $me = shift;
	my $metaclass = shift;
	
	my $tc = $me->{isa} ? Types::Common::to_TypeTiny( $me->{isa} ) : Types::Common::Any();
	if ( Types::Common::is_CodeRef( $me->{coerce} ) and Types::Common::is_TypeTiny( $tc ) ) {
		$tc = $tc->plus_coercions( Types::Common::Any(), $me->{coerce} );
	}
	
	require Moose::Meta::Attribute;
	require Moose::Meta::Method::Accessor;
	
	my $attr = Moose::Meta::Attribute->new(
		$me->{slot},
		__hack_no_process_options => !!1,
		associated_class    => $me->{package},
		definition_context  => { context => "Marlin import", package => $me->{package}, toolkit => ref($me->{_marlin}), type => 'class' },
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
	
	for my $kind ( qw/ reader writer accessor predicate clearer / ) {
		no strict 'refs';
		my $method = $me->{$kind} or next;
		my $accessor = Moose::Meta::Method::Accessor->_new(
			accessor_type => $kind,
			attribute => $attr,
			name => $me->{slot},
			body => defined( &{ $me->{package} . "::$method" } ) ? \&{ $me->{package} . "::$method" } : $me->$kind,
			package_name => $me->{package},
			definition_context => +{ %{ $attr->{definition_context} } },
		);
		Scalar::Util::weaken( $accessor->{attribute} );
		$attr->associate_method( $accessor );
		$metaclass->add_method( $accessor->name, $accessor );
		$me->injected_accessor_metadata( Moose => $accessor );
	}
	
	do {
		no warnings 'redefine';
		local *Moose::Meta::Attribute::install_accessors = sub {};
		$metaclass->add_attribute( $attr );
	};
	
	INJECT_ALIASES( $me, $attr ) if $me->{alias};
	
	return $me->injected_metadata( Moose => $attr );
}

sub Marlin::Attribute::inject_mooserole_metadata {
	my $me = shift;
	my $metarole = shift;

	my $tc = $me->{isa} ? Types::Common::to_TypeTiny( $me->{isa} ) : Types::Common::Any();
	if ( Types::Common::is_CodeRef( $me->{coerce} ) and Types::Common::is_TypeTiny( $tc ) ) {
		$tc = $tc->plus_coercions( Types::Common::Any(), $me->{coerce} );
	}
	
	require Moose::Meta::Role::Attribute;
	require Moose::Meta::Method::Accessor;
	
	my $attr = Moose::Meta::Role::Attribute->new(
		$me->{slot},
		__hack_no_process_options => !!1,
		associated_class    => $me->{package},
		definition_context  => { context => "Marlin import", package => $me->{package}, toolkit => ref($me->{_marlin}), type => 'role' },
		is                  => $me->{is} || 'bare',
		init_arg            => exists( $me->{init_arg} ) ? $me->{init_arg} : $me->{slot},
		required            => !!$me->{required},
		isa                 => $tc,
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
	
	for my $kind ( qw/ reader writer accessor predicate clearer / ) {
		no strict 'refs';
		my $method = $me->{$kind} or next;
		my $accessor = Moose::Meta::Method::Accessor->_new(
			accessor_type => $kind,
			attribute => $attr,
			name => $me->{slot},
			body => defined( &{ $me->{package} . "::$method" } ) ? \&{ $me->{package} . "::$method" } : $me->$kind,
			package_name => $me->{package},
			definition_context => +{ %{ $attr->{definition_context} } },
		);
		Scalar::Util::weaken( $accessor->{attribute} );
		$metarole->add_method( $accessor->name, $accessor );
		$me->injected_accessor_metadata( Moose => $accessor );
	}
	
	$metarole->add_attribute( $attr );
	
	INJECT_ALIASES( $me, $attr ) if $me->{alias};
	
	return $me->injected_metadata( Moose => $attr );
}

__PACKAGE__
__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::Marlin - 🫎 ❤️ 🐟 inherit from Marlin classes in Moose

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
    use Moose;
    use MooseX::Marlin;
    extends 'Person';
    
    has employee_id => ( is => 'ro', isa => 'Int', required => 1 );
  }

=head1 WARNING

This appears to work, but it is not thoroughly tested.

=head1 DESCRIPTION

Loading this class will do a few things:

=over

=item *

Ensures you are using at least Moose 2.2004 (released in January 2017).

=item *

Loop through all Marlin classes and roles which have already been defined
(also any foreign classes like Class::Tiny ones which Marlin has learned
about by inheritance, etc) and inject metadata about them into Class::MOP,
enabling them to be used by Moose.

=item *

Tells Marlin to keep injecting metadata into Class::MOP for any Marlin
classes or roles that are loaded later.

=item *

Checks that the caller package is a Moose class or Moose role, and
complains otherwise. (Make sure to C<< use Moose >> or C<< use Moose::Role >>
I<before> you C<< use MooseX::Marlin >>!)

=item *

Imports C<new>, C<does>, C<BUILDARGS>, C<BUILDALL>, and C<DEMOLISHALL>
from L<Moose::Object> into the caller package, if the caller package is
a Moose class.

=back

It is possible to list additional foreign classes on the
C<< use MooseX::Marlin >> line to force Marlin to learn about them.
This can allow Moose to inherit some non-Moose classes, like classes
built by L<Mouse> or L<Class::Tiny>.

In the following example C<< use MooseX::Marlin qw( Local::Squeak ) >>
not only allows C<Local::Squash> to inherit from Marlin classes, but
also disguises C<Local::Squeak> as a Marlin class. (Moose cannot
normally inherit from Mouse classes!)

  BEGIN {
    package Local::Squeak;
    use Mouse;
    has squeak => ( is => 'ro', isa => 'Int' );
  };
  
  BEGIN {
    package Local::Squash;
    use Moose;
    
    use MooseX::Marlin qw( Local::Squeak );
    extends 'Local::Squeak';
    
    has squash => ( is => 'ro', isa => 'Int' );
    __PACKAGE__->meta->make_immutable;
  };
  
  use Data::Dumper;
  
  $Data::Dumper::Deparse = 1;
  print Dumper( Local::Squash->can('new') );
  
  my $o = Local::Squash->new( squeak => 1, squash => 2 );
  print Dumper( $o );

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin/issues>.

=head1 SEE ALSO

L<Marlin>, L<Moose>.

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
