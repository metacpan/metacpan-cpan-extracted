use 5.008008;
use strict;
use warnings;

package Marlin::Attribute;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.014000';

use parent 'Sub::Accessor::Small';

use B ();
use Class::XSAccessor ();
use Marlin ();
use Scalar::Util ();
use Types::Common ();

sub new {
	my $class = shift;
	my $me = $class->SUPER::new( @_ );
	$me->_auto_apply_roles;
	Scalar::Util::weaken( $me->{marlin} );
	return $me;
}

sub _auto_apply_roles {
	my $me = shift;
	
	my @roles = grep { /\A:/ } sort keys %$me or return;
	
	require Module::Runtime;
	require Role::Tiny;
	
	my @with;
	for my $role ( @roles ) {
		my $pkg  = "Marlin::XAttribute:$role";
		my $opts = $me->{$role};
		
		if ( Types::Common::is_HashRef( $opts ) and $opts->{try} ) {
			Module::Runtime::use_package_optimistically( $pkg );
			push @with, $pkg if Role::Tiny->is_role( $pkg );
		}
		else {
			Module::Runtime::require_module( $pkg );
			push @with, $pkg;
		}
	}
	
	if ( @with ) {
		Role::Tiny->apply_roles_to_object( $me, @with );
		$me->canonicalize_opts;
	}
}

sub _croaker {
	my $me = shift;
	$me->{_marlin} ? $me->{_marlin}->_croaker( @_ ) : Marlin->_croaker( @_ );
}

sub accessor_kind  {
	my $me = shift;
	return 'Marlin';
}

sub canonicalize_opts {
	my $me = shift;
	
	$me->canonicalize_constant;
	$me->SUPER::canonicalize_opts( @_ );
	$me->canonicalize_storage;
}

sub canonicalize_constant {
	my $me = shift;
	my $name = $me->{slot};
	
	if ( exists $me->{constant} ) {
		
		for my $opt ( qw/ writer predicate clearer builder default lazy trigger / ) {
			Carp::croak("Option '$opt' does not make sense for a constant") if exists $me->{$opt};
		}
		
		# Quickly do coercions and check type constraint if provided.
		my $check = $me->{isa}
			? eval sprintf( 'sub { eval { %s; 1 } }', $me->inline_type_coercion('$_[0]', '$_[1]') )
			: sub { 1 };
		if ( $me->{coerce} ) {
			my $coercion  = eval sprintf( 'sub { %s }', $me->inline_type_coercion('$_[0]', '$_[1]') );
			my $new_value = $me->$coercion( $me->{constant} );
			if ( $me->$check( $new_value ) ) {
				$me->{constant} = $new_value;
			}
			else {
				Carp::croak("Coercion result for constant value does not pass its own type constraint");
			}
		}
		
		if ( ref $me->{constant} ) {
			Carp::croak("Constant values must be non-references");
		}
		elsif ( not $me->$check($me->{constant}) ) {
			Carp::croak("Constant value fails its own type constraint");
		}
		
		if ( defined $me->{init_arg} ) {
			Carp::croak("Constants cannot have an init_arg defined");
		}
		$me->{init_arg} = undef;
		
		if ( defined $me->{storage} and $me->{storage} ne 'NONE' ) {
			Carp::croak("Storage for constants must be NONE");
		}
		
		$me->{storage} = 'NONE';
		
		if ( !defined $me->{reader} and defined $name ) {
			$me->{reader} = $name;
		}
	}
}

sub canonicalize_storage {
	my $me = shift;
	
	if ( not defined $me->{storage} ) {
		$me->{storage} = 'HASH';
	}
	
	if ( $me->{storage} eq 'NONE' ) {
		Carp::croak("Attribute storage NONE only applies to constants")
			unless exists $me->{constant};
	}
	elsif ( $me->{storage} eq 'HASH' or $me->{storage} eq 'PRIVATE' ) {
		# These are fine
	}
	else {
		Carp::croak("Unknown storage: " . $me->{storage});
	}
}

sub inline_access {
	my $me = shift;
	my $selfvar = shift || '$_[0]';
	
	if ( $me->{storage} eq 'HASH' ) {
		return sprintf( q[%s->{%s}], $selfvar, B::perlstring($me->{slot}) );
	}
	elsif ( $me->{storage} eq 'PRIVATE' ) {
		$me->SUPER::inline_access( $selfvar );
	}
	elsif ( $me->{storage} eq 'NONE' ) {
		return $me->inline_constant;
	}
	else {
		die;
	}
}

