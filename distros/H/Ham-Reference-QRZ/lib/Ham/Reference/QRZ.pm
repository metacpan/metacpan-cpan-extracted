package Ham::Reference::QRZ;

# --------------------------------------------------------------------------
# Ham::Reference::QRZ - An interface to the QRZ XML Database Service
#
# Copyright (c) 2008-2016 Brad McConahay N8QQ.
# Cincinnati, Ohio USA
# --------------------------------------------------------------------------

use strict;
use warnings;
use XML::Simple;
use LWP::UserAgent;
use HTML::Entities;
use vars qw($VERSION);

our $VERSION = '0.04';

my $site_name = 'QRZ XML Database Service';
my $default_api_url = "http://xmldata.qrz.com/xml";
my $default_timeout = 10;

sub new
{
	my $class = shift;
	my %args = @_;
	my $self = {};
	bless $self, $class;
	$self->_set_agent;
	$self->set_timeout($args{timeout});
	$self->set_api_url($args{api_url});
	$self->set_callsign($args{callsign}) if $args{callsign};
	$self->set_username($args{username}) if $args{username};
	$self->set_password($args{password}) if $args{password};
	$self->set_key($args{key}) if $args{key};
	$self->_clear_errors;
	return $self;
}

sub login
{
	my $self = shift;
	$self->_clear_errors;
	if (!$self->{_username}) { die "No QRZ subscription username given" }
	if (!$self->{_password}) { die "No QRZ subscription password given" }
	my $url = "$self->{_api_url}/bin/xml?username=$self->{_username}&password=$self->{_password}&agent=$self->{_agent}";
	my $login = $self->_get_xml($url);
	if ($login->{Session}->{Error}) {
		die $login->{Session}->{Error};
	} elsif (!$login->{Session}->{Key}) {
		die "Unknown Error - Could not retrieve session key";
	} else {
		$self->set_key($login->{Session}->{Key});
		$self->{_session} = $login->{Session};
	}
}

sub set_callsign
{
	my $self = shift;
	my $callsign = shift;
	$callsign =~ tr/a-z/A-Z/;
	$self->{_callsign} = $callsign;
	$self->{_listing} = {};
	$self->{_bio} = {};
}

sub set_username
{
	my $self = shift;
	my $username = shift;
	$self->{_username} = $username;
}

sub set_password
{
	my $self = shift;
	my $password = shift;
	$self->{_password} = $password;
}

sub set_key
{
	my $self = shift;
	my $key = shift;
	$self->{_key} = $key;
}

sub set_timeout
{
	my $self = shift;
	my $timeout = shift || $default_timeout;
	$self->{_timeout} = $timeout;
}

sub set_api_url
{
	my $self = shift;
	my $api_url = shift || $default_api_url;
	$api_url =~ s/\/$//;
	$self->{_api_url} = $api_url;
}

sub get_listing
{
	my $self = shift;
	$self->_clear_errors;
	return $self->{_listing} if $self->{_listing}->{call};
	if (!$self->{_callsign}) {
		$self->{is_error} = 1;
		$self->{error_message} = "Can not get data without a callsign";
		return undef;
	}	
	if (!$self->{_key}) {
		$self->login;
	}
	my $url = "$self->{_api_url}/bin/xml?s=$self->{_key}&callsign=$self->{_callsign}";
	my $listing = $self->_get_xml($url);
	if ($listing->{Session}->{Error}) {
		$self->{is_error} = 1;
		$self->{error_message} = $listing->{Session}->{Error};
		return undef;
	}
	$self->{_session} = $listing->{Session};
	$self->{_listing} = $listing->{Callsign};
}

sub get_bio
{
	my $self = shift;
	$self->_clear_errors;
	return $self->{_bio} if $self->{_bio}->{call};
	if (!$self->{_callsign}) {
		$self->{is_error} = 1;
		$self->{error_message} = "Can not get data without a callsign";
		return undef;
	}	
	if (!$self->{_key}) {
		$self->login;
	}
	my $url = "$self->{_api_url}/bin/xml?s=$self->{_key}&bio=$self->{_callsign}";
	my $bio = $self->_get_xml($url);
	if ($bio->{Session}->{Error}) {
		$self->{is_error} = 1;
		$self->{error_message} = $bio->{Session}->{Error};
		return undef;
	}
	$self->{_session} = $bio->{Session};
	$self->{_bio} = $bio->{Bio};
}

sub get_bio_file
{
	my $self = shift;
	$self->_clear_errors;
	$self->get_bio if !$self->{_bio}->{call};
	if (!$self->{_bio}->{bio}) {
		$self->{is_error} = 1;
		$self->{error_message} = 'No URL for bio file is available for this callsign';
		return undef;		
	}
	my $url = "$self->{_bio}->{bio}";
	my $content = $self->_get_http($url);
	return undef if $self->{is_error};
	$content =~ s/&nbsp;/ /g; # convert nbsp entity to regular printable spaces
	$content = decode_entities($content);
	$content =~ s/<.*?>//g; # strip html
	return $content;
}

