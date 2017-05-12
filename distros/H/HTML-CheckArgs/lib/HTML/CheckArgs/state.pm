package HTML::CheckArgs::state;

use strict;
use warnings;

use base 'HTML::CheckArgs::Object';
use HTML::FormatData;

sub is_valid {
	my $self = shift;
	
	my $value = $self->value;
	my $config = $self->config;

	$self->check_params( 
		required => [], 
		optional => [ qw( country include_dc include_territories include_military ) ], 
		cleanable => 1 
	);

	# no value passed in
	if ( $config->{required} && !$value ) {
		$self->error_code( 'state_00' ); # required
		$self->error_message( 'Not given.' );
		return;
	} elsif ( !$config->{required} && !$value ) {
		$self->value( $value );
		return 1;
	}

	# clean it up for validation
	$value =~ s/\.//g; # for S.C. case
	$value = HTML::FormatData->new->format_text( 
		$value, clean_whitespace => 1, strip_html => 1,
	);

	# which country? must be a two-character country abbr
	# only does careful validation check for US for now
	my $country = uc $config->{params}{country} || 'US';

	if ( $country eq 'US' ) {
		my %states = get_states_hash(
			include_dc          => $config->{params}{include_dc}, 
			include_territories => $config->{params}{include_territories}, 
			include_military    => $config->{params}{include_military}
		);
		
		my $match = 0;
		while ( my ( $key, $val ) = each( %states ) ) {
			# match two-letter abbrieviation
			if ( lc( $value ) eq lc( $key ) ) {
				$value = uc( $value );
				$match = 1;
				last;
			}
			
			# match full state name
			if ( lc( $value ) eq lc( $val ) ) {
				$value = uc( $key );
				$match = 1;
				last;
			}
		}

		unless ( $match ) {
			$self->error_code( 'state_01' ); # not valid
			$self->error_message( 'Not valid US state; please enter full state name or two-letter abbrieviation.' );
			return;
		}
	
	# if not US, just do a sanity check on length
	} elsif ( length( $value ) > 100 ) {
		$self->error_code( 'state_02' ); # over max length
		$self->error_message( 'Exceeds the maximum allowable length (100 characters).' );
		return;
	}
	
	# return cleaned value (the 2-letter abbr)?
	unless ( $config->{noclean} ) {
		$self->value( $value );
	}
	
	return 1;
}


# get_states_hash( include_dc=>1, include_territories=>1, include_military=>1 )
# Returns a hash of all 50 states. Optionally, can include DC, the territories, and 
# military APOs.

sub get_states_hash {
	my %args = @_;

	my %states = (
	AL=>"Alabama",
	AK=>"Alaska",
	AZ=>"Arizona",
	AR=>"Arkansas",
	CA=>"California",
	CO=>"Colorado",
	CT=>"Connecticut",
	DE=>"Delaware",
	FL=>"Florida",
	GA=>"Georgia",
	HI=>"Hawaii",
	ID=>"Idaho",
	IL=>"Illinois",
	IN=>"Indiana",
	IA=>"Iowa",
	KS=>"Kansas",
	KY=>"Kentucky",
	LA=>"Louisiana",
	ME=>"Maine",
	MD=>"Maryland",
	MA=>"Massachusetts",
	MI=>"Michigan",
	MN=>"Minnesota",
	MS=>"Mississippi",
	MO=>"Missouri",
	MT=>"Montana",
	'NE'=>"Nebraska",
	NV=>"Nevada",
	NH=>"New Hampshire",
	NJ=>"New Jersey",
	NM=>"New Mexico",
	NY=>"New York",
	NC=>"North Carolina",
	ND=>"North Dakota",
	OH=>"Ohio",
	OK=>"Oklahoma",
	'OR'=>"Oregon",
	PA=>"Pennsylvania",
	RI=>"Rhode Island",
	SC=>"South Carolina",
	SD=>"South Dakota",
	TN=>"Tennessee",
	TX=>"Texas",
	UT=>"Utah",
	VT=>"Vermont",
	VA=>"Virginia",
	WA=>"Washington",
	WV=>"West Virginia",
	WI=>"Wisconsin",
	WY=>"Wyoming"
	);

	if ( $args{include_dc} ) {
		$states{DC} = "District of Columbia";
	}

	if ( $args{include_territories} ) {
		$states{AS} = "American Samoa";
		$states{GU} = "Guam";
		$states{MP} = "Northern Mariana Islands";
		$states{PR} = "Puerto Rico";
		$states{VI} = "Virgin Islands";
	}

	if ( $args{include_military} ) {
		$states{AA} = 'Armed Forces Americas';
		$states{AE} = 'Armed Forces Europe';
		$states{AP} = 'Armed Forces Pacific';
	}

	return %states;
}

1;
