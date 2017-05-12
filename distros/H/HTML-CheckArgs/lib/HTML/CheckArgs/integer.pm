package HTML::CheckArgs::integer;

use strict;
use warnings;

use base 'HTML::CheckArgs::Object';

sub is_valid {
	my $self = shift;
	
	my $value = $self->value;
	my $config = $self->config;

	$self->check_params( required => [], optional => [ qw( min max ) ], cleanable => 0 );

	# no value passed in
	# zero is a valid integer, so we can't just check !$value
	if ( $config->{required} && ( !defined( $value ) || $value eq '' ) ) {
		$self->error_code( 'integer_00' ); # required
		$self->error_message( 'Not given.' );
		return;
	} elsif ( !$config->{required} && ( !defined( $value ) || $value eq '' ) ) {
		return 1;
	}
		
	# is it valid?
	unless ( $value =~ m/^[-+]?\d+$/ ) {
		$self->error_code( 'integer_01' ); # not valid
		$self->error_message( 'Not a valid integer.' );
		return;
	}

	# check parameters
	# legal ones are min and max
	my ( $min, $max );
	$min = $config->{params}{min};
	$max = $config->{params}{max};

	if ( defined( $min ) && ( $value < $min ) ) {
		$self->error_code( 'integer_02' ); # under min
		$self->error_message( "Less than the minimum required ($min)." );
		return;
	}
		
	if ( defined( $max ) && ( $value > $max ) ) {
		$self->error_code( 'integer_03' ); # over max
		$self->error_message( "More than the maximum allowed ($max)." );
		return;
	}

	return 1;
}

1;