sub get_dxcc
{
	my $self = shift;
	$self->_clear_errors;
	return $self->{_dxcc} if $self->{_dxcc}->{call};
	if (!$self->{_callsign}) {
		$self->{is_error} = 1;
		$self->{error_message} = "Can not get data without a callsign";
		return undef;
	}	
	if (!$self->{_key}) {
		$self->login;
	}
	my $url = "$self->{_api_url}/bin/xml?s=$self->{_key}&dxcc=$self->{_callsign}";
	my $bio = $self->_get_xml($url);
	if ($bio->{Session}->{Error}) {
		$self->{is_error} = 1;
		$self->{error_message} = $bio->{Session}->{Error};
		return undef;
	}
	$self->{_session} = $bio->{Session};
	$self->{_dxcc} = $bio->{DXCC};
}

sub get_arrl_section
{
	my $self = shift;
	$self->_clear_errors;
	$self->get_listing if !$self->{_listing}->{callsign};
	if (!$self->{_listing}->{state} or (!$self->{_listing}->{county} and $self->{_listing}->{country} ne 'Canada')) {
		$self->{is_error} = 1;
		$self->{error_message} = "Unable to look up ARRL Section without state or county";
		return undef;
	}
	my $sections = $self->_get_arrl_sections;
	my $section = (ref($sections->{$self->{_listing}->{state}}) eq 'HASH') ? $sections->{$self->{_listing}->{state}}->{$self->{_listing}->{county}} : $sections->{$self->{_listing}->{state}};
	return $section;
}

sub get_session
{
	my $self = shift;
	return $self->{_session};
}


sub is_error { my $self = shift; $self->{is_error} }
sub error_message { my $self = shift; $self->{error_message} }


# -----------------------
#	PRIVATE
# -----------------------

sub _set_agent
{
	my $self = shift;
	$self->{_agent} = "Ham-Reference-QRZ-$VERSION";
}

sub _get_xml
{
	my $self = shift;
	my $url = shift;
	my $content = $self->_get_http($url);
	return undef if $self->{is_error};
	chomp $content;
	$content =~ s/(\r|\n)//g;

	$content =~ s/iso8859-1/iso-8859-1/; # added to account for what appears to be an
                                         # incorrect encoding declearation string, 2009-10-31 bam
	my $xs = XML::Simple->new( SuppressEmpty => 0 );
	my $data = $xs->XMLin($content);
	return $data;
}

sub _get_http
{
	my $self = shift;
	my $url = shift;
	$self->_clear_errors;
	my $ua = LWP::UserAgent->new( timeout=>$self->{_timeout} );
	$ua->agent( $self->{_agent} );
	my $request = HTTP::Request->new('GET', $url);
	my $response = $ua->request($request);
	if (!$response->is_success) {
		$self->{is_error} = 1;
		$self->{error_message} = "Could not contact $site_name - ".HTTP::Status::status_message($response->code);
		return undef;
	}
	return $response->content;
}

sub _clear_errors
{
	my $self = shift;
	$self->{is_error} = 0;
	$self->{error_message} = '';
}

