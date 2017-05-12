package Linux::DVB::DVBT::Freq ;

=head1 NAME

Linux::DVB::DVBT::Freq - DVBT frequency scanning 

=head1 SYNOPSIS

	use Linux::DVB::DVBT::Freq ;
  

=head1 DESCRIPTION

Module provides routines that create a list of frequencies to scan based on the country. The tables are based on the information in w_scan.

=cut


use strict ;

our $VERSION = '1.01' ;
our $DEBUG = 0 ;


our %CHANNEL_TYPE = (
	'NOT_USED'		=> 0,
	'DVBT_AU'		=> 1,
	'DVBT_DE'		=> 2,
	'DVBT_FR'		=> 3,
	'DVBT_GB'		=> 4,
) ;

our %COUNTRY_LIST = (
       "AD" => [ "NOT_USED",	"ANDORRA"],
       "AE" => [ "NOT_USED",	"UNITED ARAB EMIRATES"],
       "AF" => [ "NOT_USED",	"AFGHANISTAN"],
       "AG" => [ "NOT_USED",	"ANTIGUA AND BARBUDA"],
       "AI" => [ "NOT_USED",	"ANGUILLA"],
       "AL" => [ "NOT_USED",	"ALBANIA"],
       "AM" => [ "NOT_USED",	"ARMENIA"],
       "AO" => [ "NOT_USED",	"ANGOLA"],
       "AQ" => [ "NOT_USED",	"ANTARCTICA"],
       "AR" => [ "NOT_USED",	"ARGENTINA"],
       "AS" => [ "NOT_USED",	"AMERICAN SAMOA"],
       "AT" => [ "DVBT_DE",	"AUSTRIA"],
       "AU" => [ "DVBT_AU",	"AUSTRALIA"],
       "AW" => [ "NOT_USED",	"ARUBA"],
       "AX" => [ "NOT_USED",	"ÅLAND ISLANDS"],
       "AZ" => [ "NOT_USED",	"AZERBAIJAN"],
       "BA" => [ "NOT_USED",	"BOSNIA AND HERZEGOVINA"],
       "BB" => [ "NOT_USED",	"BARBADOS"],
       "BD" => [ "NOT_USED",	"BANGLADESH"],
       "BE" => [ "DVBT_DE",	"BELGIUM"],
       "BF" => [ "NOT_USED",	"BURKINA FASO"],
       "BG" => [ "NOT_USED",	"BULGARIA"],
       "BH" => [ "NOT_USED",	"BAHRAIN"],
       "BI" => [ "NOT_USED",	"BURUNDI"],
       "BJ" => [ "NOT_USED",	"BENIN"],
       "BL" => [ "NOT_USED",	"SAINT BARTHÉLEMY"],
       "BM" => [ "NOT_USED",	"BERMUDA"],
       "BN" => [ "NOT_USED",	"BRUNEI DARUSSALAM"],
       "BO" => [ "NOT_USED",	"BOLIVIA"],
       "BQ" => [ "NOT_USED",	"BONAIRE"],
       "BR" => [ "NOT_USED",	"BRAZIL"],
       "BS" => [ "NOT_USED",	"BAHAMAS"],
       "BT" => [ "NOT_USED",	"BHUTAN"],
       "BV" => [ "NOT_USED",	"BOUVET ISLAND"],
       "BW" => [ "NOT_USED",	"BOTSWANA"],
       "BY" => [ "NOT_USED",	"BELARUS"],
       "BZ" => [ "NOT_USED",	"BELIZE"],
       "CA" => [ "NOT_USED",	"CANADA"],
       "CC" => [ "NOT_USED",	"COCOS (KEELING) ISLANDS"],
       "CD" => [ "NOT_USED",	"CONGO, THE DEMOCRATIC REPUBLIC OF THE"],
       "CF" => [ "NOT_USED",	"CENTRAL AFRICAN REPUBLIC"],
       "CG" => [ "NOT_USED",	"CONGO"],
       "CH" => [ "DVBT_DE",	"SWITZERLAND"],
       "CI" => [ "NOT_USED",	"CÔTE D'IVOIRE"],
       "CK" => [ "NOT_USED",	"COOK ISLANDS"],
       "CL" => [ "NOT_USED",	"CHILE"],
       "CM" => [ "NOT_USED",	"CAMEROON"],
       "CN" => [ "NOT_USED",	"CHINA"],
       "CO" => [ "NOT_USED",	"COLOMBIA"],
       "CR" => [ "NOT_USED",	"COSTA RICA"],
       "CU" => [ "NOT_USED",	"CUBA"],
       "CV" => [ "NOT_USED",	"CAPE VERDE"],
       "CW" => [ "NOT_USED",	"CURAÇAO"],
       "CX" => [ "NOT_USED",	"CHRISTMAS ISLAND"],
       "CY" => [ "NOT_USED",	"CYPRUS"],
       "CZ" => [ "DVBT_DE",	"CZECH REPUBLIC"],
       "DE" => [ "DVBT_DE",	"GERMANY"],
       "DJ" => [ "NOT_USED",	"DJIBOUTI"],
       "DK" => [ "DVBT_DE",	"DENMARK"],
       "DM" => [ "NOT_USED",	"DOMINICA"],
       "DO" => [ "NOT_USED",	"DOMINICAN REPUBLIC"],
       "DZ" => [ "NOT_USED",	"ALGERIA"],
       "EC" => [ "NOT_USED",	"ECUADOR"],
       "EE" => [ "NOT_USED",	"ESTONIA"],
       "EG" => [ "NOT_USED",	"EGYPT"],
       "EH" => [ "NOT_USED",	"WESTERN SAHARA"],
       "ER" => [ "NOT_USED",	"ERITREA"],
       "ES" => [ "DVBT_DE",	"SPAIN"],
       "ET" => [ "NOT_USED",	"ETHIOPIA"],
       "FI" => [ "DVBT_DE",	"FINLAND"],
       "FJ" => [ "NOT_USED",	"FIJI"],
       "FK" => [ "NOT_USED",	"FALKLAND ISLANDS (MALVINAS)"],
       "FM" => [ "NOT_USED",	"MICRONESIA, FEDERATED STATES OF"],
       "FO" => [ "NOT_USED",	"FAROE ISLANDS"],
       "FR" => [ "DVBT_FR",	"FRANCE"],
       "GA" => [ "NOT_USED",	"GABON"],
       "GB" => [ "DVBT_GB",	"UNITED KINGDOM"],
       "GD" => [ "NOT_USED",	"GRENADA"],
       "GE" => [ "NOT_USED",	"GEORGIA"],
       "GF" => [ "NOT_USED",	"FRENCH GUIANA"],
       "GG" => [ "NOT_USED",	"GUERNSEY"],
       "GH" => [ "NOT_USED",	"GHANA"],
       "GI" => [ "NOT_USED",	"GIBRALTAR"],
       "GL" => [ "NOT_USED",	"GREENLAND"],
       "GM" => [ "NOT_USED",	"GAMBIA"],
       "GN" => [ "NOT_USED",	"GUINEA"],
       "GP" => [ "NOT_USED",	"GUADELOUPE"],
       "GQ" => [ "NOT_USED",	"EQUATORIAL GUINEA"],
       "GR" => [ "DVBT_DE",	"GREECE"],
       "GS" => [ "NOT_USED",	"SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS"],
       "GT" => [ "NOT_USED",	"GUATEMALA"],
       "GU" => [ "NOT_USED",	"GUAM"],
       "GW" => [ "NOT_USED",	"GUINEA-BISSAU"],
       "GY" => [ "NOT_USED",	"GUYANA"],
       "HK" => [ "DVBT_DE",	"HONG KONG"],
       "HM" => [ "NOT_USED",	"HEARD ISLAND AND MCDONALD ISLANDS"],
       "HN" => [ "NOT_USED",	"HONDURAS"],
       "HR" => [ "DVBT_DE",	"CROATIA"],
       "HT" => [ "NOT_USED",	"HAITI"],
       "HU" => [ "NOT_USED",	"HUNGARY"],
       "ID" => [ "NOT_USED",	"INDONESIA"],
       "IE" => [ "NOT_USED",	"IRELAND"],
       "IL" => [ "NOT_USED",	"ISRAEL"],
       "IM" => [ "NOT_USED",	"ISLE OF MAN"],
       "IN" => [ "NOT_USED",	"INDIA"],
       "IO" => [ "NOT_USED",	"BRITISH INDIAN OCEAN TERRITORY"],
       "IQ" => [ "NOT_USED",	"IRAQ"],
       "IR" => [ "NOT_USED",	"IRAN, ISLAMIC REPUBLIC OF"],
       "IS" => [ "DVBT_DE",	"ICELAND"],
       "IT" => [ "DVBT_DE",	"ITALY"],
       "JE" => [ "NOT_USED",	"JERSEY"],
       "JM" => [ "NOT_USED",	"JAMAICA"],
       "JO" => [ "NOT_USED",	"JORDAN"],
       "JP" => [ "NOT_USED",	"JAPAN"],
       "KE" => [ "NOT_USED",	"KENYA"],
       "KG" => [ "NOT_USED",	"KYRGYZSTAN"],
       "KH" => [ "NOT_USED",	"CAMBODIA"],
       "KI" => [ "NOT_USED",	"KIRIBATI"],
       "KM" => [ "NOT_USED",	"COMOROS"],
       "KN" => [ "NOT_USED",	"SAINT KITTS AND NEVIS"],
       "KP" => [ "NOT_USED",	"KOREA, DEMOCRATIC PEOPLE'S REPUBLIC OF"],
       "KR" => [ "NOT_USED",	"KOREA, REPUBLIC OF"],
       "KW" => [ "NOT_USED",	"KUWAIT"],
       "KY" => [ "NOT_USED",	"CAYMAN ISLANDS"],
       "KZ" => [ "NOT_USED",	"KAZAKHSTAN"],
       "LA" => [ "NOT_USED",	"LAO PEOPLE'S DEMOCRATIC REPUBLIC"],
       "LB" => [ "NOT_USED",	"LEBANON"],
       "LC" => [ "NOT_USED",	"SAINT LUCIA"],
       "LI" => [ "NOT_USED",	"LIECHTENSTEIN"],
       "LK" => [ "NOT_USED",	"SRI LANKA"],
       "LR" => [ "NOT_USED",	"LIBERIA"],
       "LS" => [ "NOT_USED",	"LESOTHO"],
       "LT" => [ "NOT_USED",	"LITHUANIA"],
       "LU" => [ "DVBT_DE",	"LUXEMBOURG"],
       "LV" => [ "DVBT_DE",	"LATVIA"],
       "LY" => [ "NOT_USED",	"LIBYAN ARAB JAMAHIRIYA"],
       "MA" => [ "NOT_USED",	"MOROCCO"],
       "MC" => [ "NOT_USED",	"MONACO"],
       "MD" => [ "NOT_USED",	"MOLDOVA"],
       "ME" => [ "NOT_USED",	"MONTENEGRO"],
       "MF" => [ "NOT_USED",	"SAINT MARTIN"],
       "MG" => [ "NOT_USED",	"MADAGASCAR"],
       "MH" => [ "NOT_USED",	"MARSHALL ISLANDS"],
       "MK" => [ "NOT_USED",	"MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF"],
       "ML" => [ "NOT_USED",	"MALI"],
       "MM" => [ "NOT_USED",	"MYANMAR"],
       "MN" => [ "NOT_USED",	"MONGOLIA"],
       "MO" => [ "NOT_USED",	"MACAO"],
       "MP" => [ "NOT_USED",	"NORTHERN MARIANA ISLANDS"],
       "MQ" => [ "NOT_USED",	"MARTINIQUE"],
       "MR" => [ "NOT_USED",	"MAURITANIA"],
       "MS" => [ "NOT_USED",	"MONTSERRAT"],
       "MT" => [ "NOT_USED",	"MALTA"],
       "MU" => [ "NOT_USED",	"MAURITIUS"],
       "MV" => [ "NOT_USED",	"MALDIVES"],
       "MW" => [ "NOT_USED",	"MALAWI"],
       "MX" => [ "NOT_USED",	"MEXICO"],
       "MY" => [ "NOT_USED",	"MALAYSIA"],
       "MZ" => [ "NOT_USED",	"MOZAMBIQUE"],
       "NA" => [ "NOT_USED",	"NAMIBIA"],
       "NC" => [ "NOT_USED",	"NEW CALEDONIA"],
       "NE" => [ "NOT_USED",	"NIGER"],
       "NF" => [ "NOT_USED",	"NORFOLK ISLAND"],
       "NG" => [ "NOT_USED",	"NIGERIA"],
       "NI" => [ "NOT_USED",	"NICARAGUA"],
       "NL" => [ "DVBT_DE",	"NETHERLANDS"],
       "NO" => [ "DVBT_DE",	"NORWAY"],
       "NP" => [ "NOT_USED",	"NEPAL"],
       "NR" => [ "NOT_USED",	"NAURU"],
       "NU" => [ "NOT_USED",	"NIUE"],
       "NZ" => [ "DVBT_DE",	"NEW ZEALAND"],
       "OM" => [ "NOT_USED",	"OMAN"],
       "PA" => [ "NOT_USED",	"PANAMA"],
       "PE" => [ "NOT_USED",	"PERU"],
       "PF" => [ "NOT_USED",	"FRENCH POLYNESIA"],
       "PG" => [ "NOT_USED",	"PAPUA NEW GUINEA"],
       "PH" => [ "NOT_USED",	"PHILIPPINES"],
       "PK" => [ "NOT_USED",	"PAKISTAN"],
       "PL" => [ "DVBT_DE",	"POLAND"],
       "PM" => [ "NOT_USED",	"SAINT PIERRE AND MIQUELON"],
       "PN" => [ "NOT_USED",	"PITCAIRN"],
       "PR" => [ "NOT_USED",	"PUERTO RICO"],
       "PS" => [ "NOT_USED",	"PALESTINIAN TERRITORY, OCCUPIED"],
       "PT" => [ "NOT_USED",	"PORTUGAL"],
       "PW" => [ "NOT_USED",	"PALAU"],
       "PY" => [ "NOT_USED",	"PARAGUAY"],
       "QA" => [ "NOT_USED",	"QATA"],
       "RE" => [ "NOT_USED",	"RÉUNION"],
       "RO" => [ "NOT_USED",	"ROMANIA"],
       "RS" => [ "NOT_USED",	"SERBIA"],
       "RU" => [ "NOT_USED",	"RUSSIAN FEDERATION"],
       "RW" => [ "NOT_USED",	"RWANDA"],
       "SA" => [ "NOT_USED",	"SAUDI ARABIA"],
       "SB" => [ "NOT_USED",	"SOLOMON ISLANDS"],
       "SC" => [ "NOT_USED",	"SEYCHELLES"],
       "SD" => [ "NOT_USED",	"SUDAN"],
       "SE" => [ "DVBT_DE",	"SWEDEN"],
       "SG" => [ "NOT_USED",	"SINGAPORE"],
       "SH" => [ "NOT_USED",	"SAINT HELENA"],
       "SI" => [ "NOT_USED",	"SLOVENIA"],
       "SJ" => [ "NOT_USED",	"SVALBARD AND JAN MAYEN"],
       "SK" => [ "DVBT_DE",	"SLOVAKIA"],
       "SL" => [ "NOT_USED",	"SIERRA LEONE"],
       "SM" => [ "NOT_USED",	"SAN MARINO"],
       "SN" => [ "NOT_USED",	"SENEGAL"],
       "SO" => [ "NOT_USED",	"SOMALIA"],
       "SR" => [ "NOT_USED",	"SURINAME"],
       "ST" => [ "NOT_USED",	"SAO TOME AND PRINCIPE"],
       "SV" => [ "NOT_USED",	"EL SALVADOR"],
       "SX" => [ "NOT_USED",	"SINT MAARTEN"],
       "SY" => [ "NOT_USED",	"SYRIAN ARAB REPUBLIC"],
       "SZ" => [ "NOT_USED",	"SWAZILAND"],
       "TC" => [ "NOT_USED",	"TURKS AND CAICOS ISLANDS"],
       "TD" => [ "NOT_USED",	"CHAD"],
       "TF" => [ "NOT_USED",	"FRENCH SOUTHERN TERRITORIES"],
       "TG" => [ "NOT_USED",	"TOGO"],
       "TH" => [ "NOT_USED",	"THAILAND"],
       "TJ" => [ "NOT_USED",	"TAJIKISTAN"],
       "TK" => [ "NOT_USED",	"TOKELAU"],
       "TL" => [ "NOT_USED",	"TIMOR-LESTE"],
       "TM" => [ "NOT_USED",	"TURKMENISTAN"],
       "TN" => [ "NOT_USED",	"TUNISIA"],
       "TO" => [ "NOT_USED",	"TONGA"],
       "TR" => [ "NOT_USED",	"TURKEY"],
       "TT" => [ "NOT_USED",	"TRINIDAD AND TOBAGO"],
       "TV" => [ "NOT_USED",	"TUVALU"],
       "TW" => [ "NOT_USED",	"TAIWAN"],
       "TZ" => [ "NOT_USED",	"TANZANIA, UNITED REPUBLIC OF"],
       "UA" => [ "NOT_USED",	"UKRAINE"],
       "UG" => [ "NOT_USED",	"UGANDA"],
       "UM" => [ "NOT_USED",	"UNITED STATES MINOR OUTLYING ISLANDS"],
       "US" => [ "NOT_USED",	"UNITED STATES"],
       "UY" => [ "NOT_USED",	"URUGUAY"],
       "UZ" => [ "NOT_USED",	"UZBEKISTAN"],
       "VA" => [ "NOT_USED",	"HOLY SEE (VATICAN CITY STATE)"],
       "VC" => [ "NOT_USED",	"SAINT VINCENT AND THE GRENADINES"],
       "VE" => [ "NOT_USED",	"VENEZUELA"],
       "VG" => [ "NOT_USED",	"VIRGIN ISLANDS, BRITISH"],
       "VI" => [ "NOT_USED",	"VIRGIN ISLANDS, U.S."],
       "VN" => [ "NOT_USED",	"VIET NAM"],
       "VU" => [ "NOT_USED",	"VANUATU"],
       "WF" => [ "NOT_USED",	"WALLIS AND FUTUNA"],
       "WS" => [ "NOT_USED",	"SAMOA"],
       "YE" => [ "NOT_USED",	"YEMEN"],
       "YT" => [ "NOT_USED",	"MAYOTTE"],
       "ZA" => [ "NOT_USED",	"SOUTH AFRICA"],
       "ZM" => [ "NOT_USED",	"ZAMBIA"],
       "ZW" => [ "NOT_USED",	"ZIMBABWE"],
) ;


