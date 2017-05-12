package Geo::Region::Constant;

use v5.8.1;
use utf8;
use strict;
use warnings;
use parent 'Exporter';

use constant {
    # region
    AFRICA             => '002',
    AMERICAS           => '019',
    ASIA               => '142',
    AUSTRALASIA        => '053',
    CARIBBEAN          => '029',
    CENTRAL_AMERICA    => '013',
    CENTRAL_ASIA       => '143',
    EASTERN_AFRICA     => '014',
    EASTERN_ASIA       => '030',
    EASTERN_EUROPE     => '151',
    EUROPE             => '150',
    EUROPEAN_UNION     => 'EU',
    LATIN_AMERICA      => '419',
    MELANESIA          => '054',
    MICRONESIAN_REGION => '057',
    MIDDLE_AFRICA      => '017',
    NORTH_AMERICA      => '003',
    NORTHERN_AFRICA    => '015',
    NORTHERN_AMERICA   => '021',
    NORTHERN_EUROPE    => '154',
    OCEANIA            => '009',
    OUTLYING_OCEANIA   => 'QO',
    POLYNESIA          => '061',
    SOUTH_AMERICA      => '005',
    SOUTHEAST_ASIA     => '035',
    SOUTHERN_AFRICA    => '018',
    SOUTHERN_ASIA      => '034',
    SOUTHERN_EUROPE    => '039',
    WESTERN_AFRICA     => '011',
    WESTERN_ASIA       => '145',
    WESTERN_EUROPE     => '155',
    WORLD              => '001',

    # country
    AFGHANISTAN                          => 'AF',
    ALAND_ISLANDS                        => 'AX',
    ALBANIA                              => 'AL',
    ALGERIA                              => 'DZ',
    AMERICAN_SAMOA                       => 'AS',
    ANDORRA                              => 'AD',
    ANGOLA                               => 'AO',
    ANGUILLA                             => 'AI',
    ANTARCTICA                           => 'AQ',
    ANTIGUA_BARBUDA                      => 'AG',
    ARGENTINA                            => 'AR',
    ARMENIA                              => 'AM',
    ARUBA                                => 'AW',
    AUSTRALIA                            => 'AU',
    AUSTRIA                              => 'AT',
    AZERBAIJAN                           => 'AZ',
    BAHAMAS                              => 'BS',
    BAHRAIN                              => 'BH',
    BANGLADESH                           => 'BD',
    BARBADOS                             => 'BB',
    BELARUS                              => 'BY',
    BELGIUM                              => 'BE',
    BELIZE                               => 'BZ',
    BENIN                                => 'BJ',
    BERMUDA                              => 'BM',
    BHUTAN                               => 'BT',
    BOLIVIA                              => 'BO',
    BOSNIA                               => 'BA',
    BOTSWANA                             => 'BW',
    BOUVET_ISLAND                        => 'BV',
    BRAZIL                               => 'BR',
    BRITISH_INDIAN_OCEAN_TERRITORY       => 'IO',
    BRITISH_VIRGIN_ISLANDS               => 'VG',
    BRUNEI                               => 'BN',
    BULGARIA                             => 'BG',
    BURKINA_FASO                         => 'BF',
    BURUNDI                              => 'BI',
    CAMBODIA                             => 'KH',
    CAMEROON                             => 'CM',
    CANADA                               => 'CA',
    CAPE_VERDE                           => 'CV',
    CARIBBEAN_NETHERLANDS                => 'BQ',
    CAYMAN_ISLANDS                       => 'KY',
    CENTRAL_AFRICAN_REPUBLIC             => 'CF',
    CHAD                                 => 'TD',
    CHILE                                => 'CL',
    CHINA                                => 'CN',
    CHRISTMAS_ISLAND                     => 'CX',
    COCOS_ISLANDS                        => 'CC',
    COLOMBIA                             => 'CO',
    COMOROS                              => 'KM',
    CONGO_DRC                            => 'CD',
    CONGO_REPUBLIC                       => 'CG',
    COOK_ISLANDS                         => 'CK',
    COSTA_RICA                           => 'CR',
    CROATIA                              => 'HR',
    CUBA                                 => 'CU',
    CURACAO                              => 'CW',
    CYPRUS                               => 'CY',
    CZECH_REPUBLIC                       => 'CZ',
    DENMARK                              => 'DK',
    DJIBOUTI                             => 'DJ',
    DOMINICA                             => 'DM',
    DOMINICAN_REPUBLIC                   => 'DO',
    EAST_TIMOR                           => 'TL',
    ECUADOR                              => 'EC',
    EGYPT                                => 'EG',
    EL_SALVADOR                          => 'SV',
    EQUATORIAL_GUINEA                    => 'GQ',
    ERITREA                              => 'ER',
    ESTONIA                              => 'EE',
    ETHIOPIA                             => 'ET',
    FALKLAND_ISLANDS                     => 'FK',
    FAROE_ISLANDS                        => 'FO',
    FIJI                                 => 'FJ',
    FINLAND                              => 'FI',
    FRANCE                               => 'FR',
    FRENCH_GUIANA                        => 'GF',
    FRENCH_POLYNESIA                     => 'PF',
    FRENCH_SOUTHERN_TERRITORIES          => 'TF',
    GABON                                => 'GA',
    GAMBIA                               => 'GM',
    GEORGIA                              => 'GE',
    GERMANY                              => 'DE',
    GHANA                                => 'GH',
    GIBRALTAR                            => 'GI',
    GREECE                               => 'GR',
    GREENLAND                            => 'GL',
    GRENADA                              => 'GD',
    GUADELOUPE                           => 'GP',
    GUAM                                 => 'GU',
    GUATEMALA                            => 'GT',
    GUERNSEY                             => 'GG',
    GUINEA                               => 'GN',
    GUINEA_BISSAU                        => 'GW',
    GUYANA                               => 'GY',
    HAITI                                => 'HT',
    HEARD_MCDONALD_ISLANDS               => 'HM',
    HONDURAS                             => 'HN',
    HONG_KONG                            => 'HK',
    HUNGARY                              => 'HU',
    ICELAND                              => 'IS',
    INDIA                                => 'IN',
    INDONESIA                            => 'ID',
    IRAN                                 => 'IR',
    IRAQ                                 => 'IQ',
    IRELAND                              => 'IE',
    ISLE_OF_MAN                          => 'IM',
    ISRAEL                               => 'IL',
    ITALY                                => 'IT',
    IVORY_COAST                          => 'CI',
    JAMAICA                              => 'JM',
    JAPAN                                => 'JP',
    JERSEY                               => 'JE',
    JORDAN                               => 'JO',
    KAZAKHSTAN                           => 'KZ',
    KENYA                                => 'KE',
    KIRIBATI                             => 'KI',
    KUWAIT                               => 'KW',
    KYRGYZSTAN                           => 'KG',
    LAOS                                 => 'LA',
    LATVIA                               => 'LV',
    LEBANON                              => 'LB',
    LESOTHO                              => 'LS',
    LIBERIA                              => 'LR',
    LIBYA                                => 'LY',
    LIECHTENSTEIN                        => 'LI',
    LITHUANIA                            => 'LT',
    LUXEMBOURG                           => 'LU',
    MACAU                                => 'MO',
    MACEDONIA                            => 'MK',
    MADAGASCAR                           => 'MG',
    MALAWI                               => 'MW',
    MALAYSIA                             => 'MY',
    MALDIVES                             => 'MV',
    MALI                                 => 'ML',
    MALTA                                => 'MT',
    MARSHALL_ISLANDS                     => 'MH',
    MARTINIQUE                           => 'MQ',
    MAURITANIA                           => 'MR',
    MAURITIUS                            => 'MU',
    MAYOTTE                              => 'YT',
    MEXICO                               => 'MX',
    MICRONESIA                           => 'FM',
    MOLDOVA                              => 'MD',
    MONACO                               => 'MC',
    MONGOLIA                             => 'MN',
    MONTENEGRO                           => 'ME',
    MONTSERRAT                           => 'MS',
    MOROCCO                              => 'MA',
    MOZAMBIQUE                           => 'MZ',
    MYANMAR                              => 'MM',
    NAMIBIA                              => 'NA',
    NAURU                                => 'NR',
    NEPAL                                => 'NP',
    NETHERLANDS                          => 'NL',
    NEW_CALEDONIA                        => 'NC',
    NEW_ZEALAND                          => 'NZ',
    NICARAGUA                            => 'NI',
    NIGER                                => 'NE',
    NIGERIA                              => 'NG',
    NIUE                                 => 'NU',
    NORFOLK_ISLAND                       => 'NF',
    NORTHERN_MARIANA_ISLANDS             => 'MP',
    NORTH_KOREA                          => 'KP',
    NORWAY                               => 'NO',
    OMAN                                 => 'OM',
    PAKISTAN                             => 'PK',
    PALAU                                => 'PW',
    PALESTINE                            => 'PS',
    PANAMA                               => 'PA',
    PAPUA_NEW_GUINEA                     => 'PG',
    PARAGUAY                             => 'PY',
    PERU                                 => 'PE',
    PHILIPPINES                          => 'PH',
    PITCAIRN_ISLANDS                     => 'PN',
    POLAND                               => 'PL',
    PORTUGAL                             => 'PT',
    PUERTO_RICO                          => 'PR',
    QATAR                                => 'QA',
    REUNION                              => 'RE',
    ROMANIA                              => 'RO',
    RUSSIA                               => 'RU',
    RWANDA                               => 'RW',
    SAMOA                                => 'WS',
    SAN_MARINO                           => 'SM',
    SAO_TOME_PRINCIPE                    => 'ST',
    SAUDI_ARABIA                         => 'SA',
    SENEGAL                              => 'SN',
    SERBIA                               => 'RS',
    SEYCHELLES                           => 'SC',
    SIERRA_LEONE                         => 'SL',
    SINGAPORE                            => 'SG',
    SINT_MAARTEN                         => 'SX',
    SLOVAKIA                             => 'SK',
    SLOVENIA                             => 'SI',
    SOLOMON_ISLANDS                      => 'SB',
    SOMALIA                              => 'SO',
    SOUTH_AFRICA                         => 'ZA',
    SOUTH_GEORGIA_SOUTH_SANDWICH_ISLANDS => 'GS',
    SOUTH_KOREA                          => 'KR',
    SOUTH_SUDAN                          => 'SS',
    SPAIN                                => 'ES',
    SRI_LANKA                            => 'LK',
    ST_BARTHELEMY                        => 'BL',
    ST_HELENA                            => 'SH',
    ST_KITTS_NEVIS                       => 'KN',
    ST_LUCIA                             => 'LC',
    ST_MARTIN                            => 'MF',
    ST_PIERRE_MIQUELON                   => 'PM',
    ST_VINCENT_GRENADINES                => 'VC',
    SUDAN                                => 'SD',
    SURINAME                             => 'SR',
    SVALBARD_JAN_MAYEN                   => 'SJ',
    SWAZILAND                            => 'SZ',
    SWEDEN                               => 'SE',
    SWITZERLAND                          => 'CH',
    SYRIA                                => 'SY',
    TAIWAN                               => 'TW',
    TAJIKISTAN                           => 'TJ',
    TANZANIA                             => 'TZ',
    THAILAND                             => 'TH',
    TOGO                                 => 'TG',
    TOKELAU                              => 'TK',
    TONGA                                => 'TO',
    TRINIDAD_TOBAGO                      => 'TT',
    TUNISIA                              => 'TN',
    TURKEY                               => 'TR',
    TURKMENISTAN                         => 'TM',
    TURKS_CAICOS_ISLANDS                 => 'TC',
    TUVALU                               => 'TV',
    UGANDA                               => 'UG',
    UKRAINE                              => 'UA',
    UNITED_ARAB_EMIRATES                 => 'AE',
    UNITED_KINGDOM                       => 'GB',
    UNITED_STATES                        => 'US',
    URUGUAY                              => 'UY',
    US_OUTLYING_ISLANDS                  => 'UM',
    US_VIRGIN_ISLANDS                    => 'VI',
    UZBEKISTAN                           => 'UZ',
    VANUATU                              => 'VU',
    VATICAN_CITY                         => 'VA',
    VENEZUELA                            => 'VE',
    VIETNAM                              => 'VN',
    WALLIS_FUTUNA                        => 'WF',
    WESTERN_SAHARA                       => 'EH',
    YEMEN                                => 'YE',
    ZAMBIA                               => 'ZM',
    ZIMBABWE                             => 'ZW',
};

