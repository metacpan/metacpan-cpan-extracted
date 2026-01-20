use 5.008008;
use strict;
use warnings;

package Marlin::Attribute;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.020000';

BEGIN { our @ISA = 'Sub::Accessor::Small' };

use constant HAS_CXSA => eval {
	require Class::XSAccessor;
	Class::XSAccessor->VERSION( 1.19 );
	1;
};

use B                     ();
use List::Util            ();
use Marlin                ();
use Marlin::Util          qw( true false );
use Scalar::Util          ();
use Sub::Accessor::Small  ();
use Types::Common         ();

my @ACCESSOR_KINDS = qw/ reader writer accessor clearer predicate /;

our $NONE = do {
	my $x = 'NONE';
	my $o = bless( \$x, 'Marlin::Attribute::NONE' );
	{
		package Marlin::Attribute::NONE;
		__PACKAGE__->Type::Tiny::_install_overloads(
			q("")    => sub { '(NONE)' },
			q(0+)    => sub { Scalar::Util::refaddr(shift) },
			q(bool)  => sub { 0 },
		);
	}
	Internals::SvREADONLY( $x, 1 );
	Internals::SvREADONLY( $o, 1 );
	$o;
};

sub new {
	my $class = shift;
	my $me = do {
		local *canonicalize_opts = sub {};
		$class->SUPER::new( @_ );
	};
	$me->_auto_apply_roles;
	$me->canonicalize_opts;
	Scalar::Util::weaken( $me->{marlin} );
	return $me;
}

sub make_clone {
	my $me = shift;
	
	defined &Clone::clone or require Clone;
	my $clone = Clone::clone( $me );
	
	# Clone shouldn't clone anything lexical!
	for my $kind ( @ACCESSOR_KINDS ) {
		exists $clone->{$kind} or next;
		delete $clone->{$kind} if ref $clone->{$kind};
		delete $clone->{$kind} if $clone->{$kind} =~ /^my\s/;
	}
	if ( $clone->{handles} ) {
		$clone->{handles} = {
			map  { @$_ }
			grep { not( ref $_->[0] or $_->[0] =~ /^my\s/ ) }
			List::Util::pairs( $clone->expand_handles )
		};
	}
	
	delete $clone->{_implementation};
	delete $clone->{inline_environment};
	
	return $clone;
}

sub make_clone_for_consuming_class {
	my ( $me, $marlin ) = @_;
	my $clone = $me->make_clone;
	$clone->{package} = $marlin->this;
	$clone->{marlin}  = $marlin;
	Scalar::Util::weaken( $clone->{marlin} );
	return $clone;
}