our %BASE_FREQ = (
	'NOT_USED'		=> [],
	'DVBT_AU'		=> [
		{'min'=>5, 	'max'=>12,	'freq'=> 142500000},
		{'min'=>21,	'max'=>69,	'freq'=> 333500000},
	],
	'DVBT_DE'		=> [
		{'min'=>5, 	'max'=>12,	'freq'=> 142500000},
		{'min'=>21,	'max'=>69,	'freq'=> 306000000},
	],
	'DVBT_FR'		=> [
		{'min'=>5, 	'max'=>12,	'freq'=> 142500000},
		{'min'=>21,	'max'=>69,	'freq'=> 306000000},
	],
	'DVBT_GB'		=> [
		{'min'=>5, 	'max'=>12,	'freq'=> 142500000},
		{'min'=>21,	'max'=>69,	'freq'=> 306000000},
	],
) ;

our %FREQ_STEP = (
	'NOT_USED'		=> [],
	'DVBT_AU'		=> [
		{'min'=>5, 	'max'=>69,	'freq'=> 7000000,	'bw'=>7},
	],
	'DVBT_DE'		=> [
		{'min'=>5, 	'max'=>12,	'freq'=> 7000000,	'bw'=>7},
		{'min'=>21,	'max'=>69,	'freq'=> 8000000,	'bw'=>8},
	],
	'DVBT_FR'		=> [
		{'min'=>5, 	'max'=>12,	'freq'=> 7000000,	'bw'=>7},
		{'min'=>21,	'max'=>69,	'freq'=> 8000000,	'bw'=>8},
	],
	'DVBT_GB'		=> [
		{'min'=>5, 	'max'=>12,	'freq'=> 7000000,	'bw'=>7},
		{'min'=>21,	'max'=>69,	'freq'=> 8000000,	'bw'=>8},
	],
) ;


