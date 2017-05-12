package HTML::CheckArgs::cc_number;

use strict;
use warnings;

use base 'HTML::CheckArgs::Object';

sub is_valid {
	my $self = shift;
	
	my $value = $self->value;
	my $config = $self->config;

	$self->check_params( required => [], optional => [], cleanable => 1 );

	# no value passed in
	if ( $config->{required} && !$value ) {
		$self->error_code( 'cc_number_00' ); # required
		$self->error_message( 'Not given.' );
		return;
	} elsif ( !$config->{required} && !$value ) {
		return 1;
	}

	# clean it up for validation
	$value =~ tr/0-9//cd;

	if ( !luhn_check( $value ) ) {
		$self->error_code( 'cc_number_01' ); # not valid
		$self->error_message( 'Not valid.' );
		return;
	}

	# send back cleaned up value?
	unless ( $config->{noclean} ) {
		$self->value( $value );
	}
		
	return 1;
}

sub luhn_check {

	my ($number, @in_digits, $number_digits, $sum, $odd, $count, $chunk);
	$number = $_[0];

	# For a card with an even number of digits, double every odd numbered
	# digit and subtract 9 if the product is greater than 9.  Add up all the
	# even digits as well as the doubled-odd digits, and the result must be
	# a multiple of 10 or it's not a valid card.  If the card has an odd
	# number of digits, perform the same addition doubling the even numbered
	# digits instead.
	#  -- Phrack, issue 47, section 8
	#     http://www.lglobal.com/TAO/Zines/Phrack/47/P47-08

	@in_digits = split( '', $number );
	$number_digits = @in_digits;
	$odd = $number_digits & 1;
	$sum = 0;

	for ( $count= 0; $count < $number_digits; $count++ ) {
		$chunk = $in_digits[$count];
		unless ( $count & 1 ^ $odd ) {
			$chunk = $chunk * 2;
			$chunk -= 9 if $chunk > 9;
		}
		$sum += $chunk;
	}
	
	return ( $sum % 10 == 0 );
}

1;
