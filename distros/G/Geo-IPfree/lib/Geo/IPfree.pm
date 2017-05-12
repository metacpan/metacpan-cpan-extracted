package Geo::IPfree;
use 5.006;
use strict;
use warnings;

use Memoize;
use Carp qw();

require Exporter;
our @ISA = qw(Exporter);

our $VERSION = '1.151940';

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

my ( %baseX, $base, $THIS, %countrys );

{
    my $c = 0;
    %baseX = map { $_ => ( $c++ ) } @baseX;
    $base = @baseX;

    my @data;
    while ( <DATA> ) {
        last if m{^__END__};
        chomp;
        push @data, split m{ }, $_, 2;
    }
    %countrys = @data;
}

sub new {
    my ( $class, $db_file ) = @_;

    if ( !defined $_[ 0 ] || $_[ 0 ] !~ /^[\w:]+$/ ) {
        $class   = 'Geo::IPfree';
        $db_file = $_[ 0 ];
    }

    my $this = bless( {}, $class );

    if ( !defined $db_file ) { $db_file = _find_db_file(); }

    $this->LoadDB( $db_file );

    $this->Clean_Cache();
    $this->{ cache } = 1;

    return $this;
}

sub _find_db_file {
    my @locations = (
        qw(/usr/local/share /usr/local/share/GeoIPfree),
        map { $_, "$_/Geo" } @INC
    );

    # lastly, find where this module was loaded, and try that dir
    my ( $lib ) = ( $INC{ 'Geo/IPfree.pm' } =~ /^(.*?)[\\\/]+[^\\\/]+$/gs );
    push @locations, $lib;

    for my $file ( map { "$_/$DEFAULT_DB" } @locations ) {
        return $file if -e $file;
    }
}

sub LoadDB {
    my $this = shift;
    my ( $db_file ) = @_;

    if ( -d $db_file ) { $db_file .= "/$DEFAULT_DB"; }

    if ( !-s $db_file ) {
        Carp::croak( "Can't load database, blank or not there: $db_file" );
    }

    my $buffer = '';
    open( my $handler, '<', $db_file )
        || Carp::croak( "Failed to open database file $db_file for read!" );
    binmode( $handler );
    $this->{ dbfile } = $db_file;

    delete $this->{ pos } if $this->{ pos };

    while ( read( $handler, $buffer, 1, length( $buffer ) ) ) {
        if ( $buffer =~ /##headers##(\d+)##$/s ) {
            my $headers;
            read( $handler, $headers, $1 );
            my ( %head ) = ( $headers =~ /(\d+)=(\d+)/gs );
            $this->{ pos }{ $_ } = $head{ $_ } for keys %head;
            $buffer = '';
        }
        elsif ( $buffer =~ /##start##$/s ) {
            $this->{ start } = tell( $handler );
            last;
        }
    }

    $this->{ searchorder } = [ sort { $a <=> $b } keys %{ $this->{ pos } } ];
    $this->{ handler } = $handler;
}