our %FREQ_OFFSET = (
	'NOT_USED'		=> [],
	'DVBT_AU'		=> [
		{'min'=>5,	'max'=>69,	'offset_min'=> 0,		'offset_max'=>125000},
	],
	'DVBT_DE'		=> [
		{'min'=>5,	'max'=>69,	'offset_min'=> 0,		'offset_max'=>0},
	],
	'DVBT_FR'		=> [
		{'min'=>5, 	'max'=>12,	'offset_min'=> 0,		'offset_max'=>0},
		{'min'=>21,	'max'=>69,	'offset_min'=> -167000,	'offset_max'=>167000},
	],
	'DVBT_GB'		=> [
		{'min'=>5, 	'max'=>12,	'offset_min'=> 0,		'offset_max'=>0},
		{'min'=>21,	'max'=>69,	'offset_min'=> -167000,	'offset_max'=>167000},
	],
) ;



#============================================================================================

=head2 Functions

=over 4

=cut


#-----------------------------------------------------------------------------

=item B<country_supported($iso3166)>

Returns TRUE if the specified ISO 3166-1 country code is for a country that has DVB-T

=cut

sub country_supported
{
	my ($iso3166) = @_ ;
	my $supported = 0 ;

	$iso3166 ||= "" ;
	$iso3166 = uc $iso3166 ;
	if ($iso3166 && exists($COUNTRY_LIST{$iso3166}))
	{
		my ($chan_type, $country) = @{$COUNTRY_LIST{$iso3166}} ;
		if ($chan_type ne 'NOT_USED')
		{
			$supported = 1 ;
		}
	}
	return $supported ;
}