sub _get_arrl_sections {
	return {
		'AL' => 'AL',
		'AK' => 'AK',
		'AB' => 'AB',
		'AZ' => 'AZ',
		'AR' => 'AR',
		'BC' => 'BC',
		'CA' => {
			'Alameda' => 'EB',
			'Contra Costa' => 'EB',
			'Napa' => 'EB',
			'Solano' => 'EB',
			'Los Angeles' => 'LAX',
			'Inyo' => 'ORG',
			'Orange' => 'ORG',
			'Riverside' => 'ORG',
			'San Bernardino' => 'ORG',
			'San Luis Obispo' => 'SB',
			'Santa Barbara' => 'SB',
			'Ventura' => 'SB',
			'Monterey' => 'SCV',
			'San Benito' => 'SCV',
			'San Mateo' => 'SCV',
			'Santa Clara' => 'SCV',
			'Santa Cruz' => 'SCV',
			'Imperial' => 'SDG',
			'San Diego' => 'SDG',
			'Del Norte' => 'SF',
			'Humboldt' => 'SF',
			'Lake' => 'SF',
			'Marin' => 'SF',
			'Mendocino' => 'SF',
			'San Francisco' => 'SF',
			'Sonoma' => 'SF',
			'Calaveras' => 'SJV',
			'Fresno' => 'SJV',
			'Kern' => 'SJV',
			'Kings' => 'SJV',
			'Madera' => 'SJV',
			'Mariposa' => 'SJV',
			'Merced' => 'SJV',
			'Mono' => 'SJV',
			'San Joaquin' => 'SJV',
			'Stanislaus' => 'SJV',
			'Tulare' => 'SJV',
			'Tuolumne' => 'SJV',
			'Alpine' => 'SV',
			'Amador' => 'SV',
			'Butte' => 'SV',
			'Colusa' => 'SV',
			'El Dorado' => 'SV',
			'Glenn' => 'SV',
			'Lassen' => 'SV',
			'Modoc' => 'SV',
			'Nevada' => 'SV',
			'Placer' => 'SV',
			'Plumas' => 'SV',
			'Sacramento' => 'SV',
			'Shasta' => 'SV',
			'Sierra' => 'SV',
			'Siskiyou' => 'SV',
			'Sutter' => 'SV',
			'Tehama' => 'SV',
			'Trinity' => 'SV',
			'Yolo' => 'SV',
			'Yuba' => 'SV'
		},
		'CO' => 'CO',
		'CT' => 'CT',
		'DE' => 'DE',
		'DC' => 'MDC',
		'FL' => {
			'Alachua' => "NFL",
			'Lee' => "SFL",
			'Baker' => "NFL",
			'Leon' => "NFL",
			'Bay' => "NFL",
			'Levy' => "NFL",
			'Bradford' => "NFL",
			'Liberty' => "NFL",
			'Brevard' => "SFL",
			'Madison' => "NFL",
			'Broward' => "SFL",
			'Manatee' => "WCF",
			'Calhoun' => "NFL",
			'Marion' => "NFL",
			'Charlotte' => "WCF",
			'Martin' => "SFL",
			'Citrus' => "NFL",
			'Miami-Dade' => "SFL",
			'Clay' => "NFL",
			'Monroe' => "SFL",
			'Collier' => "SFL",
			'Nassau' => "NFL",
			'Columbia' => "NFL",
			'Okaloosa' => "NFL",
			'Desoto' => "WCF",
			'Okeechobee' => "SFL",
			'Dixie' => "NFL",
			'Orange' => "NFL",
			'Duval' => "NFL",
			'Osceola' => "SFL",
			'Escambia' => "NFL",
			'Palm Beach' => "SFL",
			'Flagler' => "NFL",
			'Pasco' => "WCF",
			'Franklin' => "NFL",
			'Pinellas' => "WCF",
			'Gadsden' => "NFL",
			'Polk' => "WCF",
			'Gilchrist' => "NFL",
			'Putnam' => "NFL",
			'Glades' => "SFL",
			'Santa Rosa' => "NFL",
			'Gulf' => "NFL",
			'Sarasota' => "WCF",
			'Hamilton' => "NFL",
			'Seminole' => "NFL",
			'Hardee' => "WCF",
			'St. Johns' => "NFL",
			'Hendry' => "SFL",
			'St. Lucie' => "SFL",
			'Hernando' => "NFL",
			'Sumter' => "NFL",
			'Highlands' => "WCF",
			'Suwannee' => "NFL",
			'Hillsborough' => "WCF",
			'Taylor' => "NFL",
			'Holmes' => "NFL",
			'Union' => "NFL",
			'Indian River' => "SFL",
			'Volusia' => "NFL",
			'Jackson' => "NFL",
			'Wakulla' => "NFL",
			'Jefferson' => "NFL",
			'Walton' => "NFL",
			'Lafayette' => "NFL",
			'Washington' => "NFL",
			'Lake' => "NFL"
		},
		'GA' => 'GA',
		'GU' => 'GU',
		'HI' => 'PAC',
		'ID' => 'ID',
		'IL' => 'IL',
		'IN' => 'IN',
		'IA' => 'IA',
		'KS' => 'KS',
		'KY' => 'KY',
		'LA' => 'LA',
		'MA' => {
			'Barnstable' => 'EMA',
			'Bristol' => 'EMA',
			'Dukes' => 'EMA',
			'Essex' => 'EMA',
			'Middlesex' => 'EMA',
			'Nantucket' => 'EMA',
			'Norfolk' => 'EMA',
			'Plymouth' => 'EMA',
			'Berkshire' => 'WMA',
			'Franklin' => 'WMA',
			'Hampden' => 'WMA',
			'Hampshire' => 'WMA',
			'Worcester' => 'WMA'
		},
		'ME' => 'ME',
		'MB' => 'MB',
		'MD' => 'MDC',
		'MI' => 'MI',
		'MN' => 'MN',
		'MS' => 'MS',
		'MO' => 'MO',
		'MT' => 'MT',
		'NB' => 'NB',
		'NC' => 'NC',
		'ND' => 'ND',
		'NE' => 'NE',
		'NH' => 'NH',
		'NJ' => {
			'Bergen' => 'NNJ',
			'Essex' => 'NNJ',
			'Hudson' => 'NNJ',
			'Hunterdon' => 'NNJ',
			'Middlesex' => 'NNJ',
			'Monmouth' => 'NNJ',
			'Morris' => 'NNJ',
			'Passaic' => 'NNJ',
			'Somerset' => 'NNJ',
			'Sussex' => 'NNJ',
			'Union' => 'NNJ',
			'Warren' => 'NNJ',
			'Atlantic' => 'SNJ',
			'Burlington' => 'SNJ',
			'Camden' => 'SNJ',
			'Cape May' => 'SNJ',
			'Cumberland' => 'SNJ',
			'Gloucester' => 'SNJ',
			'Mercer' => 'SNJ',
			'Ocean' => 'SNJ',
			'Salem' => 'SNJ'
		},
		'NL' => 'NL',
		'NM' => 'NM',
		'NS' => 'NS',
		'NT' => 'NT',
		'NU' => 'NU',
		'NV' => 'NV',
		'NY' => {
			'Bronx' => 'NLI',
			'New York' => 'NLI',
			'Kings' => 'NLI',
			'Queens' => 'NLI',
			'Richmond' => 'NLI',
			'Nassau' => 'NLI',
			'Suffolk' => 'NLI',
			'Albany' => 'ENY', 
			'Columbia' => 'ENY', 
			'Dutchess' => 'ENY', 
			'Greene' => 'ENY', 
			'Orange' => 'ENY', 
			'Putnam' => 'ENY', 
			'Rensselaer' => 'ENY', 
			'Rockland' => 'ENY', 
			'Saratoga' => 'ENY', 
			'Schenectady' => 'ENY', 
			'Sullivan' => 'ENY', 
			'Ulster' => 'ENY', 
			'Warren' => 'ENY', 
			'Washington' => 'ENY', 
			'Westchester' => 'ENY',
			'Clinton' => 'NNY', 
			'Essex' => 'NNY', 
			'Franklin' => 'NNY', 
			'Fulton' => 'NNY', 
			'Hamilton' => 'NNY', 
			'Jefferson' => 'NNY', 
			'Lewis' => 'NNY', 
			'Montgomery' => 'NNY', 
			'St. Lawrence' => 'NNY', 
			'Schoharie' => 'NNY',
			'Allegany' => 'WNY', 
			'Broome' => 'WNY', 
			'Cattaraugus' => 'WNY', 
			'Cayuga' => 'WNY', 
			'Chautauqua' => 'WNY', 
			'Chemung' => 'WNY', 
			'Chenango' => 'WNY', 
			'Cortland' => 'WNY', 
			'Delaware' => 'WNY', 
			'Erie' => 'WNY', 
			'Genesee' => 'WNY', 
			'Herkimer' => 'WNY', 
			'Livingston' => 'WNY', 
			'Madison' => 'WNY', 
			'Monroe' => 'WNY', 
			'Niagara' => 'WNY', 
			'Oneida' => 'WNY', 
			'Onondaga' => 'WNY', 
			'Ontario' => 'WNY', 
			'Orleans' => 'WNY', 
			'Oswego' => 'WNY', 
			'Otsego' => 'WNY', 
			'Schuyler' => 'WNY', 
			'Seneca' => 'WNY', 
			'Steuben' => 'WNY', 
			'Tioga' => 'WNY', 
			'Tompkins' => 'WNY',
			'Wayne' => 'WNY', 
			'Wyoming' => 'WNY', 
			'Yates' => 'WNY'
		},
		'OH' => 'OH',
		'OK' => 'OK',
		'ON' => 'ON',
		'OR' => 'OR',
		'PA' => { 
			'Adams' => 'EPA',
			'Berks' => 'EPA',
			'Bradford' => 'EPA',
			'Bucks' => 'EPA',
			'Carbon' => 'EPA',
			'Chester' => 'EPA',
			'Columbia' => 'EPA',
			'Cumberland' => 'EPA',
			'Dauphin' => 'EPA',
			'Delaware' => 'EPA',
			'Juniata' => 'EPA',
			'Lackawanna' => 'EPA',
			'Lancaster' => 'EPA',
			'Lebanon' => 'EPA',
			'Lehigh' => 'EPA',
			'Luzerne' => 'EPA',
			'Lycoming' => 'EPA',
			'Monroe' => 'EPA',
			'Montgomery' => 'EPA',
			'Montour' => 'EPA',
			'Northhampton' => 'EPA',
			'Northumberland' => 'EPA',
			'Perry' => 'EPA',
			'Philadelphia' => 'EPA',
			'Pike' => 'EPA',
			'Schuylkill' => 'EPA',
			'Snyder' => 'EPA',
			'Sullivan' => 'EPA',
			'Susquehanna' => 'EPA',
			'Tioga' => 'EPA',
			'Union' => 'EPA',
			'Wayne' => 'EPA',
			'Wyoming' => 'EPA',
			'York' => 'EPA',
			'Allegheny' => 'WPA',
			'Armstrong' => 'WPA',
			'Beaver' => 'WPA',
			'Bedford' => 'WPA',
			'Blair' => 'WPA',
			'Butler' => 'WPA',
			'Cambria' => 'WPA',
			'Cameron' => 'WPA',
			'Centre' => 'WPA',
			'Clarion' => 'WPA',
			'Clearfield' => 'WPA',
			'Clinton' => 'WPA',
			'Crawford' => 'WPA',
			'Elk' => 'WPA',
			'Erie' => 'WPA',
			'Fayette' => 'WPA',
			'Franklin' => 'WPA',
			'Fulton' => 'WPA',                  
			'Greene' => 'WPA',
			'Huntingdon' => 'WPA',
			'Indiana' => 'WPA',                      
			'Jefferson' => 'WPA',                       
			'Lawrence' => 'WPA',
			'McKean' => 'WPA',
			'Mercer' => 'WPA',
			'Mifflin' => 'WPA',                                   
			'Potter' => 'WPA', 
			'Somerset' => 'WPA',                 
			'Venango' => 'WPA',
			'Warren' => 'WPA',
			'Washington' => 'WPA',
			'Westmoreland' => 'WPA'
		},
		'PE' => 'MAR',
		'PR' => 'PR',
		'QC' => 'QC',
		'RI' => 'RI',
		'SK' => 'SK',
		'SC' => 'SC',
		'SD' => 'SD',
		'TN' => 'TN',
		'TX' => {
			'Anderson' => 'WTX',
			'Andrews' => 'WTX',
			'Angelina' => 'STX',
			'Aransas' => 'STX',
			'Archer' => 'NTX',
			'Armstrong' => 'WTX',
			'Atascosa' => 'STX',
			'Austin' => 'STX',
			'Bailey' => 'WTX',
			'Bandera' => 'STX',
			'Bastrop' => 'WTX',
			'Baylor' => 'NTX',
			'Bee' => 'STX',
			'Bell' => 'NTX',
			'Bexar' => 'STX',
			'Blanco' => 'STX',
			'Borden' => 'WTX',
			'Bosque' => 'NTX',
			'Bowie' => 'NTX',
			'Brazoria' => 'STX',
			'Brazos' => 'STX',
			'Brewster' => 'WTX',
			'Briscoe' => 'WTX',
			'Brooks' => 'STX',
			'Brown' => 'NTX',
			'Burleson' => 'STX',
			'Burnet' => 'STX',
			'Caldwell' => 'STX',
			'Calhoun' => 'STX',
			'Callahan' => 'WTX',
			'Cameron' => 'STX',
			'Camp' => 'NTX',
			'Carson' => 'WTX',
			'Cass' => 'NTX',
			'Castro' => 'WTX',
			'Chambers' => 'STX',
			'Cherokee' => 'NTX',
			'Childress' => 'WTX',
			'Clay' => 'NTX',
			'Cochran' => 'WTX',
			'Coke' => 'WTX',
			'Coleman' => 'WTX',
			'Collin' => 'NTX',
			'Collingsworth' => 'WTX',
			'Colorado' => 'STX',
			'Comal' => 'STX',
			'Comanche' => 'NTX',
			'Concho' => 'WTX',
			'Cooke' => 'NTX',
			'Coryell' => 'NTX',
			'Cottle' => 'WTX',
			'Crane' => 'WTX',
			'Crockett' => 'WTX',
			'Crosby' => 'WTX',
			'Culberson' => 'WTX',
			'Dallam' => 'WTX',
			'Dallas' => 'NTX',
			'Dawson' => 'WTX',
			'Deaf Smith' => 'WTX',
			'Delta' => 'NTX',
			'Denton' => 'NTX',
			'DeWitt' => 'STX',
			'Dickens' => 'WTX',
			'Dimmit' => 'STX',
			'Donley' => 'WTX',
			'Duval' => 'STX',
			'Eastland' => 'NTX',
			'Ector' => 'WTX',
			'Edwards' => 'STX',
			'El Paso' => 'WTX',
			'Ellis' => 'NTX',
			'Erath' => 'NTX',
			'Falls' => 'NTX',
			'Fannin' => 'NTX',
			'Fayette' => 'STX',
			'Fisher' => 'WTX',
			'Floyd' => 'WTX',
			'Foard' => 'WTX',
			'Fort Bend' => 'STX',
			'Franklin' => 'NTX',
			'Freestone' => 'NTX',
			'Frio' => 'STX',
			'Gaines' => 'WTX',
			'Galveston' => 'STX',
			'Garza' => 'WTX',
			'Gillespie' => 'STX',
			'Glasscock' => 'WTX',
			'Goliad' => 'STX',
			'Gonzales' => 'STX',
			'Gray' => 'WTX',
			'Grayson' => 'NTX',
			'Gregg' => 'NTX',
			'Grimes' => 'STX',
			'Guadalupe' => 'STX',
			'Hale' => 'WTX',
			'Hall' => 'WTX',
			'Hamilton' => 'NTX',
			'Hansford' => 'WTX',
			'Hardeman' => 'WTX',
			'Hardin' => 'STX',
			'Harris' => 'STX',
			'Harrison' => 'NTX',
			'Hartley' => 'WTX',
			'Haskell' => 'WTX',
			'Hays' => 'STX',
			'Hemphill' => 'WTX',
			'Henderson' => 'NTX',
			'Hidalgo' => 'STX',
			'Hill' => 'NTX',
			'Hockley' => 'WTX',
			'Hood' => 'NTX',
			'Hopkins' => 'NTX',
			'Houston' => 'STX',
			'Howard' => 'WTX',
			'Hudspeth' => 'WTX',
			'Hunt' => 'NTX',
			'Hutchinson' => 'WTX',
			'Irion' => 'WTX',
			'Jack' => 'NTX',
			'Jackson' => 'STX',
			'Jasper' => 'STX',
			'Jeff Davis' => 'WTX',
			'Jefferson' => 'STX',
			'Jim Hogg' => 'STX',
			'Jim Wells' => 'STX',
			'Johnson' => 'NTX',
			'Jones' => 'WTX',
			'Karnes' => 'STX',
			'Kaufman' => 'NTX',
			'Kendall' => 'STX',
			'Kenedy' => 'STX',
			'Kent' => 'WTX',
			'Kerr' => 'STX',
			'Kimble' => 'STX',
			'King' => 'WTX',
			'Kinney' => 'STX',
			'Kleberg' => 'STX',
			'Knox' => 'WTX',
			'La Salle' => 'STX',
			'Lamar' => 'NTX',
			'Lamb' => 'WTX',
			'Lampasas' => 'NTX',
			'Lavaca' => 'STX',
			'Lee' => 'STX',
			'Leon' => 'STX',
			'Liberty' => 'STX',
			'Limestone' => 'NTX',
			'Lipscomb' => 'WTX',
			'Live Oak' => 'STX',
			'Llano' => 'STX',
			'Loving' => 'WTX',
			'Lubbock' => 'WTX',
			'Lynn' => 'WTX',
			'Madison' => 'STX',
			'Marion' => 'NTX',
			'Martin' => 'WTX',
			'Mason' => 'STX',
			'Matagorda' => 'STX',
			'Maverick' => 'STX',
			'McCulloch' => 'STX',
			'McLennan' => 'NTX',
			'McMullen' => 'STX',
			'Medina' => 'STX',
			'Menard' => 'STX',
			'Midland' => 'WTX',
			'Milam' => 'STX',
			'Mills' => 'NTX',
			'Mitchell' => 'WTX',
			'Montague' => 'NTX',
			'Montgomery' => 'STX',
			'Moore' => 'WTX',
			'Morris' => 'NTX',
			'Motley' => 'WTX',
			'Nacogdoches' => 'NTX',
			'Navarro' => 'NTX',
			'Newton' => 'STX',
			'Nolan' => 'WTX',
			'Nueces' => 'STX',
			'Ochiltree' => 'WTX',
			'Oldham' => 'WTX',
			'Orange' => 'STX',
			'Palo Pinto' => 'NTX',
			'Panola' => 'NTX',
			'Parker' => 'NTX',
			'Parmer' => 'WTX',
			'Pecos' => 'WTX',
			'Polk' => 'STX',
			'Potter' => 'WTX',
			'Presidio' => 'WTX',
			'Rains' => 'NTX',
			'Randall' => 'WTX',
			'Reagan' => 'WTX',
			'Real' => 'STX',
			'Red River' => 'NTX',
			'Reeves' => 'WTX',
			'Refugio' => 'STX',
			'Roberts' => 'WTX',
			'Robertson' => 'STX',
			'Rockwall' => 'NTX',
			'Runnels' => 'WTX',
			'Rusk' => 'NTX',
			'Sabine' => 'STX',
			'San Augustine' => 'STX',
			'San Jacinto' => 'STX',
			'San Patricio' => 'STX',
			'San Saba' => 'STX',
			'Schleicher' => 'WTX',
			'Scurry' => 'WTX',
			'Shackelford' => 'WTX',
			'Shelby' => 'NTX',
			'Sherman' => 'WTX',
			'Smith' => 'NTX',
			'Somervell' => 'NTX',
			'Starr' => 'STX',
			'Stephens' => 'NTX',
			'Sterling' => 'WTX',
			'Stonewall' => 'WTX',
			'Sutton' => 'WTX',
			'Swisher' => 'WTX',
			'Tarrant' => 'NTX',
			'Taylor' => 'WTX',
			'Terrell' => 'WTX',
			'Terry' => 'WTX',
			'Throckmorton' => 'NTX',
			'Titus' => 'NTX',
			'Tom Green' => 'WTX',
			'Travis' => 'STX',
			'Trinity' => 'STX',
			'Tyler' => 'STX',
			'Upshur' => 'NTX',
			'Upton' => 'WTX',
			'Uvalde' => 'STX',
			'Val Verde' => 'STX',
			'Van Zandt' => 'NTX',
			'Victoria' => 'STX',
			'Walker' => 'STX',
			'Waller' => 'STX',
			'Ward' => 'WTX',
			'Washington' => 'STX',
			'Webb' => 'STX',
			'Wharton' => 'STX',
			'Wheeler' => 'WTX',
			'Wichita' => 'NTX',
			'Wilbarger' => 'NTX',
			'Willacy' => 'STX',
			'Williamson' => 'STX',
			'Wilson' => 'STX',
			'Winkler' => 'WTX',
			'Wise' => 'NTX',
			'Wood' => 'NTX',
			'Yoakum' => 'WTX',
			'Young' => 'NTX',
			'Zapata' => 'STX',
			'Zavala' => 'STX'
		},
		'UT' => 'UT',
		'VT' => 'VT',
		'VA' => 'VA',
		'VI' => 'VI',
		'WA' => {
			'Adams' => 'EWA',
			'Asotin' => 'EWA',
			'Benton' => 'EWA',
			'Chelan' => 'EWA',
			'Columbia' => 'EWA',
			'Douglas' => 'EWA',
			'Ferry' => 'EWA',
			'Franklin' => 'EWA',
			'Garfield' => 'EWA',
			'Grant' => 'EWA',
			'Kittitas' => 'EWA',
			'Klickitat' => 'EWA',
			'Lincoln' => 'EWA',
			'Okanogan' => 'EWA',
			'Pend Oreille' => 'EWA',
			'Spokane' => 'EWA',
			'Stevens' => 'EWA',
			'Walla Walla' => 'EWA',
			'Whitman' => 'EWA',
			'Yakima' => 'EWA',
			'Clallam' => 'WWA',
			'Clark' => 'WWA',
			'Cowlitz' => 'WWA',
			'Grays Harbor' => 'WWA',
			'Island' => 'WWA',
			'Jefferson' => 'WWA',
			'King' => 'WWA',
			'Kitsap' => 'WWA',
			'Lewis' => 'WWA',
			'Mason' => 'WWA',
			'Pacific' => 'WWA',
			'Pierce' => 'WWA',
			'San Juan' => 'WWA',
			'Skagit' => 'WWA',
			'Skamania' => 'WWA',
			'Snohomish' => 'WWA',
			'Thurston' => 'WWA',
			'Wahkiakum' => 'WWA',
			'Whatcom' => 'WWA'
		},
		'WI' => 'WI',
		'WV' => 'WV',
		'WY' => 'WY',
		'YT' => 'YT'
	};
}

