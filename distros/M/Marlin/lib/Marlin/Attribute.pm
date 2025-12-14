use 5.008008;
use strict;
use warnings;

package Marlin::Attribute;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002002';

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

sub inline_access {
	my $me = shift;
	my $selfvar = shift || '$_[0]';
	sprintf( q[%s->{%s}], $selfvar, B::perlstring($me->{slot}) );
}

sub requires_pp_constructor {
	my $me = shift;
	return !!0 if !defined $me->{init_arg};
	return !!1 if $me->{init_arg} ne $me->{slot};
	return !!1 if $me->{coerce};
	return !!1 if $me->{weak_ref};
	return !!1 if exists $me->{trigger};
	unless ( $me->{lazy} ) {
		return !!1 if exists $me->{default};
		return !!1 if exists $me->{builder};
	}
	return !!0;
}

my %cxsa_map = (
	accessor   => 'accessors',
	reader     => 'getters',
	writer     => 'setters',
	predicate  => 'exists_predicates',
);

sub install_accessors {
	my $me = shift;

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
				sub { sprintf '$self->%s(%s)', $me->{trigger}, join q{, }, @_ }
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
			$P = $T->(sprintf '$self->{%s}', B::perlstring($me->{slot})) . $P;
		}
		elsif ( $me->{required} and not $me->{lazy} ) {
			$code->addf( '%s("Missing key in constructor: %s") unless exists %s;', $me->_croaker, $init_arg, $V);
		}
		else {
			$C .= sprintf 'if ( exists %s ) { ', $V;
			$P = $T->(sprintf '$self->{%s}', B::perlstring($me->{slot})) . '}' . $P;
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
		$C .= sprintf '$self->{%s} = %s; ', B::perlstring($me->{slot}), $V;
	
		$code->add_line( $C . $P );
	}
	elsif ( ( exists $me->{default} or exists $me->{builder} ) and not $me->{lazy} ) {
		$code->add_line( $me->inline_access_w( '$self', $D ) . ';' );
	}
	
	$code->add_line( $me->inline_weaken('$self') ) if $me->{weak_ref};
}

1;