sub make_extended {
	my ( $me, $opts ) = @_;
	
	delete $opts->{slot};
	
	my $clone = $me->make_clone;
	$clone->{marlin}  = delete( $opts->{marlin} );
	$clone->{package} = delete( $opts->{package} ) || $clone->{marlin}->this;
	Scalar::Util::weaken( $clone->{marlin} );
	
	# Allow accessors to be ADDED but not changed.
	for my $kind ( @ACCESSOR_KINDS ) {
		next unless exists $opts->{$kind};
		if ( not defined $opts->{$kind} ) {
			delete $opts->{$kind};
			next;
		}
		if ( defined $clone->{$kind} and $clone->{$kind} ne $opts->{$kind} ) {
			Marlin::Util::_croak( "Attribute '%s' already has a %s: '%s'", $clone->{slot}, $kind, $clone->{$kind} );
		}
		$clone->{$kind} = delete $opts->{$kind};
	}
	
	# Handles needs to be merged.
	if ( ref $clone->{handles} and ref $opts->{handles} ) {
		my @pairs = List::Util::pairs( $clone->expand_handles );
		push @pairs, do {
			local $clone->{handles} = delete $opts->{handles};
			List::Util::pairs( $clone->expand_handles );
		};
		
		# Keep deduped list
		my %seen;
		$clone->{handles} = {
			map  { @$_ }
			reverse
			grep { not $seen{ $_->[0] }++  }
			reverse @pairs
		};
	}
	elsif ( ref $opts->{handles} ) {
		$clone->{handles} = delete $opts->{handles};
	}
	
	# Handles_via needs to be merged
	if ( $opts->{handles_via} ) {
		my $new = delete $opts->{handles_via};
		if ( not $clone->{handles_via} ) {
			$clone->{handles_via} = $new;
		}
		elsif ( ref $clone->{handles_via} ) {
			push @{ $clone->{handles_via} }, $new
				unless grep { $new eq $_ } @{ $clone->{handles_via} };
		}
		else {
			$clone->{handles_via} = [ $clone->{handles_via}, $new ]
				unless $new eq $clone->{handles_via};
		}
	}
	
	# These things can just always be straight-up changed.
	for my $option ( qw/ init_arg default builder trigger weak_ref undef_tolerant lazy documentation constant / ) {
		next unless exists $opts->{$option};
		$clone->{$option} = delete $opts->{$option};
	}
	
	# Can make an optional attribute required, but cannot make a required
	# attribute optional unless there's a default or builder.
	if ( $opts->{required} ) {
		$clone->{required} = delete $opts->{required};
	}
	elsif ( $clone->{required} and exists $opts->{required} ) {
		if ( exists $clone->{default} or defined $clone->{builder} ) {
			$clone->{required} = false;
		}
		else {
			Marlin::Util::_croak( "Attribute '%s' must have a default or builder if no longer required", $clone->{slot} );
		}
	}
	else {
		delete $opts->{required};
	}
	
	if ( $opts->{isa} ) {
		my $new_type = Types::Common::to_TypeTiny( delete $opts->{isa} );
		if ( $clone->{isa} and not $clone->{isa} == Types::Common::Any ) {
			if ( $new_type->is_a_type_of( $clone->{isa} ) ) {
				$clone->{isa} = $new_type;
			}
			else {
				$clone->{isa} = ( $clone->{isa} &+ $new_type );
			}
		}
		else {
			$clone->{isa} = $new_type;
		}
	}

	if ( $opts->{coerce} ) {
		$clone->{coerce} = delete $opts->{coerce};
	}
	elsif ( $clone->{coerce} and exists $opts->{coerce} ) {
		Marlin::Util::_croak( "Attribute '%s' cannot have coercion disabled", $clone->{slot} );
	}
	else {
		delete $opts->{coerce};
	}
	
	if ( my @bad = sort keys %$opts ) {
		Marlin::Util::_croak( "Attribute '%s' cannot change: %s", $clone->{slot}, join( q[, ], @bad ) );
	}
	
	for my $k ( keys %$clone ) {
		Scalar::Util::blessed( $clone->{$k} ) or next;
		delete $clone->{$k} if $clone->{$k} == $NONE;
	}
	
	do {
		# The original has already canonicalized 'is'.
		# If we do it again, we might end up adding
		# accessors that we don't want.
		local $clone->{is} = 'bare';
		$clone->canonicalize_opts;
	};
	$clone->{extended_from} = $me;
	return $clone;
}

sub _auto_apply_roles {
	my $me = shift;
	
	my @roles = grep { /\A:/ } sort keys %$me or return;
	
	require Role::Tiny;
	
	my @with;
	for my $role ( @roles ) {
		# Marlin::XAttribute::Alias functionality is now included
		# directly in Marlin::Attribute; skip attempt to load it.
		next if $role eq ':Alias';
		
		my $pkg  = "Marlin::XAttribute:$role";
		my $opts = $me->{$role};
		
		if ( Types::Common::is_HashRef( $opts ) and $opts->{try} ) {
			Marlin::Util::_maybe_load_module( $pkg );
			push @with, $pkg if Role::Tiny->is_role( $pkg );
		}
		else {
			Marlin::Util::_load_module( $pkg );
			push @with, $pkg;
		}
	}
	
	if ( @with ) {
		Role::Tiny->apply_roles_to_object( $me, @with );
	}
}