1;
__END__

=head1 NAME

Ham::Reference::QRZ - An object oriented front end for the QRZ.COM Amateur Radio callsign database

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

 use Ham::Reference::QRZ;
 use Data::Dumper;

 my $qrz = Ham::Reference::QRZ->new(
   callsign => 'N8QQ',
   username => 'your_username',
   password => 'your_password'
 );

 # get the listing, bio and other information
 my $listing = $qrz->get_listing;
 my $bio = $qrz->get_bio;
 my $dxcc = $qrz->get_dxcc;
 my $session = $qrz->get_session;

 # dump the data to see how it's structured
 print Dumper($listing);
 print Dumper($bio);
 print Dumper($dxcc);
 print Dumper($session);

 # set a different callsign to look up
 $qrz->set_callsign('W8IRC');

 # get the listing and print some specific info
 $listing = $qrz->get_listing;
 print "Name: $listing->{name}\n";

 # show some dxcc info
 print "DXCC Continent: $dxcc->{continent}\n";
 print "DXCC Name: $dxcc->{name}\n";
 print "CQ Zone: $dxcc->{cqzone}\n";

 # show some session info
 print "Lookups in current 24 hour period: $session->{Count}\n";
 print "QRZ subscription expiration: $session->{SubExp}\n";

 # show the ARRL section
 my $arrl_section = $qrz->get_arrl_section;
 print "ARRL Section: $arrl_section\n";

 # show biography details, if any
 my $bio = $qrz->get_bio_file;
 print "Biography: $bio\n";

