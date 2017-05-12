package HTML::CheckArgs::cc_expiration;

# to-do: better date format checking with DateTime
# add future date check, perhaps 20 years

use strict;
use warnings;

use base 'HTML::CheckArgs::Object';

sub is_valid {
	my $self = shift;
	
	my $value = $self->value;
	my $config = $self->config;

	$self->check_params( required => [], optional => [], cleanable => 0 );

	# no value passed in
	if ( $config->{required} && !$value ) {
		$self->error_code( 'cc_expiration_00' ); # required
		$self->error_message( 'Not given.' );
		return;
	} elsif ( !$config->{required} && !$value ) {
		return 1;
	}

	# quick dumb check for date format
	# value must be passed in as YYYYMM
	if ( length( $value ) != 6 ) {
		$self->error_code( 'cc_expiration_01' ); # not valid
		$self->error_message( 'Not a valid date.' );
		return;
	}

	# check if is past
	my ( $month, $year ) = ( localtime )[4,5];
	$month = sprintf( '%02d', $month ); $year += 1900;

	if ( $value < "$year$month" ) {
		$self->error_code( 'cc_expiration_02' ); # already passed
		$self->error_message( 'Date has already passed.' );
		return;
	}

	return 1;
}

1;