sub inline_access_w {
	my $me = shift;
	my $selfvar = shift || '$_[0]';
	my $val     = shift || '$_[1]';
	
	if ( $me->{storage} eq 'NONE' ) {
		Carp::croak("Failed to inline writer code for constant " . $me->{slot});
	}
	
	return $me->SUPER::inline_access_w( $selfvar, $val );
}

my %cxsa_map = (
	accessor   => 'accessors',
	reader     => 'getters',
	writer     => 'setters',
	predicate  => 'exists_predicates',
);

for my $type ( qw/accessor reader writer predicate clearer/ ) {
	my $m = "has_simple_$type";
	my $orig = Sub::Accessor::Small->can($m);
	my $new = sub {
		my $me = shift;
		return !!0 if $me->{storage} ne 'HASH';
		return $me->$orig( @_ );
	};
	no strict 'refs'; *$m = $new;
}

sub install_accessors {
	my $me = shift;

	if ( exists $me->{constant} ) {
		$me->install_constant;
	}
	else {
		my %args_for_cxsa;
		for my $type (qw( accessor reader writer predicate clearer )) {
			next unless defined $me->{$type};
			if ( $type eq 'reader' and !$me->${\"has_simple_$type"} and $me->xs_reader ) {
				next;
			}
			elsif ( exists $cxsa_map{$type} and $me->${\"has_simple_$type"} and !ref $me->{$type} and $me->{$type} !~ /^my\s+/ ) {
				$args_for_cxsa{$cxsa_map{$type}}{$me->{$type}} = $me->{slot};
			}
			else {
				$me->install_coderef($me->{$type}, $me->$type);
			}
		}
		Class::XSAccessor->import( class => $me->{package}, %args_for_cxsa ) if keys %args_for_cxsa;
	}

	if (defined $me->{handles}) {

		my $shv_data;
		if ($me->{traits} or $me->{handles_via}) {

			my @pairs = $me->expand_handles;
			my %handles_map;
			while ( @pairs ) {
				my ( $name ) = splice( @pairs, 0, 2 );
				$handles_map{"$name"} = $name;
			}

			require Sub::HandlesVia::Toolkit::SubAccessorSmall;
			my $SHV = 'Sub::HandlesVia::Toolkit::SubAccessorSmall'->new(
				attr => $me,
				handles_map => \%handles_map,
			);
			$shv_data = $SHV->clean_spec(
				$me->{package},
				$me->{slot},
				+{%$me},
			);
			$shv_data and $SHV->install_delegations( $shv_data );
		}

		if (!$shv_data) {
			my @pairs = $me->expand_handles;
			while (@pairs) {
				my ($target, $method) = splice(@pairs, 0, 2);
				$me->xs_delegation( $target, $method )
					or $me->install_coderef($target, $me->handles($method));
			}
		}
	}
}

sub xs_reader {
	my $me = shift;
	my $target = $me->{reader};
	return if !defined $target;
	return if ref $target;
	return if $target =~ /^my\s/;
	return if $me->{auto_deref};

	return if $me->{storage} ne 'HASH';
	
	require Class::XSConstructor;
	Class::XSConstructor::install_reader(
		$me->{package} . "::" . $target,
		$me->{slot},
		( exists $me->{default} or defined $me->{builder} ),
		exists( $me->{default} )
			? Class::XSConstructor::_common_default( $me->{default} )
			: 0,
		Class::XSConstructor->_canonicalize_defaults( $me ),
		Types::Common::is_TypeTiny( $me->{isa} )
			? Class::XSConstructor->_type_to_number( $me->{isa} )
			: Class::XSConstructor::XSCON_TYPE_OTHER(),
		ref( $me->{isa} ) eq 'CODE'
			? $me->{isa}
			: Types::Common::is_TypeTiny( $me->{isa} ) ? $me->{isa}->compiled_check : undef,
		ref( $me->{coerce} ) eq 'CODE'
			? $me->{coerce}
			: $me->{coerce} ? $me->{isa}->coercion->compiled_coercion : undef,
	);
	return 1;
}

