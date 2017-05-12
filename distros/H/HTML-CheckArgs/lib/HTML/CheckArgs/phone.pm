package HTML::CheckArgs::phone;

use strict;
use warnings;

use base 'HTML::CheckArgs::Object';
use HTML::FormatData;

sub is_valid {
	my $self = shift;
	
	my $value = $self->value;
	my $config = $self->config;

	$self->check_params( required => [], optional => [ 'country' ], cleanable => 1 );
	
	# no value passed in
	if ( $config->{required} && !$value ) {
		$self->error_code( 'phone_00' ); # required
		$self->error_message( 'Not given.' );
		return;
	} elsif ( !$config->{required} && !$value ) {
		return 1;
	}


	# clean it up for validation
	# for US case, we clean it up a lot more below
	$value = HTML::FormatData->new->format_text( 
		$value, clean_whitespace => 1, strip_html => 1,
	);
	
	# which country? must be a two-character country abbr
	# only does careful validation check for US for now
	my $country = uc $config->{params}{country} || 'US';

	if ( uc( $country ) eq 'US' ) {
		$value =~ tr/0-9//cd;
		if ( $value !~ m/^\d{10}$/ ) {
			$self->error_code( 'phone_01' ); # not valid
			$self->error_message( 'Not valid; please enter a 10-digit phone number, including area code.' );
			return;
		}
	
	# if not US, just do a sanity check on length
	} elsif ( length( $value ) > 100 ) {
		$self->error_code( 'phone_02' ); # over max length
		$self->error_message( 'Exceeds the maximum allowable length (100 characters).' );
		return;
	}

	# return cleaned value?
	unless ( $config->{noclean} ) {
		$self->value( $value );
	}
		
	return 1;
}

1;