#-----------------------------------------------------------------------------

=item B<country_list()>

Returns the array of countries which have DVB-T information. Each array entry consists of
an array containing 2 elements:

	[0] => iso3166-1 country code (e.g. 'GB')
	[1] => country name (e.g. "UNITED KINGDOM")

=cut

sub country_list
{
	my @list ;
	foreach my $code (sort keys %COUNTRY_LIST)
	{
		my ($chan_type, $country) = @{$COUNTRY_LIST{$code}} ;
		if ($chan_type ne 'NOT_USED')
		{
			push @list, [$code, $country] ;
		}
	}
	return @list ;
}


#-----------------------------------------------------------------------------

=item B<freq_list($iso3166)>

Create a list of frequencies for the specified country code.

Returns an array of frequencies (or an empty list).

=cut

sub freq_list
{
	my ($iso3166) = @_ ;
	
	my @freqs ;
	my @freq_list = chan_freq_list($iso3166) ;
	
	foreach my $href (@freq_list)
	{
		push @freqs, $href->{'freq'} ;
	}
	
	return @freqs ;
}

#-----------------------------------------------------------------------------

=item B<chan_freq_list($iso3166)>

Create a list of channel numbers and frequencies for the specified country code.

Returns an array of HASHes, each hash containing:

	'chan'	=> channel number
	'freq'	=> frequency in Hz