sub xs_delegation {
	my ( $me, $target, $method ) = @_;
	
	return if !defined $target;
	return if ref $target;
	return if $target =~ /^my\s/;
	
	my ( $local_method, $handler_slot, $handler_method, $curried, $is_accessor ) =
		( $target, $me->{slot}, undef, undef, !!0 );
	
	if ( ref $method eq 'ARRAY' ) {
		( $handler_method, my @c ) = @$method;
		$curried = \@c;
	}
	elsif ( ref $method or not defined $method ) {
		return;
	}
	else {
		$handler_method = $method;
	}
	
	return if ref $handler_method;
	
	if ( $me->inline_reader ne $me->inline_get or $me->{storage} ne 'HASH' ) {
		my $reader = $me->{reader} || $me->{accessor};
		return if !defined $reader;
		return if ref $reader;
		return if $reader =~ /^my\s/;
		( $handler_slot, $is_accessor ) = ( $reader, !!1 );
	}
	
	require Class::XSDelegation;
	Class::XSDelegation->import( \$me->{package}, [
		$local_method,
		$handler_slot,
		$handler_method,
		{ curry => $curried, is_accessor => $is_accessor },
	] );
	return 1;
}

sub install_constant {
	my $me = shift;
	my $val = $me->{constant};
	
	if ( Sub::Accessor::Small::_is_bool($val) ) {
		Class::XSAccessor->import( class => $me->{package}, $val ? 'true' : 'false', [ $me->{reader} ] );
		return;
	}
	
	my $code = $me->inline_constant;
	$me->install_coderef( $me->{reader}, eval "sub () { $code }" );
}

sub inline_constant {
	my $me  = shift;
	my $val = @_ ? shift : $me->{constant};
	
	require B;
	return
		!defined($val)                                 ? 'undef' :
		Sub::Accessor::Small::_is_bool($val)           ? ( $val ? '!!1' : '!!0' ) :
		Sub::Accessor::Small::_created_as_number($val) ? ( 0 + $val ) : B::perlstring($val);
}

sub install_coderef {
	my $me = shift;
	my ( $target, $coderef ) = @_;
	
	if ( $target =~ /^my\s+(.+)$/ ) {
		my $lexname = $1;
		$me->{_marlin}->lexport( $lexname, $coderef );
	}
	
	return $me->SUPER::install_coderef( @_ );
}

sub allowed_constructor_parameters {
	my $me = shift;
	if ( exists $me->{init_arg} ) {
		return if !defined $me->{init_arg};
		return $me->{init_arg};
	}
	return $me->{slot};
}

sub xs_constructor_args {
	my $me = shift;
	
	return if $me->{storage} eq 'NONE';
	
	my $name = $me->{slot};
	my $req  = $me->{required} ? '!' : '';
	
	my $opt  = {};
	$opt->{isa}      = $me->{isa}       if defined $me->{isa};
	$opt->{coerce}   = 1                if Scalar::Util::blessed($me->{isa}) && $me->{coerce} && !ref $me->{coerce};
	$opt->{coerce}   = $me->{coerce}    if ref $me->{coerce};
	$opt->{default}  = $me->{default}   if !$me->{lazy} && exists $me->{default};
	$opt->{builder}  = $me->{builder}   if !$me->{lazy} && defined $me->{builder};
	$opt->{init_arg} = $me->{init_arg}  if exists $me->{init_arg};
	$opt->{trigger}  = $me->{trigger}   if $me->{trigger};
	$opt->{weak_ref} = $me->{weak_ref}  if $me->{weak_ref};
	
	$opt->{slot_initializer} = $me->{slot_initializer} if $me->{slot_initializer};
	$opt->{slot_initializer} = $me->writer if $me->{storage} ne 'HASH';
	$opt->{undef_tolerant}   = !!1 if $me->{undef_tolerant};
	
	return ( $name . $req => $opt );
}

sub _moose_safe_default {
	my $me = shift;
	
	if ( $INC{'Sub/Quote.pm'} ) {
		return Sub::Quote::quote_sub( q{ +{} } ) if Types::Common::is_HashRef( $me->{default} );
		return Sub::Quote::quote_sub( q{ +[] } ) if Types::Common::is_ArrayRef( $me->{default} );
		return Sub::Quote::quote_sub( ${ $me->{default} } ) if Types::Common::is_ScalarRef( $me->{default} );
	}
	else {
		return sub { +{} } if Types::Common::is_HashRef( $me->{default} );
		return sub { +[] } if Types::Common::is_ArrayRef( $me->{default} );
		return eval qq{ sub { ${ $me->{default} } } } if Types::Common::is_ScalarRef( $me->{default} );
	}
	
	return $me->{default};
}

# This method does nothing, but is a hook for extensions.
# It is safer to wrap this (using CMM) than to wrap
# inject_moose(role?)_metadata or inject_moo(role?)_metadata
# which might not be loaded yet!
sub injected_metadata {
	my ( $me, $framework, $metadata ) = @_;
	return $metadata;
}

# Ditto
sub injected_accessor_metadata {
	my ( $me, $framework, $metadata ) = @_;
	return $metadata;
}

1;