our $VERSION = '0.07';

my @region = qw(
    AFRICA
    AMERICAS
    ASIA
    AUSTRALASIA
    CARIBBEAN
    CENTRAL_AMERICA
    CENTRAL_ASIA
    EASTERN_AFRICA
    EASTERN_ASIA
    EASTERN_EUROPE
    EUROPE
    EUROPEAN_UNION
    LATIN_AMERICA
    MELANESIA
    MICRONESIAN_REGION
    MIDDLE_AFRICA
    NORTH_AMERICA
    NORTHERN_AFRICA
    NORTHERN_AMERICA
    NORTHERN_EUROPE
    OCEANIA
    OUTLYING_OCEANIA
    POLYNESIA
    SOUTH_AMERICA
    SOUTHEAST_ASIA
    SOUTHERN_AFRICA
    SOUTHERN_ASIA
    SOUTHERN_EUROPE
    WESTERN_AFRICA
    WESTERN_ASIA
    WESTERN_EUROPE
    WORLD
);

my @country = qw(
    AFGHANISTAN
    ALAND_ISLANDS
    ALBANIA
    ALGERIA
    AMERICAN_SAMOA
    ANDORRA
    ANGOLA
    ANGUILLA
    ANTARCTICA
    ANTIGUA_BARBUDA
    ARGENTINA
    ARMENIA
    ARUBA
    AUSTRALIA
    AUSTRIA
    AZERBAIJAN
    BAHAMAS
    BAHRAIN
    BANGLADESH
    BARBADOS
    BELARUS
    BELGIUM
    BELIZE
    BENIN
    BERMUDA
    BHUTAN
    BOLIVIA
    BOSNIA
    BOTSWANA
    BOUVET_ISLAND
    BRAZIL
    BRITISH_INDIAN_OCEAN_TERRITORY
    BRITISH_VIRGIN_ISLANDS
    BRUNEI
    BULGARIA
    BURKINA_FASO
    BURUNDI
    CAMBODIA
    CAMEROON
    CANADA
    CAPE_VERDE
    CARIBBEAN_NETHERLANDS
    CAYMAN_ISLANDS
    CENTRAL_AFRICAN_REPUBLIC
    CHAD
    CHILE
    CHINA
    CHRISTMAS_ISLAND
    COCOS_ISLANDS
    COLOMBIA
    COMOROS
    CONGO_DRC
    CONGO_REPUBLIC
    COOK_ISLANDS
    COSTA_RICA
    CROATIA
    CUBA
    CURACAO
    CYPRUS
    CZECH_REPUBLIC
    DENMARK
    DJIBOUTI
    DOMINICA
    DOMINICAN_REPUBLIC
    EAST_TIMOR
    ECUADOR
    EGYPT
    EL_SALVADOR
    EQUATORIAL_GUINEA
    ERITREA
    ESTONIA
    ETHIOPIA
    FALKLAND_ISLANDS
    FAROE_ISLANDS
    FIJI
    FINLAND
    FRANCE
    FRENCH_GUIANA
    FRENCH_POLYNESIA
    FRENCH_SOUTHERN_TERRITORIES
    GABON
    GAMBIA
    GEORGIA
    GERMANY
    GHANA
    GIBRALTAR
    GREECE
    GREENLAND
    GRENADA
    GUADELOUPE
    GUAM
    GUATEMALA
    GUERNSEY
    GUINEA
    GUINEA_BISSAU
    GUYANA
    HAITI
    HEARD_MCDONALD_ISLANDS
    HONDURAS
    HONG_KONG
    HUNGARY
    ICELAND
    INDIA
    INDONESIA
    IRAN
    IRAQ
    IRELAND
    ISLE_OF_MAN
    ISRAEL
    ITALY
    IVORY_COAST
    JAMAICA
    JAPAN
    JERSEY
    JORDAN
    KAZAKHSTAN
    KENYA
    KIRIBATI
    KUWAIT
    KYRGYZSTAN
    LAOS
    LATVIA
    LEBANON
    LESOTHO
    LIBERIA
    LIBYA
    LIECHTENSTEIN
    LITHUANIA
    LUXEMBOURG
    MACAU
    MACEDONIA
    MADAGASCAR
    MALAWI
    MALAYSIA
    MALDIVES
    MALI
    MALTA
    MARSHALL_ISLANDS
    MARTINIQUE
    MAURITANIA
    MAURITIUS
    MAYOTTE
    MEXICO
    MICRONESIA
    MOLDOVA
    MONACO
    MONGOLIA
    MONTENEGRO
    MONTSERRAT
    MOROCCO
    MOZAMBIQUE
    MYANMAR
    NAMIBIA
    NAURU
    NEPAL
    NETHERLANDS
    NEW_CALEDONIA
    NEW_ZEALAND
    NICARAGUA
    NIGER
    NIGERIA
    NIUE
    NORFOLK_ISLAND
    NORTHERN_MARIANA_ISLANDS
    NORTH_KOREA
    NORWAY
    OMAN
    PAKISTAN
    PALAU
    PALESTINE
    PANAMA
    PAPUA_NEW_GUINEA
    PARAGUAY
    PERU
    PHILIPPINES
    PITCAIRN_ISLANDS
    POLAND
    PORTUGAL
    PUERTO_RICO
    QATAR
    REUNION
    ROMANIA
    RUSSIA
    RWANDA
    SAMOA
    SAN_MARINO
    SAO_TOME_PRINCIPE
    SAUDI_ARABIA
    SENEGAL
    SERBIA
    SEYCHELLES
    SIERRA_LEONE
    SINGAPORE
    SINT_MAARTEN
    SLOVAKIA
    SLOVENIA
    SOLOMON_ISLANDS
    SOMALIA
    SOUTH_AFRICA
    SOUTH_GEORGIA_SOUTH_SANDWICH_ISLANDS
    SOUTH_KOREA
    SOUTH_SUDAN
    SPAIN
    SRI_LANKA
    ST_BARTHELEMY
    ST_HELENA
    ST_KITTS_NEVIS
    ST_LUCIA
    ST_MARTIN
    ST_PIERRE_MIQUELON
    ST_VINCENT_GRENADINES
    SUDAN
    SURINAME
    SVALBARD_JAN_MAYEN
    SWAZILAND
    SWEDEN
    SWITZERLAND
    SYRIA
    TAIWAN
    TAJIKISTAN
    TANZANIA
    THAILAND
    TOGO
    TOKELAU
    TONGA
    TRINIDAD_TOBAGO
    TUNISIA
    TURKEY
    TURKMENISTAN
    TURKS_CAICOS_ISLANDS
    TUVALU
    UGANDA
    UKRAINE
    UNITED_ARAB_EMIRATES
    UNITED_KINGDOM
    UNITED_STATES
    URUGUAY
    US_OUTLYING_ISLANDS
    US_VIRGIN_ISLANDS
    UZBEKISTAN
    VANUATU
    VATICAN_CITY
    VENEZUELA
    VIETNAM
    WALLIS_FUTUNA
    WESTERN_SAHARA
    YEMEN
    ZAMBIA
    ZIMBABWE
);

