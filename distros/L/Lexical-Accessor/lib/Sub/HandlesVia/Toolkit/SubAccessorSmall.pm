use 5.008003;
use strict;
use warnings;
no warnings qw( void once uninitialized );

package Sub::HandlesVia::Toolkit::SubAccessorSmall;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '1.000002';

use Sub::HandlesVia::Toolkit;
our @ISA = 'Sub::HandlesVia::Toolkit';
$ISA[0]->VERSION( '0.025' );

sub new {
	my $class = shift;
	bless { @_ } => $class;
}

sub _attr {
	shift->{attr};
}

sub _handles_map {
	shift->{handles_map};
}

sub clean_spec {
	my ( $self, $target, $attr, $spec ) = @_;
	if ( 'ARRAY' eq ref $spec->{handles} ) {
		my %tmp = @{ $spec->{handles} };
		$spec->{handles} = \%tmp;
	}
	return $self->SUPER::clean_spec( $target, $attr, $spec );
}

sub code_generator_for_attribute {
	my ( $self, $target, $attr ) = @_;
	my $realattr = $self->_attr;
	my $handles_map = $self->_handles_map;
	
	my $captures = ( $realattr->{inline_environment} ||= {} );
	
	my $slot = sub {
		my $gen = shift;
		$realattr->inline_access($gen->generate_self);
	};
	
	my ( $get, $set, $get_is_lvalue );
	
	if ( $realattr->has_simple_reader ) {
		$get = sub {
			my $gen = shift;
			return $realattr->inline_access($gen->generate_self);
		};
		$get_is_lvalue = !!1;
	}
	else {
		$get = sub {
			my $gen = shift;
			return $realattr->inline_reader( $gen->generate_self );
		}
	}
	
	if ( $realattr->has_simple_writer ) {
		$set = sub {
			my ( $gen, $val ) = @_;
			return sprintf('(%s)', $realattr->inline_access_w($gen->generate_self, $val) );
		};
	}
	else {
		$set = sub {
			my ( $gen, $val ) = @_;
			return $realattr->inline_writer( $gen->generate_self, $val );
		};
	}
	
	require Sub::HandlesVia::CodeGenerator;
	return 'Sub::HandlesVia::CodeGenerator'->new(
		toolkit               => $self,
		target                => $target,
		attribute             => $attr,
		env                   => $captures,
		isa                   => $realattr->{isa},
		coerce                => $realattr->{coerce},
		generator_for_get     => $get,
		generator_for_set     => $set,
		generator_for_slot    => $slot,
		get_is_lvalue         => $get_is_lvalue,
		set_checks_isa        => !!1,
		set_strictly          => !!0,
		method_installer      => sub {
			my ( $method_name, $coderef ) = @_;
			my $real_destination = $handles_map->{$method_name};
			$realattr->install_coderef( $real_destination, $coderef );
		},
		generator_for_default => sub {
			my ( $gen, $handler ) = @_ or die;
			if ( $handler and not $realattr->{builder} and not exists $realattr->{default} ) {
				return $handler->default_for_reset->();
			}
			return $realattr->inline_default($gen->generate_self, '$default');
		},
	);
}

1;