=cut

sub chan_freq_list
{
	my ($iso3166) = @_ ;
	my @freqs ;
	
	if (country_supported($iso3166))
	{
		$iso3166 = uc $iso3166 ;
		my ($chan_type, $country) = @{$COUNTRY_LIST{$iso3166}} ;
		
		my $base_freq_list = $BASE_FREQ{$chan_type} ;
		my $freq_step_list = $FREQ_STEP{$chan_type} ;
		my $freq_offset_list = $FREQ_OFFSET{$chan_type} ;
			
		foreach my $freq_href (@$base_freq_list)
		{
			my $base_freq = $freq_href->{'freq'} ;
			for (my $chan = $freq_href->{'min'}; $chan <= $freq_href->{'max'}; ++$chan)
			{
				my ($freq_step, $bw) = _lookup_freq_step($chan, $freq_step_list) ;
				my ($offset_min, $offset_max) = _lookup_freq_offset($chan, $freq_offset_list) ;
				
				my @offsets = (0) ;
				unshift(@offsets, $offset_min) if ($offset_min < 0) ;
				push(@offsets, $offset_max) if ($offset_max < 0) ;
				
				foreach my $offset (@offsets)
				{
					my $frequency = $base_freq + ($chan * $freq_step) + $offset ;
					push @freqs, {
						'chan'	=> $chan,
						'freq'	=> $frequency,	
						'bw'	=> $bw,	
					} ;
				}
			}
		}
	}
	
	return @freqs ;
}

#-----------------------------------------------------------------------------
sub _lookup_freq_step
{
	my ($chan, $freq_step_list) = @_ ;
	my $freq_step = 8000000 ;
	my $bw = 8 ;
	
	foreach my $freq_href (@$freq_step_list)
	{
		if  ( ($chan >= $freq_href->{'min'}) && ($chan <= $freq_href->{'max'}) )
		{
			$freq_step = $freq_href->{'freq'} ;
			$bw = $freq_href->{'bw'} ;
			last ;
		}
	}
	return wantarray ?  ($freq_step, $bw) : $freq_step ;
}

#-----------------------------------------------------------------------------
sub _lookup_freq_offset
{
	my ($chan, $freq_offset_list) = @_ ;
	my $min = 0 ;
	my $max = 0 ;
	
	foreach my $freq_href (@$freq_offset_list)
	{
		if  ( ($chan >= $freq_href->{'min'}) && ($chan <= $freq_href->{'max'}) )
		{
			$min = $freq_href->{'offset_min'} ;
			$max = $freq_href->{'offset_max'} ;
			last ;
		}
	}
	return ($min, $max) ;
}


# ============================================================================================
# END OF PACKAGE

=back

=cut

1;