our @EXPORT_OK = (@region, @country);

our %EXPORT_TAGS = (
    all     => \@EXPORT_OK,
    region  => \@region,
    country => \@country,
);

1;

__END__

=encoding UTF-8

=head1 NAME

Geo::Region::Constant - Constants for UN M.49 and CLDR region codes

=head1 VERSION

This document describes Geo::Region::Constant v0.07, built with Unicode CLDR v27.

=head1 SYNOPSIS

    use Geo::Region::Constant qw( AFRICA AMERICAS ASIA EUROPE OCEANIA );

    use Geo::Region::Constant qw( :all );

    LATIN_AMERICA   # '419'
    EUROPEAN_UNION  # 'EU'
    JAPAN           # 'JP'

=head1 DESCRIPTION

Exportable constants for region and country codes, designed for use with
L<Geo::Region> but available for standalone use as well.

=head2 Constants

No constants are exported by default. They may be exported individually or using
the export tags C<:region>, C<:country>, and C<:all>.

=over

=item C<:region>

The UN M.49 region codes plus CLDR extensions B<EU> and B<QO>.

    WORLD                   001
    • AFRICA                002
      ◦ EASTERN_AFRICA      014
      ◦ MIDDLE_AFRICA       017
      ◦ NORTHERN_AFRICA     015
      ◦ SOUTHERN_AFRICA     018
      ◦ WESTERN_AFRICA      011
    • AMERICAS              019
      ◦ CARIBBEAN           029
      ◦ CENTRAL_AMERICA     013
      ◦ LATIN_AMERICA       419
      ◦ NORTH_AMERICA       003
      ◦ NORTHERN_AMERICA    021
      ◦ SOUTH_AMERICA       005
    • ASIA                  142
      ◦ CENTRAL_ASIA        143
      ◦ EASTERN_ASIA        030
      ◦ SOUTHEAST_ASIA      035
      ◦ SOUTHERN_ASIA       034
      ◦ WESTERN_ASIA        145
    • EUROPE                150
      ◦ EASTERN_EUROPE      151
      ◦ EUROPEAN_UNION      EU
      ◦ NORTHERN_EUROPE     154
      ◦ SOUTHERN_EUROPE     039
      ◦ WESTERN_EUROPE      155
    • OCEANIA               009
      ◦ AUSTRALASIA         053
      ◦ MELANESIA           054
      ◦ MICRONESIAN_REGION  057
      ◦ OUTLYING_OCEANIA    QO
      ◦ POLYNESIA           061

