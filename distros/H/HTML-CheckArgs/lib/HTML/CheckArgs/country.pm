package HTML::CheckArgs::country;

# to-do: allow more options for entering a country?
# would require expanding on Geography::Countries, or
# doing some fuzzier matching on country name

use strict;
use warnings;

use base 'HTML::CheckArgs::Object';
use Geography::Countries;
use HTML::FormatData;

sub is_valid {
	my $self = shift;
	
	my $value = $self->value;
	my $config = $self->config;

	$self->check_params( required => [], optional => [], cleanable => 1 );

	# no value passed in
	if ( $config->{required} && !$value ) {
		$self->error_code( 'country_00' ); # required
		$self->error_message( 'Not given.' );
		return;
	} elsif ( !$config->{required} && !$value ) {
		return 1;
	}

	# clean it up for validation
	$value =~ s/\.//g; # for U.S. case
	$value = HTML::FormatData->new->format_text( 
		$value, clean_whitespace => 1, strip_html => 1,
	);
	
	# match two-letter abbrieviation or name
	# matching on name is extremely fragile, and should never be done
	my ( $abbr, undef, undef, $name, undef ) = country( $value );
	unless ( lc( $value ) eq lc( $abbr ) or lc( $value ) eq lc( $name ) ) {
		$self->error_code( 'country_01' );
		$self->error_message( 'Not valid country; please enter canonical country name or two-letter abbrieviation.' );
		return;
	}
	
	# return cleaned value (the 2-letter abbr)?
	unless ( $config->{noclean} ) {
		$self->value( $abbr );
	}
		
	return 1;
}

1;