=head1 DESCRIPTION

The C<Ham::Reference::QRZ> module provides an easy object oriented front end to access Amateur Radio
callsign data from the QRZ.COM online database.

This module uses the QRZ XML Database Service, which requires a subscription from QRZ.COM.

The QRZ XML Database Service specification states "The data supplied by the XML port may
be extended in a forwardly compatible manner. New XML elements and database objects
(with their associated elements) may be transmitted at any time. It is the developers
responsibility to have their program ignore any unrecognized objects and/or elements
without raising an error, so long as the information received consists of properly formatted XML."

Therefore, this module will not attempt to list or manage individual elements of a callsign.  You
will need to inspect the hash reference keys to see which elements are available for any given
callsign, as demonstrated in the synopsis.

This module does not handle any management of reusing session keys at this time.

=head1 CONSTRUCTOR

=head2 new()

 Usage    : my $qrz = Ham::Reference::QRZ->new;
 Function : creates a new Ham::Reference::QRZ object
 Returns  : a Ham::Reference::QRZ object
 Args     : a hash:

            key       required?   value
            -------   ---------   -----
            timeout   no          an integer of seconds to wait for
                                   the timeout of the xml site
                                   default = 10
            api_url   no          a string to override the default
                                   base api url
                                   default = http://xmldata.qrz.com/xml
            callsign  no          you may specify a callsign to look up
                                   here, or you may do it later with the
                                   set_callsign() method
            username  no          you may specify a username to log in with
                                   here, or you may do it later with the
                                   set_username() method
            password  no          you may specify a password to log in with
                                   here, or you may do it later with the
                                   set_password() method
            key       no          set a session key here if you have a valid key so
                                   that no time is wasted doing another login. only
                                   useful if you are managing the reuse of your own keys