sub _croaker {
	my $me = shift;
	$me->{marlin} ? $me->{marlin}->_croaker( @_ ) : Marlin->_croaker( @_ );
}

sub accessor_kind  {
	my $me = shift;
	$me->{marlin} ? ref( $me->{marlin} ) : 'Marlin';
}

sub canonicalize_opts {
	my $me = shift;
	
	$me->canonicalize_constant;
	$me->canonicalize_alias;
	$me->SUPER::canonicalize_opts( @_ );
	$me->canonicalize_storage;
}

sub canonicalize_constant {
	my $me = shift;
	my $name = $me->{slot};
	
	if ( exists $me->{constant} ) {
		
		for my $opt ( qw/ writer predicate clearer builder default lazy trigger / ) {
			Marlin::Util::_croak("Option '$opt' does not make sense for a constant") if exists $me->{$opt};
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
				Marlin::Util::_croak("Coercion result for constant value does not pass its own type constraint");
			}
		}
		
		if ( ref $me->{constant} ) {
			Marlin::Util::_croak("Constant values must be non-references");
		}
		elsif ( not $me->$check($me->{constant}) ) {
			Marlin::Util::_croak("Constant value fails its own type constraint");
		}
		
		if ( defined $me->{init_arg} ) {
			Marlin::Util::_croak("Constants cannot have an init_arg defined");
		}
		$me->{init_arg} = undef;
		
		if ( defined $me->{storage} and $me->{storage} ne 'NONE' ) {
			Marlin::Util::_croak("Storage for constants must be NONE");
		}
		
		$me->{storage} = 'NONE';
		
		if ( !defined $me->{reader} and defined $name ) {
			$me->{reader} = $name;
		}
	}
}

sub canonicalize_alias {
	my $me = shift;
	if ( exists $me->{alias} and not defined $me->{alias} ) {
		delete $me->{alias};
	}
	if ( defined $me->{alias} and not ref $me->{alias} ) {
		$me->{alias} = [ $me->{alias} ];
	}
	if ( exists $me->{alias} ) {
		Marlin::Util::_croak("Not a valid value for the alias option: %s", defined($me->{alias}) ? $me->{alias} : 'undef' )
			unless 'ARRAY' eq ref $me->{alias};
		$me->{alias_for} ||= ( $me->{is} eq 'rw' ? 'accessor' : 'reader' );
	}
}

sub canonicalize_storage {
	my $me = shift;
	
	if ( not defined $me->{storage} ) {
		$me->{storage} = 'HASH';
	}
	
	if ( $me->{storage} eq 'NONE' ) {
		Marlin::Util::_croak("Attribute storage NONE only applies to constants")
			unless exists $me->{constant};
	}
	elsif ( $me->{storage} eq 'HASH' or $me->{storage} eq 'PRIVATE' ) {
		# This is fine
	}
	else {
		Marlin::Util::_croak("Unknown storage: " . $me->{storage});
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
		Marlin::Util::_croak("Failed to inline writer code for constant " . $me->{slot});
	}
	
	return $me->SUPER::inline_access_w( $selfvar, $val );
}

for my $type ( @ACCESSOR_KINDS ) {
	my $m = "has_simple_$type";
	my $orig = Sub::Accessor::Small->can($m);
	my $new = sub {
		my $me = shift;
		return false if $me->{storage} ne 'HASH';
		return $me->$orig( @_ );
	};
	no strict 'refs'; *$m = $new;
}

my %cxsa_map = (
	accessor   => 'accessors',
	reader     => 'getters',
	writer     => 'setters',
	predicate  => 'exists_predicates',
);

