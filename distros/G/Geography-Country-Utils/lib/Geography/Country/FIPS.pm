#                              -*- Mode: Perl -*- 
################### Original code was by
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Mon Aug 28 16:37:39 1995
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Mar 24 14:21:39 1996
# Language        : Perl
# Update Count    : 5
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1995, Universität Dortmund, all rights reserved.
# 
# HISTORY
# 
# $Locker: pfeifer $
# $Log: Country.pm,v $
# Revision 0.1.1.1  1996/03/25 11:19:18  pfeifer
# patch1:
#
# Revision 1.1  1996/03/24 13:33:52  pfeifer
# Initial revision
#
# 
######### Changed database to FIPS, renamed to a new module
# BUG: iso2fips will yield wrong answers with Yemen, Virgin Islands
# or simillar countries with doubles

package Geography::Country::FIPS;

require Exporter;
@EXPORT_OK = qw(Name Code country2fips fips2country iso2fips fips2iso);
@ISA = qw(Exporter);

$VERSION = 1.06;

sub DATA ();
foreach (split(/\n/, +DATA())) {
    ($cc, $rest) = split(' ', $_, 2);
    next unless $cc;
    $country{$cc} = $rest;
    $rest =~ s/\s*\(.*\)\s*$//;
    $rest =~ s/,.*$//;
    $cross{lc($rest)} = $cc;
}

sub Name { goto &country2fips }
sub Code { goto &fips2country }

sub country2fips { $country{uc($_[0])} || $_[0] }
sub fips2country { $cross{lc($_[0])} || $_[0] }

sub iso2fips {
        my $c = uc(shift);
        return "GM" if ($c eq 'DE');
        return "KR" if ($c eq 'KS');
        return "KP" if ($c eq 'KN');
        require Net::Country;
        my $n = Net::Country::Name($c);
        return undef unless ($n);
        $n =~ s/\s*\(.*?\)\s*//;
        return $cross{lc($n)};
}

sub fips2iso {
        my $c = uc(shift);
        return "DE" if ($c eq 'GM');
        return "KS" if ($c eq 'KR');
        return "KN" if ($c eq 'KP');
        my $n = Name($c);
        return undef unless ($n);
        $n =~ s/\s*\(.*?\)\s*//;
        require Geography::Country::TZ;
        return Geography::Country::TZ::from_iso($n);
}

1;