=head1 METHODS

=head2 set_callsign()

 Usage    : $qrz->set_callsign( $callsign );
 Function : set the callsign to look up at QRZ
 Returns  : n/a
 Args     : a case-insensitive string containing an Amateur Radio callsign.
 Notes    : calling this will reset the listing and bio data to null until
            you do another get_listing() or get_bio(), respectively.

=head2 set_username()

 Usage    : $qrz->set_username( $username );
 Function : set the username for your QRZ subscriber login
 Returns  : n/a
 Args     : a string

=head2 set_password()

 Usage    : $qrz->set_password( $password );
 Function : set the password for your QRZ subscriber login
 Returns  : n/a
 Args     : a string

=head2 set_key()

 Usage    : $qrz->set_key( $session_key );
 Function : set a session key for retrieving data at QRZ
 Returns  : n/a
 Args     : a string
 Notes    : this is useful only if you already have a valid key before the first login
            during a particular instance of the module.

=head2 set_timeout()

 Usage    : $qrz->set_timeout( $seconds );
 Function : sets the number of seconds to wait on the xml server before timing out
 Returns  : n/a
 Args     : an integer

=head2 set_api_url()

 Usage    : $qrz->set_api_url( $url );
 Function : overrides the base url path of the QRZ API URL. Example: http://xmldata.qrz.com/xml
 Returns  : n/a
 Args     : a string

