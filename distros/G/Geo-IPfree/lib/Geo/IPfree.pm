package Geo::IPfree;
use 5.006;
use strict;
use warnings;

use Carp qw();

require Exporter;
our @ISA = qw(Exporter);

our $VERSION = '1.160000';    # VERSION

# ABSTRACT: Geo::IPfree - Look up the country of an IPv4 address

our @EXPORT    = qw(LookUp LoadDB);
our @EXPORT_OK = @EXPORT;

my $DEFAULT_DB   = 'ipscountry.dat';
my $cache_expire = 5000;
my @baseX        = (
    0 .. 9,
    'A' .. 'Z',
    'a' .. 'z',
    split( m{}, q(.,;'"`<>{}[]=+-~*@#%$&!?) )
);

my ( %baseX, $base, $THIS, %countrys, $base0, $base1, $base2, $base3, $base4 );

{
    my $c = 0;
    %baseX = map { $_ => ( $c++ ) } @baseX;
    $base  = @baseX;
    $base0 = $base**0;
    $base1 = $base**1;
    $base2 = $base**2;
    $base3 = $base**3;
    $base4 = $base**4;

    my @data;
    while (<DATA>) {
        last if m{^__END__};
        chomp;
        push @data, split m{ }, $_, 2;
    }
    %countrys = @data;
}

sub new {
    my ( $class, $db_file ) = @_;

    if ( !defined $_[0] || $_[0] !~ /^[\w:]+$/ ) {
        $class   = 'Geo::IPfree';
        $db_file = $_[0];
    }

    my $this = bless( {}, $class );

    if ( !defined $db_file ) { $db_file = _find_db_file(); }

    $this->LoadDB($db_file);

    $this->Clean_Cache();
    $this->{cache} = 1;

    return $this;
}

sub get_all_countries {
    return {%countrys};    # copy
}

sub _find_db_file {
    my @locations = (
        qw(/usr/local/share /usr/local/share/GeoIPfree),
        map { $_, "$_/Geo" } @INC
    );

    # lastly, find where this module was loaded, and try that dir
    my ($lib) = ( $INC{'Geo/IPfree.pm'} =~ /^(.*?)[\\\/]+[^\\\/]+$/gs );
    push @locations, $lib;

    for my $file ( map { "$_/$DEFAULT_DB" } @locations ) {
        return $file if -e $file;
    }
}

sub LoadDB {
    my $this = shift;
    my ($db_file) = @_;

    if ( -d $db_file ) { $db_file .= "/$DEFAULT_DB"; }

    if ( !-s $db_file ) {
        Carp::croak("Can't load database, blank or not there: $db_file");
    }

    my $buffer = '';
    open( my $handler, '<', $db_file )
      || Carp::croak("Failed to open database file $db_file for read!");
    binmode($handler);
    $this->{dbfile} = $db_file;

    delete $this->{pos} if $this->{pos};

    while ( read( $handler, $buffer, 1, length($buffer) ) ) {
        if ( $buffer =~ /##headers##(\d+)##$/s ) {
            my $headers;
            read( $handler, $headers, $1 );
            my (%head) = ( $headers =~ /(\d+)=(\d+)/gs );
            $this->{pos}{$_} = $head{$_} for keys %head;
            $buffer = '';
        }
        elsif ( $buffer =~ /##start##$/s ) {
            $this->{start} = tell($handler);
            last;
        }
    }

    $this->{searchorder} = [ sort { $a <=> $b } keys %{ $this->{pos} } ];
    $this->{handler}     = $handler;
}

sub LookUp {
    my $this;

    if ( $#_ == 0 ) {
        if ( !$THIS ) { $THIS = Geo::IPfree->new(); }
        $this = $THIS;
    }
    else { $this = shift; }

    my ($ip) = @_;

    $ip =~ s/\.+/\./gs      if index( $ip, '..' ) > -1;
    substr( $ip, 0, 1, '' ) if substr( $ip, 0, 1 ) eq '.';
    chop $ip                if substr( $ip, -1 ) eq '.';

    if ( $ip !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ ) {
        $ip = nslookup($ip);
    }

    return unless length $ip;

    ## Since the last class is always from the same country, will try 0 and cache 0:
    my $ip_class = $ip;
    $ip_class =~ s/\.\d+$/\.0/;

    if ( $this->{cache} && $this->{CACHE}{$ip_class} ) {
        return ( @{ $this->{CACHE}{$ip_class} }, $ip_class );
    }

    my $ipnb = ip2nb($ip_class);

    my $buf_pos = 0;

    foreach my $Key ( @{ $this->{searchorder} } ) {
        if ( $ipnb <= $Key ) { $buf_pos = $this->{pos}{$Key}; last; }
    }

    my ( $buffer, $country, $iprange, $basex2 );

    ## Will use the DB in the memory:
    if ( $this->{FASTER} ) {
        my $base_cache = $this->{'baseX2dec'} ||= {};
        while ( $buf_pos < $this->{DB_SIZE} ) {
            if ( $ipnb >= ( $base_cache->{ ( $basex2 = substr( $this->{DB}, $buf_pos + 2, 5 ) ) } ||= baseX2dec($basex2) ) ) {
                $country = substr( $this->{DB}, $buf_pos, 2 );
                last;
            }
            $buf_pos += 7;
        }
        $country ||= substr( $this->{DB}, $buf_pos - 7, 2 );
    }
    ## Will read the DB in the disk:
    else {
        seek( $this->{handler}, 0, 0 )
          if $] < 5.006001;    ## Fix bug on Perl 5.6.0
        seek( $this->{handler}, $buf_pos + $this->{start}, 0 );
        while ( read( $this->{handler}, $buffer, 7 ) ) {
            if ( $ipnb >= baseX2dec( substr( $buffer, 2 ) ) ) {
                $country = substr( $buffer, 0, 2 );
                last;
            }
        }
    }

    if ( $this->{cache} ) {
        if ( $this->{CACHE_COUNT} > $cache_expire ) {
            keys %{ $this->{CACHE} };
            my ($d_key) = each( %{ $this->{CACHE} } );
            delete $this->{CACHE}{$d_key};
        }
        else {
            $this->{CACHE_COUNT}++;
        }
        $this->{CACHE}{$ip_class} = [ $country, $countrys{$country} ];
    }

    return ( $country, $countrys{$country}, $ip_class );
}

sub Faster {
    my $this    = shift;
    my $handler = $this->{handler};

    seek( $handler, 0,              0 );    ## Fix bug on Perl 5.6.0
    seek( $handler, $this->{start}, 0 );

    $this->{DB}      = do { local $/; <$handler>; };
    $this->{DB_SIZE} = length( $this->{DB} );
    $this->{FASTER}  = 1;
}

sub Clean_Cache {
    my $this = shift;
    $this->{CACHE_COUNT} = 0;
    delete $this->{CACHE};
    delete $this->{'baseX2dec'};
    return 1;
}

sub nslookup {
    my ( $host, $last_lookup ) = @_;
    require Socket;
    my $iaddr = Socket::inet_aton($host) || '';
    my @ip    = unpack( 'C4', $iaddr );

    return nslookup( "www.${host}", 1 ) if !@ip && !$last_lookup;
    return join( '.', @ip );
}

sub ip2nb {
    my @ip = split( /\./, $_[0] );
    return ( $ip[0] << 24 ) + ( $ip[1] << 16 ) + ( $ip[2] << 8 ) + $ip[3];
}

sub nb2ip {
    my ($input) = @_;
    my @ip;

    while ( $input > 1 ) {
        my $int = int( $input / 256 );
        push @ip, $input - ( $int << 8 );
        $input = $int;
    }

    push @ip, $input if $input > 0;
    push @ip, (0) x ( 4 - @ip );

    return join( '.', reverse @ip );
}

sub dec2baseX {
    my ($dec) = @_;
    my @base;

    while ( $dec > 1 ) {
        my $int = int( $dec / $base );
        push @base, $dec - $int * $base;
        $dec = $int;
    }

    push @base, $dec if $dec > 0;
    push @base, (0) x ( 5 - @base );

    return join( '', map { $baseX[$_] } reverse @base );
}

sub baseX2dec {
    my $string = reverse $_[0];
    my $length = length $string;
    return    #
      (
        0 + ( $length > 4 ? ( $baseX{ substr( $string, 4, 1 ) } * $base4 ) : 0 ) +    #
          ( $length > 3 ? ( $baseX{ substr( $string, 3, 1 ) } * $base3 ) : 0 ) +      #
          ( $length > 2 ? ( $baseX{ substr( $string, 2, 1 ) } * $base2 ) : 0 ) +      #
          ( $length > 1 ? ( $baseX{ substr( $string, 1, 1 ) } * $base1 ) : 0 ) +      #
          ( $length     ? ( $baseX{ substr( $string, 0, 1 ) } * $base0 ) : 0 )        #
      );                                                                              #
}

1;

=pod

=encoding UTF-8

=head1 NAME

Geo::IPfree - Geo::IPfree - Look up the country of an IPv4 address

=head1 VERSION

version 1.160000

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Graciliano M. P.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
-- N/A
L0 localhost
I0 IntraNet
A1 Anonymous Proxy
A2 Satellite Provider
AC Ascension Island
AD Andorra
AE United Arab Emirates
AF Afghanistan
AG Antigua and Barbuda
AI Anguilla
AL Albania
AM Armenia
AN Netherlands Antilles
AO Angola
AP Asia/Pacific Region
AQ Antarctica
AR Argentina
AS American Samoa
AT Austria
AU Australia
AW Aruba
AX Aland Islands
AZ Azerbaijan
BA Bosnia and Herzegovina
BB Barbados
BD Bangladesh
BE Belgium
BF Burkina Faso
BG Bulgaria
BH Bahrain
BI Burundi
BJ Benin
BL Saint Barthelemy
BM Bermuda
BN Brunei Darussalam
BO Bolivia, Plurinational State of
BQ Bonaire, Sint Eustatius and Saba
BR Brazil
BS Bahamas
BT Bhutan
BU Burma
BV Bouvet Island
BW Botswana
BY Belarus
BZ Belize
CA Canada
CC Cocos (Keeling) Islands
CD Congo, The Democratic Republic of the
CF Central African Republic
CG Congo
CH Switzerland
CI Cote d'Ivoire
CK Cook Islands
CL Chile
CM Cameroon
CN China
CO Colombia
CP Clipperton Island
CR Costa Rica
CS Serbia and Montenegro
CU Cuba
CV Cape Verde
CW Curacao
CX Christmas Island
CY Cyprus
CZ Czech Republic
DE Germany
DJ Djibouti
DK Denmark
DM Dominica
DO Dominican Republic
DZ Algeria
EC Ecuador
EE Estonia
EG Egypt
EH Western Sahara
ER Eritrea
ES Spain
ET Ethiopia
EU Europe
FI Finland
FJ Fiji
FK Falkland Islands (Malvinas)
FM Micronesia, Federated States of
FO Faroe Islands
FR France
FX France Metropolitan
GA Gabon
GB United Kingdom
GD Grenada
GE Georgia
GF French Guiana
GG Guernsey
GH Ghana
GI Gibraltar
GL Greenland
GM Gambia
GN Guinea
GP Guadeloupe
GQ Equatorial Guinea
GR Greece
GS South Georgia and the South Sandwich Islands
GT Guatemala
GU Guam
GW Guinea-Bissau
GY Guyana
HK Hong Kong
HM Heard Island and McDonald Islands
HN Honduras
HR Croatia
HT Haiti
HU Hungary
ID Indonesia
IE Ireland
IL Israel
IM Isle of Man
IN India
IO British Indian Ocean Territory
IQ Iraq
IR Iran, Islamic Republic of
IS Iceland
IT Italy
JE Jersey
JM Jamaica
JO Jordan
JP Japan
KE Kenya
KG Kyrgyzstan
KH Cambodia
KI Kiribati
KM Comoros
KN Saint Kitts and Nevis
KP Korea, Democratic People's Republic of
KR Korea, Republic of
KW Kuwait
KY Cayman Islands
KZ Kazakhstan
LA Lao People's Democratic Republic
LB Lebanon
LC Saint Lucia
LI Liechtenstein
LK Sri Lanka
LR Liberia
LS Lesotho
LT Lithuania
LU Luxembourg
LV Latvia
LY Libya
MA Morocco
MC Monaco
MD Moldova, Republic of
ME Montenegro
MF Saint Martin (French part)
MG Madagascar
MH Marshall Islands
MK Macedonia, the Former Yugoslav Republic of
ML Mali
MM Myanmar
MN Mongolia
MO Macao
MP Northern Mariana Islands
MQ Martinique
MR Mauritania
MS Montserrat
MT Malta
MU Mauritius
MV Maldives
MW Malawi
MX Mexico
MY Malaysia
MZ Mozambique
NA Namibia
NC New Caledonia
NE Niger
NF Norfolk Island
NG Nigeria
NI Nicaragua
NL Netherlands
NO Norway
NP Nepal
NR Nauru
NU Niue
NZ New Zealand
OM Oman
PA Panama
PE Peru
PF French Polynesia
PG Papua New Guinea
PH Philippines
PK Pakistan
PL Poland
PM Saint Pierre and Miquelon
PN Pitcairn
PR Puerto Rico
PS Palestine, State of
PT Portugal
PW Palau
PY Paraguay
QA Qatar
RE Reunion
RO Romania
RS Serbia
RU Russian Federation
RW Rwanda
SA Saudi Arabia
SB Solomon Islands
SC Seychelles
SD Sudan
SE Sweden
SF Finland
SG Singapore
SH Saint Helena, Ascension and Tristan da Cunha
SI Slovenia
SJ Svalbard and Jan Mayen
SK Slovakia
SL Sierra Leone
SM San Marino
SN Senegal
SO Somalia
SR Suriname
SS South Sudan
ST Sao Tome and Principe
SV El Salvador
SX Sint Maarten (Dutch part)
SY Syrian Arab Republic
SZ Swaziland
TC Turks and Caicos Islands
TD Chad
TF French Southern Territories
TG Togo
TH Thailand
TJ Tajikistan
TK Tokelau
TL Timor-Leste
TM Turkmenistan
TN Tunisia
TO Tonga
TP East Timor
TR Turkey
TT Trinidad and Tobago
TV Tuvalu
TW Taiwan, Province of China
TZ Tanzania, United Republic of
UA Ukraine
UG Uganda
UK United Kingdom
UM United States Minor Outlying Islands
US United States
UY Uruguay
UZ Uzbekistan
VA Holy See (Vatican City State)
VC Saint Vincent and the Grenadines
VE Venezuela, Bolivarian Republic of
VG Virgin Islands, British
VI Virgin Islands, U.S.
VN Viet Nam
VU Vanuatu
WF Wallis and Futuna
WS Samoa
XK Kosovo
YE Yemen
YT Mayotte
YU Serbia and Montenegro (Formally Yugoslavia)
ZA South Africa
ZM Zambia
ZR Zaire
ZW Zimbabwe
ZZ Reserved for private IP addresses
__END__
