package HTML::CheckArgs::dollar;

# to-do: check for alpha chars and throw and error instead of stripping
# them out first?

use strict;
use warnings;

use base 'HTML::CheckArgs::Object';

sub is_valid {
	my $self = shift;
	
	my $value = $self->value;
	my $config = $self->config;

	$self->check_params( required => [], optional => [ qw( min max ) ], cleanable => 1 );
	
	# no value passed in
	# zero is a valid dollar, so we can't just check !$value
	if ( $config->{required} && ( !defined( $value ) || $value eq '' ) ) {
		$self->error_code( 'dollar_00' ); # required
		$self->error_message( 'Not given.' );
		return;
	} elsif ( !$config->{required} && ( !defined( $value ) || $value eq '' ) ) {
		return 1;
	}

	# is it valid?
	unless ( $value =~ m/^[-+\$]?([0-9,]+(\.[0-9]*)?|\.[0-9]+)$/ ) { # Friedl p128
		$self->error_code( 'dollar_01' ); # not valid
		$self->error_message( 'Not a valid dollar value.' );
		return;
	}

	# check parameters
	# legal ones are min and max
	my ( $min, $max );
	$min = $config->{params}{min};
	$max = $config->{params}{max};

	if ( defined( $min ) && ( $value < $min ) ) {
		$self->error_code( 'dollar_02' ); # under min
		$self->error_message( "Less than the minimum required (\$$min)." );
		return;
	}
		
	if ( defined( $max ) && ( $value > $max ) ) {
		$self->error_code( 'dollar_03' ); # over max
		$self->error_message( "More than the maximum allowed (\$$max)." );
		return;
	}
		
	# send back cleaned up value?
	# since original value can contain letters etc., you should
	# never set noclean => 1
	unless ( $config->{noclean} ) {
		$value =~ tr/-+.0-9//cd;
		if ($value =~ /^[-+]?\d+$/) {
		    $value .= ".00";
		}
		
		if ($value =~ m/^[-+]?\d+\.\d$/) {
			$value .= "0";
		}

		my @parts = $value =~ /(^[-+]?\d*\.\d{2})(.*)$/;
		if ( $parts[1] ) { $value = $1; }
		
		$self->value( $value );
	}
	
	return 1;
}

1;