=item C<:country>

The 249 officially assigned ISO 3166-1 alpha-2 codes.

    AFGHANISTAN                           AF
    ALAND_ISLANDS                         AX
    ALBANIA                               AL
    ALGERIA                               DZ
    AMERICAN_SAMOA                        AS
    ANDORRA                               AD
    ANGOLA                                AO
    ANGUILLA                              AI
    ANTARCTICA                            AQ
    ANTIGUA_BARBUDA                       AG
    ARGENTINA                             AR
    ARMENIA                               AM
    ARUBA                                 AW
    AUSTRALIA                             AU
    AUSTRIA                               AT
    AZERBAIJAN                            AZ
    BAHAMAS                               BS
    BAHRAIN                               BH
    BANGLADESH                            BD
    BARBADOS                              BB
    BELARUS                               BY
    BELGIUM                               BE
    BELIZE                                BZ
    BENIN                                 BJ
    BERMUDA                               BM
    BHUTAN                                BT
    BOLIVIA                               BO
    BOSNIA                                BA
    BOTSWANA                              BW
    BOUVET_ISLAND                         BV
    BRAZIL                                BR
    BRITISH_INDIAN_OCEAN_TERRITORY        IO
    BRITISH_VIRGIN_ISLANDS                VG
    BRUNEI                                BN
    BULGARIA                              BG
    BURKINA_FASO                          BF
    BURUNDI                               BI
    CAMBODIA                              KH
    CAMEROON                              CM
    CANADA                                CA
    CAPE_VERDE                            CV
    CARIBBEAN_NETHERLANDS                 BQ
    CAYMAN_ISLANDS                        KY
    CENTRAL_AFRICAN_REPUBLIC              CF
    CHAD                                  TD
    CHILE                                 CL
    CHINA                                 CN
    CHRISTMAS_ISLAND                      CX
    COCOS_ISLANDS                         CC
    COLOMBIA                              CO
    COMOROS                               KM
    CONGO_DRC                             CD
    CONGO_REPUBLIC                        CG
    COOK_ISLANDS                          CK
    COSTA_RICA                            CR
    CROATIA                               HR
    CUBA                                  CU
    CURACAO                               CW
    CYPRUS                                CY
    CZECH_REPUBLIC                        CZ
    DENMARK                               DK
    DJIBOUTI                              DJ
    DOMINICA                              DM
    DOMINICAN_REPUBLIC                    DO
    EAST_TIMOR                            TL
    ECUADOR                               EC
    EGYPT                                 EG
    EL_SALVADOR                           SV
    EQUATORIAL_GUINEA                     GQ
    ERITREA                               ER
    ESTONIA                               EE
    ETHIOPIA                              ET
    FALKLAND_ISLANDS                      FK
    FAROE_ISLANDS                         FO
    FIJI                                  FJ
    FINLAND                               FI
    FRANCE                                FR
    FRENCH_GUIANA                         GF
    FRENCH_POLYNESIA                      PF
    FRENCH_SOUTHERN_TERRITORIES           TF
    GABON                                 GA
    GAMBIA                                GM
    GEORGIA                               GE
    GERMANY                               DE
    GHANA                                 GH
    GIBRALTAR                             GI
    GREECE                                GR
    GREENLAND                             GL
    GRENADA                               GD
    GUADELOUPE                            GP
    GUAM                                  GU
    GUATEMALA                             GT
    GUERNSEY                              GG
    GUINEA                                GN
    GUINEA_BISSAU                         GW
    GUYANA                                GY
    HAITI                                 HT
    HEARD_MCDONALD_ISLANDS                HM
    HONDURAS                              HN
    HONG_KONG                             HK
    HUNGARY                               HU
    ICELAND                               IS
    INDIA                                 IN
    INDONESIA                             ID
    IRAN                                  IR
    IRAQ                                  IQ
    IRELAND                               IE
    ISLE_OF_MAN                           IM
    ISRAEL                                IL
    ITALY                                 IT
    IVORY_COAST                           CI
    JAMAICA                               JM
    JAPAN                                 JP
    JERSEY                                JE
    JORDAN                                JO
    KAZAKHSTAN                            KZ
    KENYA                                 KE
    KIRIBATI                              KI
    KUWAIT                                KW
    KYRGYZSTAN                            KG
    LAOS                                  LA
    LATVIA                                LV
    LEBANON                               LB
    LESOTHO                               LS
    LIBERIA                               LR
    LIBYA                                 LY
    LIECHTENSTEIN                         LI
    LITHUANIA                             LT
    LUXEMBOURG                            LU
    MACAU                                 MO
    MACEDONIA                             MK
    MADAGASCAR                            MG
    MALAWI                                MW
    MALAYSIA                              MY
    MALDIVES                              MV
    MALI                                  ML
    MALTA                                 MT
    MARSHALL_ISLANDS                      MH
    MARTINIQUE                            MQ
    MAURITANIA                            MR
    MAURITIUS                             MU
    MAYOTTE                               YT
    MEXICO                                MX
    MICRONESIA                            FM
    MOLDOVA                               MD
    MONACO                                MC
    MONGOLIA                              MN
    MONTENEGRO                            ME
    MONTSERRAT                            MS
    MOROCCO                               MA
    MOZAMBIQUE                            MZ
    MYANMAR                               MM
    NAMIBIA                               NA
    NAURU                                 NR
    NEPAL                                 NP
    NETHERLANDS                           NL
    NEW_CALEDONIA                         NC
    NEW_ZEALAND                           NZ
    NICARAGUA                             NI
    NIGER                                 NE
    NIGERIA                               NG
    NIUE                                  NU
    NORFOLK_ISLAND                        NF
    NORTHERN_MARIANA_ISLANDS              MP
    NORTH_KOREA                           KP
    NORWAY                                NO
    OMAN                                  OM
    PAKISTAN                              PK
    PALAU                                 PW
    PALESTINE                             PS
    PANAMA                                PA
    PAPUA_NEW_GUINEA                      PG
    PARAGUAY                              PY
    PERU                                  PE
    PHILIPPINES                           PH
    PITCAIRN_ISLANDS                      PN
    POLAND                                PL
    PORTUGAL                              PT
    PUERTO_RICO                           PR
    QATAR                                 QA
    REUNION                               RE
    ROMANIA                               RO
    RUSSIA                                RU
    RWANDA                                RW
    SAMOA                                 WS
    SAN_MARINO                            SM
    SAO_TOME_PRINCIPE                     ST
    SAUDI_ARABIA                          SA
    SENEGAL                               SN
    SERBIA                                RS
    SEYCHELLES                            SC
    SIERRA_LEONE                          SL
    SINGAPORE                             SG
    SINT_MAARTEN                          SX
    SLOVAKIA                              SK
    SLOVENIA                              SI
    SOLOMON_ISLANDS                       SB
    SOMALIA                               SO
    SOUTH_AFRICA                          ZA
    SOUTH_GEORGIA_SOUTH_SANDWICH_ISLANDS  GS
    SOUTH_KOREA                           KR
    SOUTH_SUDAN                           SS
    SPAIN                                 ES
    SRI_LANKA                             LK
    ST_BARTHELEMY                         BL
    ST_HELENA                             SH
    ST_KITTS_NEVIS                        KN
    ST_LUCIA                              LC
    ST_MARTIN                             MF
    ST_PIERRE_MIQUELON                    PM
    ST_VINCENT_GRENADINES                 VC
    SUDAN                                 SD
    SURINAME                              SR
    SVALBARD_JAN_MAYEN                    SJ
    SWAZILAND                             SZ
    SWEDEN                                SE
    SWITZERLAND                           CH
    SYRIA                                 SY
    TAIWAN                                TW
    TAJIKISTAN                            TJ
    TANZANIA                              TZ
    THAILAND                              TH
    TOGO                                  TG
    TOKELAU                               TK
    TONGA                                 TO
    TRINIDAD_TOBAGO                       TT
    TUNISIA                               TN
    TURKEY                                TR
    TURKMENISTAN                          TM
    TURKS_CAICOS_ISLANDS                  TC
    TUVALU                                TV
    UGANDA                                UG
    UKRAINE                               UA
    UNITED_ARAB_EMIRATES                  AE
    UNITED_KINGDOM                        GB
    UNITED_STATES                         US
    URUGUAY                               UY
    US_OUTLYING_ISLANDS                   UM
    US_VIRGIN_ISLANDS                     VI
    UZBEKISTAN                            UZ
    VANUATU                               VU
    VATICAN_CITY                          VA
    VENEZUELA                             VE
    VIETNAM                               VN
    WALLIS_FUTUNA                         WF
    WESTERN_SAHARA                        EH
    YEMEN                                 YE
    ZAMBIA                                ZM
    ZIMBABWE                              ZW

=back

=head1 SEE ALSO

=over

=item * L<Geo::Region> — Geographical regions and groupings using UN M.49 and CLDR
data

=item * L<Unicode CLDR: UN M.49 Territory
Containment|http://unicode.org/cldr/charts/27/supplemental/territory_containment_un_m_49.html>

=item * L<United Nations: UN M.49 Standard Country, Area, & Region
Codes|http://unstats.un.org/unsd/methods/m49/m49regin.htm>

=back

=head1 AUTHOR

Nick Patch <patch@cpan.org>

This project is brought to you by L<Perl CLDR|http://perl-cldr.github.io/> and
L<Shutterstock|http://www.shutterstock.com/>. Additional open source projects
from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 COPYRIGHT AND LICENSE

© 2014–2015 Shutterstock, Inc.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