sub LookUp {
    my $this;

    if ( $#_ == 0 ) {
        if ( !$THIS ) { $THIS = Geo::IPfree->new(); }
        $this = $THIS;
    }
    else { $this = shift; }

    my ( $ip ) = @_;

    $ip =~ s/\.+/\./gs;
    $ip =~ s/^\.//;
    $ip =~ s/\.$//;

    if ( $ip !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ ) {
        $ip = nslookup( $ip );
    }

    return unless length $ip;

    ## Since the last class is always from the same country, will try 0 and cache 0:
    my $ip_class = $ip;
    $ip_class =~ s/\.\d+$/\.0/;

    if ( $this->{ cache } && $this->{ CACHE }{ $ip_class } ) {
        return ( @{ $this->{ CACHE }{ $ip_class } }, $ip_class );
    }

    my $ipnb = ip2nb( $ip_class );

    my $buf_pos = 0;

    foreach my $Key ( @{ $this->{ searchorder } } ) {
        if ( $ipnb <= $Key ) { $buf_pos = $this->{ pos }{ $Key }; last; }
    }

    my ( $buffer, $country, $iprange );

    ## Will use the DB in the memory:
    if ( $this->{ FASTER } ) {
        while ( $buf_pos < $this->{ DB_SIZE } ) {
            $buffer  = substr( $this->{ DB }, $buf_pos, 7 );
            $country = substr( $buffer,       0,        2 );
            $iprange = baseX2dec( substr( $buffer, 2, 5 ) );
            $buf_pos += 7;
            last if $ipnb >= $iprange;
        }
    }
    ## Will read the DB in the disk:
    else {
        seek( $this->{ handler }, 0, 0 )
            if $] < 5.006001;    ## Fix bug on Perl 5.6.0
        seek( $this->{ handler }, $buf_pos + $this->{ start }, 0 );
        while ( read( $this->{ handler }, $buffer, 7 ) ) {
            $country = substr( $buffer, 0, 2 );
            $iprange = baseX2dec( substr( $buffer, 2 ) );
            last if $ipnb >= $iprange;
        }
    }

    if ( $this->{ cache } ) {
        if( $this->{ CACHE_COUNT } > $cache_expire ) {
            keys %{ $this->{ CACHE } };
            my( $d_key ) = each( %{ $this->{ CACHE } } );
            delete $this->{ CACHE }{ $d_key };
        }
        else {
            $this->{ CACHE_COUNT }++;
        }
        $this->{ CACHE }{ $ip_class } = [ $country, $countrys{ $country } ];
    }

    return ( $country, $countrys{ $country }, $ip_class );
}

sub Faster {
    my $this = shift;
    my $handler = $this->{ handler };

    seek( $handler, 0, 0 );                 ## Fix bug on Perl 5.6.0
    seek( $handler, $this->{ start }, 0 );

    $this->{ DB } = do { local $/; <$handler>; };
    $this->{ DB_SIZE } = length( $this->{ DB } );

    memoize( 'dec2baseX' );
    memoize( 'baseX2dec' );

    $this->{ FASTER } = 1;
}

sub Clean_Cache {
    my $this = shift;
    $this->{ CACHE_COUNT } = 0;
    delete $this->{ CACHE };
    return 1;
}

sub nslookup {
    my ( $host, $last_lookup ) = @_;
    require Socket;
    my $iaddr = Socket::inet_aton( $host ) || '';
    my @ip = unpack( 'C4', $iaddr );

    return nslookup( "www.${host}", 1 ) if !@ip && !$last_lookup;
    return join( '.', @ip );
}

sub ip2nb {
    my @ip = split( /\./, $_[ 0 ] );
    return ( $ip[ 0 ] << 24 ) + ( $ip[ 1 ] << 16 ) + ( $ip[ 2 ] << 8 )
        + $ip[ 3 ];
}

sub nb2ip {
    my ( $input ) = @_;
    my @ip;

    while ( $input > 1 ) {
        my $int = int( $input / 256 );
        push @ip, $input - ( $int << 8 );
        $input = $int;
    }

    push @ip, $input if $input > 0;
    push @ip, ( 0 ) x ( 4 - @ip );

    return join( '.', reverse @ip );
}

sub dec2baseX {
    my ( $dec ) = @_;
    my @base;

    while ( $dec > 1 ) {
        my $int = int( $dec / $base );
        push @base, $dec - $int * $base;
        $dec = $int;
    }

    push @base, $dec if $dec > 0;
    push @base, ( 0 ) x ( 5 - @base );

    return join( '', map { $baseX[ $_ ] } reverse @base );
}

sub baseX2dec {
    my ( $input ) = @_;

    my @digits = reverse split( '', $input );
    my $dec = 0;

    foreach ( 0 .. @digits - 1 ) {
        $dec += $baseX{ $digits[ $_ ] } * ( $base**$_ );
    }

    return $dec;
}

1;

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
YE Yemen
YT Mayotte
YU Serbia and Montenegro (Formally Yugoslavia)
ZA South Africa
ZM Zambia
ZR Zaire
ZW Zimbabwe
ZZ Reserved for private IP addresses
__END__

=head1 NAME

Geo::IPfree - Look up the country of an IPv4 address

=head1 SYNOPSIS

    use Geo::IPfree;
    
    my $geo = Geo::IPfree->new;
    my( $code1, $name1 ) = $geo->LookUp( '200.176.3.142' );
    
    # use memory to speed things up
    $geo->Faster;
    
    # lookup by hostname
    my( $code2, $name2, $ip2 ) = $geo->LookUp( 'www.cnn.com' );

