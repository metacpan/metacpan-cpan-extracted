use 5.008008;
use strict;
use warnings;

package Marlin::Attribute;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006001';

use parent 'Sub::Accessor::Small';
use B ();
use Class::XSAccessor ();
use Marlin ();

sub _croaker {
	shift;
	Marlin->_croaker( @_ );
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
			if ( exists $cxsa_map{$type} and $me->${\"has_simple_$type"} and !ref $me->{$type} and $me->{$type} !~ /^my\s+/ ) {
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
				$me->install_coderef($target, $me->handles($method));
			}
		}
	}
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
		if ( Marlin::_HAS_NATIVE_LEXICAL_SUB ) {
			no warnings ( "$]" >= 5.037002 ? 'experimental::builtin' : () );
			builtin::export_lexically( $lexname, $coderef );
			return;
		}
		elsif ( Marlin::_HAS_MODULE_LEXICAL_SUB ) {
			'Lexical::Sub'->import( $lexname, $coderef );
			return;
		}
		else {
			$target = $lexname;
		}
	}
	
	return $me->SUPER::install_coderef( @_ );
}

# Mostly cribbed from Mite
sub _compile_init {
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

1;