=head2 get_listing()

 Usage    : $hashref = $qrz->get_listing;
 Function : retrieves data for the standard listing of a callsign from QRZ
 Returns  : a hash reference
 Args     : n/a
 Notes    : if a session key has not already been set, this method will automatically login.
            if a there is already listing information set from a previous lookup,
            this will just return that data.  call a new set_callsign() if you need to refresh
            the data with a new call to the qrz database.

=head2 get_bio()

 Usage    : $hashref = $qrz->get_bio;
 Function : retrieves data for the biography of a callsign from QRZ
 Returns  : a hash reference
 Args     : n/a
 Notes    : if a session key has not already been set, this method will automatically login.
            if a there is already biographical information set from a previous lookup,
            this will just return that data.  call a new set_callsign() if you need to refresh
            the data with a new call to the qrz database.  this method only retrieves the meta
            information about the bio.  call get_bio_file to get the actual contents of the bio.

=head2 get_bio_file()

 Usage    : $scalar = $qrz->get_bio_file;
 Function : retrieves the full biography of a callsign from QRZ, if any is available
 Returns  : a scalar
 Args     : n/a
 Notes    : if the get_bio method has not been called yet, it will be called first to get
            the url for the bio file.  any html entities in the contents of the bio will be
            converted to plain text, and all html will be stripped.  hard line breaks will be
            left in place.  suggestions are welcome on how this data might better be filtered.