sub install_accessors {
	my $me = shift;

	if ( exists $me->{constant} ) {
		$me->install_constant;
	}
	else {
		my %args_for_cxsa;
		for my $type ( @ACCESSOR_KINDS ) {
			next unless defined $me->{$type};
			if ( $type eq 'reader' and !$me->${\"has_simple_$type"} and $me->xs_reader ) {
				$me->{_implementation}{$me->{$type}} = 'CXSR';
				next;
			}
			elsif ( HAS_CXSA and exists $cxsa_map{$type} and $me->${\"has_simple_$type"} and !ref $me->{$type} and $me->{$type} !~ /^my\s+/ ) {
				$args_for_cxsa{$cxsa_map{$type}}{$me->{$type}} = $me->{slot};
				$me->{_implementation}{$me->{$type}} = 'CXSA';
			}
			else {
				$me->install_coderef($me->{$type}, $me->$type);
				$me->{_implementation}{$me->{$type}} = 'Marlin';
			}
		}
		Class::XSAccessor->import( class => $me->{package}, replace => 1, %args_for_cxsa ) if keys %args_for_cxsa;
	}
	
	if ( my @aliases = @{ $me->{alias} or [] } ) {
		my $for = $me->{alias_for} || 'reader';
		my $coderef;
		if ( my $orig_method_name = $me->{$for} ) {
			no strict 'refs';
			$coderef = \&{ $me->{package} . "::$orig_method_name" };
		}
		if ( not $coderef ) {
			$coderef = $me->$for;
		}
		$me->install_coderef( $_, $coderef ) for @aliases;
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
				$me->{_implementation}{$target} ||= 'Marlin';
			}
		}
	}
}

sub provides_accessors {
	my $me = shift;
	
	my @list;
	
	if ( exists $me->{constant} ) {
		for my $kind ( 'reader' ) {
			push @list, [ $me->{$kind}, $kind, $me ] if $me->{$kind};
		}
	}
	else {
		for my $kind ( @ACCESSOR_KINDS ) {
			push @list, [ $me->{$kind}, $kind, $me ] if $me->{$kind};
		}
	}
	
	push @list, map [ $_, 'alias', $me ], @{ $me->{alias} or [] };
	
	if ( defined $me->{handles} ) {
		my @pairs = $me->expand_handles;
		while ( @pairs ) {
			my ( $name ) = splice( @pairs, 0, 2 );
			push @list, [ $name, 'delegated method', $me ];
		}
	}
	
	return @list;
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
		( $target, $me->{slot}, undef, undef, false );
	
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
		( $handler_slot, $is_accessor ) = ( $reader, true );
	}
	
	require Class::XSDelegation;
	$me->{_implementation}{$local_method} = 'CXSD';
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
	
	if ( HAS_CXSA and Sub::Accessor::Small::_is_bool($val) ) {
		Class::XSAccessor->import( class => $me->{package}, $val ? 'true' : 'false', [ $me->{reader} ] );
		$me->{_implementation}{$me->{reader}} = 'CSXA';
		return;
	}
	
	$me->{_implementation}{$me->{reader}} = 'Marlin';
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
		return $me->{marlin}->lexport( $lexname, $coderef );
	}
	
	return $me->SUPER::install_coderef( @_ );
}

sub allowed_constructor_parameters {
	my $me = shift;
	my @list;
	if ( exists $me->{init_arg} ) {
		return if !defined $me->{init_arg};
		push @list, $me->{init_arg};
	}
	else {
		push @list, $me->{slot};
	}
	push @list, @{ $me->{alias} or [] };
	return @list;
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
	$opt->{alias}    = $me->{alias}     if $me->{alias};
	
	$opt->{slot_initializer} = $me->{slot_initializer} if $me->{slot_initializer};
	$opt->{slot_initializer} = $me->writer if $me->{storage} ne 'HASH';
	$opt->{undef_tolerant}   = true if $me->{undef_tolerant};
	
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

__PACKAGE__
__END__