=head1 DESCRIPTION

Geo::IPfree is a Perl module that determines the originating country of an
arbitrary IPv4 address. It uses a local file-based database to provide basic
geolocation services.

An updated version of the database can be obtained by visiting the Webnet77 
website: L<http://software77.net/geo-ip/>.
  
=head1 METHODS

=head2 new( [$db] )

Creates a new Geo::IPfree instance. Optionally, a database filename may be
passed in to load a custom data set rather than the version shipped with the
module.

=head2 LoadDB( $filename )

Load a specific database to use to look up the IP addresses.

=head2 LookUp( $ip | $hostname )

Given an IP address or a hostname, this function returns three things:

=over 4

=item * The ISO 3166 country code (2 chars)

=item * The country name

=item * The IP address resolved

=back

B<NB:> In order to use the location services on a hostname, you will need
to have an internet connection to resolve a host to an IP address.

If you pass a private IP address (for example 192.168.0.1), you'll get back a country
code of ZZ, and country name of "Reserved for private IP addresses".

=head2 Clean_Cache( )

Clears any cached lookup data.

=head2 Faster( )

Make the LookUp() faster, which is good if you're going to be calling Lookup() many times. This will load the entire DB into memory and read from there,
not from disk (good way for slow disk or network disks), but use more memory. The module "Memoize" will be enabled for some internal functions too.

Note that if you call Lookup() many times, you'll end up using a lot of memory anyway, so you'll be better off using a lot of memory from the start by calling Faster(),
and getting an improvement for all calls.

=head2 nslookup( $host, [$last_lookup] )

Attempts to resolve a hostname to an IP address. If it fails on the first pass
it will attempt to resolve the same hostname with 'www.' prepended. C<$last_lookup>
is used to suppress this behavior.

=head2 ip2nb( $ip )

Encodes C<$ip> into a numerical representation.

=head2 nb2ip( $number )

Decodes C<$number> back to an IP address.

=head2 dec2baseX( $number )

Converts a base 10 (decimal) number to base 86.

=head2 baseX2dec( $number )

Converts a base 86 number to base 10 (decimal).

=head1 VARS

=over 4

=item $GeoIP->{db}

The database file in use.

=item $GeoIP->{handler}

The database file handler.

=item $GeoIP->{dbfile}

The database file path.

=item $GeoIP->{cache} BOOLEAN

Set/tell if the cache of LookUp() is on. If it's on it will cache the last 5000 queries. Default: 1

The cache is good when you are parsing a list of IPs, generally a web log.
If in the log you have many lines with the same IP, GEO::IPfree won't have to make a full search for each query,
it will cache the last 5000 different IPs. After 5000 IPs an existing IP is removed from the cache and the new
data is stored.

Note that the Lookup make the query without the last IP number (xxx.xxx.xxx.0),
then the cache for the IP 192.168.0.1 will be the same for 192.168.0.2 (they are the same query, 192.168.0.0).

=back

=head1 DB FORMAT

The data file has a list of IP ranges & countries, for example, from 200.128.0.0 to
200.103.255.255 the IPs are from BR. To make a fast access to the DB the format
tries to use less bytes per input (block). The file was in ASCII and in blocks
of 7 bytes: XXnnnnn

  XX    -> the country code (BR,US...)
  nnnnn -> the IP range using a base of 85 digits
           (not in dec or hex to get space).

See CPAN for updates of the DB...

=head1 NOTES

The file ipscountry.dat is a dedicated format for Geo::IPfree.
To convert it see the tool "ipct2txt.pl" in the C<misc> directoy.

The module looks for C<ipscountry.dat> in the following locations:

=over 4

=item * /usr/local/share

=item * /usr/local/share/GeoIPfree

=item * through @INC (as well as all @INC directories plus "/Geo")

=item * from the same location that IPfree.pm was loaded

=back

=head1 SEE ALSO

=over 4

=item * http://software77.net/geo-ip/

=back

=head1 AUTHOR

Graciliano M. P. E<lt>gm@virtuasites.com.brE<gt>

=head1 MAINTAINER

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 THANK YOU

Thanks to Laurent Destailleur (author of AWStats) that tested it on many OS and
fixed bugs for them, like the not portable sysread, and asked for some speed improvement.

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