=head2 get_dxcc()

 Usage    : $hashref = $qrz->get_dxcc;
 Function : retrieves DXCC information for a callsign from QRZ
 Returns  : a hash reference
 Args     : n/a
 Notes    : if a session key has not already been set, this method will automatically login.
            if a there is already dxcc information set from a previous lookup,
            this will just return that data.  call a new set_callsign() if you need to refresh
            the data with a new call to the qrz database.

=head2 get_arrl_section()

 Usage    : $scalar = $qrz->get_arrl_section;
 Function : returns ARRL Section information for a callsign
 Returns  : a scalar
 Args     : n/a
 Notes    : if get listing has not yet been called, it will call get_listing to get state and county.
            this method gets its data internally, and does not query the qrz xml server.

=head2 login()

 Usage    : $session = $qrz->login;
 Function : initiates a login to the QRZ xml server
 Returns  : a hash reference of the session data
 Args     : n/a
 Notes    : this generally shouldn't need to be used since the get_listing() and get_bio()
            methods will automatically initiate a login to the server if it hasn't already
            been done.

=head2 get_session()

 Usage    : $session = $qrz->get_session;
 Function : retrieves the session information from the most recent call to the XML site
 Returns  : a hash reference of the session data
 Args     : n/a

=head2 is_error()

 Usage    : if ( $qrz->is_error )
 Function : test for an error if one was returned from the call to the XML site
 Returns  : a true value if there has been an error
 Args     : n/a

=head2 error_message()

 Usage    : my $err_msg = $qrz->error_message;
 Function : if there was an error message when trying to call the XML site, this is it
 Returns  : a string (the error message)
 Args     : n/a

=head1 DEPENDENCIES

=over 4

=item * L<XML::Simple>

=item * L<LWP::UserAgent>

=item * L<HTML::Entities>

=item * An Internet connection

=item * A QRZ.COM subscription that includes access to the QRZ XML Database Service

=back

=head1 TODO

=over 4

=item * Session key reuse between instances (maybe).

=item * Look into any escaping or filtering of data that would be helpful, particularly with regard to get_bio_file().

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Thomas Schaefer NY4I for the idea, original code, and data for the ARRL Section additions!

This module accesses data from the widely popular QRZ.COM Database.  See http://www.qrz.com

=head1 SEE ALSO

=over 4

=item

In order to use this module you need to have a subscription for the QRZ XML Database Service.
See http://www.qrz.com/XML/index.html

=item

The technical reference for the QRZ XML Database Service is at http://www.qrz.com/XML/current_spec.html

=back

=head1 AUTHOR

Brad McConahay N8QQ, C<< <brad at n8qq.com> >>

=head1 COPYRIGHT AND LICENSE

C<Ham::Reference::QRZ> is Copyright (C) 2008-2016 Brad McConahay N8QQ.

This module is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0. For
details, see the full text of the license in the file LICENSE.

This program is distributed in the hope that it will be
useful, but it is provided "as is" and without any express
or implied warranties. For details, see the full text of
the license in the file LICENSE.

