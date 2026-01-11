use 5.008008;
use strict;
use warnings;

package Marlin::Attribute;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.011002';

use parent 'Sub::Accessor::Small';

use B ();
use Class::XSAccessor ();
use Marlin ();
use Scalar::Util ();
use Types::Common ();

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

sub requires_pp_constructor {
	my $me = shift;
	return !!1 unless $me->{storage} eq 'NONE' || $me->{storage} eq 'HASH';
	return !!0;
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
	my $slot = $me->{slot};
	
	require Class::XSConstructor;
	
	my $has_common_default = 0;
	do {
		my $spec = $me;
		if ( exists $spec->{default} and !defined $spec->{default} ) {
			$has_common_default = 1;
		}
		elsif ( exists $spec->{default} and Class::XSConstructor::_created_as_number( $spec->{default} ) and $spec->{default} == 0 ) {
			$has_common_default = 2;
		}
		elsif ( exists $spec->{default} and Class::XSConstructor::_created_as_number( $spec->{default} ) and $spec->{default} == 1 ) {
			$has_common_default = 3;
		}
		elsif ( exists $spec->{default} and Class::XSConstructor::_is_bool( $spec->{default} ) and !$spec->{default} ) {
			$has_common_default = 4;
		}
		elsif ( exists $spec->{default} and Class::XSConstructor::_is_bool( $spec->{default} ) and $spec->{default} ) {
			$has_common_default = 5;
		}
		elsif ( exists $spec->{default} and Class::XSConstructor::_created_as_string( $spec->{default} ) and $spec->{default} eq '' ) {
			$has_common_default = 6;
		}
		elsif ( exists $spec->{default} and Class::XSConstructor::is_ScalarRef( $spec->{default} ) and ${$spec->{default}} eq '[]' ) {
			$has_common_default = 7;
		}
		elsif ( exists $spec->{default} and Class::XSConstructor::is_ScalarRef( $spec->{default} ) and ${$spec->{default}} eq '{}' ) {
			$has_common_default = 8;
		}
	};
	
	Class::XSConstructor::install_reader(
		$me->{package} . "::" . $target,
		$me->{slot},
		( exists $me->{default} or defined $me->{builder} ),
		$has_common_default,
		Class::XSConstructor->_canonicalize_defaults( $me ),
		Types::Common::is_TypeTiny($me->{isa}) ? Class::XSConstructor->_type_to_number($me->{isa}) : Class::XSConstructor::XSCON_TYPE_OTHER(),
		ref($me->{isa}) eq 'CODE' ? $me->{isa} : Types::Common::is_TypeTiny($me->{isa}) ? $me->{isa}->compiled_check : undef,
		ref($me->{coerce}) eq 'CODE' ? $me->{coerce} : $me->{coerce} ? $me->{isa}->coercion->compiled_coercion : undef,
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

# Mostly cribbed from Mite
sub add_code_for_initialization {
	my $me = shift;
	my $code = shift;
	
	my $init_arg = defined($me->{init_arg}) ? $me->{init_arg} : $me->{slot};

	my $D = do {
		my $var = ref($me->{default}) eq 'CODE'
			? $code->add_variable( '$default_for_' . $me->{slot}, \$me->{default} )
			: 'DUMMY';
		$me->inline_default( '$self', $var );
	};
	
	if ( defined $me->{init_arg} or not exists $me->{init_arg} ) {
		my ( $C, $P ) = ( '', '' );
		my $V = sprintf '$args{%s}', B::perlstring($init_arg);
		my $T = do {
			if ( $me->{trigger} ) {
				sub {
					$code->add_variable( $me->make_var_name('trigger'), \$me->{trigger} );
					$me->inline_trigger('$self');
				},
			}
			else {
				sub { '' };
			}
		};
		my $N = 1;
		
		if ( ( exists $me->{default} or exists $me->{builder} ) and not $me->{lazy} ) {
			if ( $me->{isa} ) {
				$C = sprintf 'do { my $value = exists( %s ) ? %s : %s; ', $V, $V, $D;
				$V = '$value';
				$P = "}; $P";
			}
			else {
				$V = sprintf '( exists( %s ) ? %s : %s )', $V, $V, $D;
			}
			$P = $T->() . $P;
		}
		elsif ( $me->{required} and not $me->{lazy} ) {
			$code->addf( '%s("Missing key in constructor: %s") unless exists %s;', $me->_croaker, $init_arg, $V);
		}
		else {
			$C .= sprintf 'if ( exists %s ) { ', $V;
			$P = $T->() . '}' . $P;
		}
		
		if ( $N and my $type = $me->{isa} ) {
			if ( $me->{coerce} ) {
				if ( $type->can('coercion') and $type->coercion->can('can_be_inlined') and $type->coercion->can_be_inlined ) {
					$C .= sprintf 'do { my $to_coerce = %s; my $coerced_value = do { %s }; ', $V, $type->coercion->inline_coercion( '$to_coerce' );
				}
				elsif ( $type->can('coerce') ) {
					my $var = $code->add_variable( '$type_for_' . $me->{slot}, \$type );
					$C .= sprintf 'do { my $coerced_value = %s->coerce( %s ); ', $var, $V;
				}
				$V = '$coerced_value';
				$P = "}; $P";
			}
			$C .= sprintf '%s or %s("Type check failed in constructor: %%s should be %%s", %s, %s); ',
				do {
					if ( $type->can_be_inlined ) {
						$type->inline_check($V);
					}
					elsif ( $type->can('compiled_check') ) {
						my $var = $code->add_variable( '$check_for_' . $me->{slot}, \$type->compiled_check );
						sprintf '%s->( %s )', $var, $V;
					}
					else {
						my $var = $code->add_variable( '$type_for_' . $me->{slot}, \$type );
						sprintf '%s->check( %s )', $var, $V;
					}
				},
				$me->_croaker,
				B::perlstring($init_arg),
				B::perlstring($type->display_name);
		}
		$C .= sprintf '%s; ', $me->inline_access_w('$self', $V);
	
		$code->add_line( $C . $P );
	}
	elsif ( ( exists $me->{default} or exists $me->{builder} ) and not $me->{lazy} ) {
		$code->add_line( $me->inline_access_w( '$self', $D ) . ';' );
	}
	
	$code->add_line( $me->inline_weaken('$self') ) if $me->{weak_ref};
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
	
	return unless $me->{storage} eq 'HASH';
	
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

sub inject_moose_metadata {
	my $me = shift;
	my $metaclass = shift;
	
	my $tc = $me->{isa} ? Types::Common::to_TypeTiny( $me->{isa} ) : Types::Common::Any();
	if ( Types::Common::is_CodeRef( $me->{coerce} ) and Types::Common::is_TypeTiny( $tc ) ) {
		$tc = $tc->plus_coercions( Types::Common::Any(), $me->{coerce} );
	}
	
	require Moose;
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
	}
	
	do {
		no warnings 'redefine';
		local *Moose::Meta::Attribute::install_accessors = sub {};
		$metaclass->add_attribute( $attr );
	};
	
	return $attr;
}

sub inject_mooserole_metadata {
	my $me = shift;
	my $metarole = shift;

	my $tc = $me->{isa} ? Types::Common::to_TypeTiny( $me->{isa} ) : Types::Common::Any();
	if ( Types::Common::is_CodeRef( $me->{coerce} ) and Types::Common::is_TypeTiny( $tc ) ) {
		$tc = $tc->plus_coercions( Types::Common::Any(), $me->{coerce} );
	}
	
	require Moose;
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
	}
	
	$metarole->add_attribute( $attr );
	
	return $attr;
}

sub inject_moo_metadata {
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
	
	return \%spec;
}

sub inject_moorole_metadata {
	shift->inject_moo_metadata( @_ );
}

1;