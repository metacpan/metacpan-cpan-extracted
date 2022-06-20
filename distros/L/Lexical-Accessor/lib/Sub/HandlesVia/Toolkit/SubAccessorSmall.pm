use 5.008003;
use strict;
use warnings;
no warnings qw( void once uninitialized );

package Sub::HandlesVia::Toolkit::SubAccessorSmall;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.014';

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
	
	{
		my $reader = $realattr->reader;
		my $writer = $realattr->writer;
		my $default =
			ref($realattr->{default})    ? $realattr->{default} :
			length($realattr->{builder}) ? $realattr->{builder} :
			undef;
		$attr = [ $reader, $writer, $default ? $default : () ];
	}
	
	my $gen = $self->SUPER::code_generator_for_attribute( $target, $attr );
	
	$gen->method_installer( sub {
		my ( $method_name, $coderef ) = @_;
		my $real_destination = $handles_map->{$method_name};
		$realattr->install_coderef( $real_destination, $coderef );
	} );
	
	return $gen;
}

1;