use constant DATA => << '.';
AA	Aruba
AC	Antigua and Barbuda
AF	Afghanistan
AG	Algeria
AL	Albania
AN	Andorra
AO	Angola
AQ	American Samoa
AR	Argentina
AS	Australia
AT	Ashmore and Cartier Islands
AU	Austria
AV	Anguilla
AY	Antarctica
BA	Bahrain
BB	Barbados
BC	Botswana
BD	Bermuda
BE	Belgium
BF	Bahamas, The
BG	Bangladesh
BH	Belize
BL	Bolivia
BM	Burma
BN	Benin
BP	Solomon Islands
BQ	Navassa Island
BR	Brazil
BS	Bassas da India
BT	Bhutan
BU	Bulgaria
BV	Bouvet Island
BX	Brunei
BY	Burundi
BZ	Germany, Berlin
CA	Canada
CB	Cambodia
CD	Chad
CE	Sri Lanka
CF	Congo
CG	Zaire 
CH	China
CI	Chile
CJ	Cayman Islands
CK	Cocos Islands
CM	Cameroon
CN	Comoros
CO	Colombia
CQ	Northern Mariana Islands
CR	Coral Sea Islands
CS	Costa Rica
CT	Central African Republic
CU	Cuba
CV	Cape Verde
CW	Cook Island
CY	Cyprus
CZ	Czechoslovakia
DA	Denmark
DJ	Djibouti
DO	Dominica
DQ	Jarvis Island
DR	Dominican Republic
EC	Ecuador
EG	Egypt
EI	Ireland
EK	Equatorial Guinea
EN	Estonia
ES	El Salvador
ET	Ethiopia
EU	Europa Island
FG	French Guiana
FI	Finland
FJ	Fiji
FK	Falkland Islands
FM      Micronesia
FO	Faroe Islands
FP	French Polynesia
FQ	Baker Island
FR	France
FS	French Southern and Antarctic Lands
GA	Gambia, The
GB	Gabon
GC	German Democratic Republic
GE	Germany, Federal Republic of
GH	Ghana
GI	Gibraltar
GJ	Grenada
GK	Guernsey
GL	Greenland
GM	Germany (1991)
GN	Gilbert and Ellice Islands
GO	Glorioso Islands
GP	Guadeloupe
GQ	Guam
GR	Greece
GT	Guatemala
GV	Guinea
GY	Guyana
GZ	Gaza Strip
HA	Haiti
HK	Hong Kong
HM	Heard and McDonald Islands
HO	Honduras
HQ	Howland Island
HU	Hungary
IC	Iceland
ID	Indonesia
IM	Man, Isle of
IN	India
IO	British Indian Ocean Territory
IP	Clipperton Island
IR	Iran
IS	Israel
IT	Italy
IV	Ivory Coast
IY	Iraq-Saudia Arabia Neutral Zone
IZ	Iraq
JA	Japan
JE	Jersey
JM	Jamaica
JN	Jan Mayen
JO	Jordan
JQ	Johnston Atoll
JU	Juan de Nova Island
KE	Kenya
KN      Korea (North)
KQ	Kingman Reef
KR	Kiribati
KS      Korea (South)
KT	Christmas Island
KU	Kuwait
LA	Laos
LE	Lebanon
LG	Latvia
LH	Lithuania
LI	Liberia
LQ	Palmyra Atoll	
LS	Liechtenstein
LT	Lesotho
LU	Luxembourg
LY	Libya
MA	Madagascar
MB	Martinique
MC	Macau
MF	Mayotte
MG	Mongolia
MH	Montserrat
MI	Malawi
ML	Mali
MN	Monaco
MO	Morocco
MP	Mauritius
MQ	Midway Islands
MR	Mauritania
MT	Malta
MU	Oman
MV	Maldives
MX	Mexico
MY	Malaysia
MZ	Mozambique
NC	New Caledonia
NE	Niue
NF	Norfolk Island
NG	Niger
NH	Vanuatu
NI	Nigeria
NL	Netherlands
NO	Norway
NP	Nepal
NR	Nauru
NS	Suriname
NT	Netherlands Antilles
NU	Nicaragua
NZ	New Zealand
PA	Paraguay
PC	Pitcairn Islands
PE	Peru
PF	Paracel Islands
PG	Spratly Islands
PK	Pakistan 
PL	Poland
PM	Panama
PO	Portugal
PP	Papua New Guinea
PS	Trust Territory of the Pacific
PU	Guinea-Bissau
QA	Qatar
RE	Reunion
RM	Marshall Islands
RO	Romania
RP	Philippines
RQ	Puerto Rico
RW	Rwanda
SA	Saudi Arabia
SB	St. Pierre and Miquelon
SC	St. Kitts and Nevis
SE	Seychelles
SF	South Africa
SG	Senegal 
SH	St. Helena
SL	Sierra Leone
SM	San Marino
SN	Singapore
SO	Somalia
SP	Spain
ST	St. Lucia
SU	Sudan
SV	Svalbard
SW	Sweden
SY	Syria
SZ	Switzerland
TC	United Arab Emirates
TD      Trinidad & Tobago
TE	Tromelin Island
TH	Thailand
TK	Turks and Caicos Islands
TL	Tokelau
TN	Tonga
TO	Togo
TP	Sao Tome and Principe
TS	Tunisia 
TU	Turkey
TV	Tuvalu
TW	Taiwan 
TZ	Tanzania, United Republic of 
UA	Ukraine
UG	Uganda
UK	United Kingdom
UR	USSR
US	United States
UY	Uruguay
UV	Burkina	
VC	St. Vincent and the Grenadines
VE	Venezuela
VI	British Virgin Islands
VM	Vietnam 
VQ	Virgin Islands 
VT	Vatican City
WA	Namibia
WE	West Bank
WF	Wallis and Futuna
WI	Western Sahara
WQ	Wake Island
WS	Western Samoa
WZ	Swaziland
YE	Yemen (Sanaa)
YO	Yugoslavia
YS	Yemen (Aden)
ZA	Zambia
ZI	Zimbabwe
.
