#!/usr/bin/perl -w
# Copyright (c) 2010-2022 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This is used to match country names from one source with those from
# an existing source.  It can also be used to create additional aliases
# that do not occur in any of the standards.
#
$Data{'country'}{'link'} =
  [
   [ "Bolivia (Plurinational State of)",
        "Bolivia, Plurinational State of",
        "Plurinational State of Bolivia",
        "Bolivia" ],
   [ "Brunei Darussalam",
        "Brunei" ],
   [ "Cocos (Keeling) Islands (The)",
        "Cocos Islands",
        "The Cocos Islands",
        "Keeling Islands",
        "The Keeling Islands" ],
   [ "Congo",
        "The Republic of the Congo",
        "Republic of the Congo",
        "Congo, The Republic of the",
        "Congo, Republic of the",
        "Congo-Brazzaville",
        "Congo (Brazzaville)" ],
   [ "Congo (The Democratic Republic of the)",
        "Congo, The Democratic Republic of the",
        "Congo, Democratic Republic of the",
        "The Democratic Republic of the Congo",
        "Democratic Republic of the Congo",
        "Congo-Kinshasa",
        "Congo (Kinshasa)" ],
   [ "Czech Republic",
     "The Czech Republic",
     "Czech Republic, The",
     "Czech Republic (The)",
     "Czechia" ],
   [ "Falkland Islands (The) [Malvinas]",
        "Falkland Islands (Malvinas)",
        "Falkland Islands (Islas Malvinas)" ],
   [ "Faroe Islands (The)",
        "Faeroe Islands",
        "The Faeroe Islands" ],
   [ "French Southern Territories",
        "French Southern and Antarctic Lands" ],
   [ "Great Britain",
        "United Kingdom (The)",
        "The United Kingdom",
        "United Kingdom",
        "United Kingdom, The",
        "United Kingdom of Great Britain and Northern Ireland",
        "UK" ],
   [ "Holy See (The) [Vatican City State]",
        "Holy See (Vatican City State)",
        "Holy See (Vatican City)",
        "The Holy See",
        "Holy See",
        "Holy See (The)",
        "Holy See, The",
        "Vatican City" ],
   [ "Hong Kong",
        "China, Hong Kong Special Administrative Region",
        "Hong Kong S.A.R.",
        "Hong Kong Special Administrative Region of China" ],
   [ "Iran (Islamic Republic of)",
        "Iran (The Islamic Republic of)",
        "Iran, Islamic Republic of",
        "Iran, The Islamic Republic of",
        "Islamic Republic of Iran",
        "The Islamic Republic of Iran",
        "Iran" ],
   [ "Kazakhstan",
        "Kazakstan" ],
   [ "Korea (The Democratic People's Republic of)",
        "North Korea" ],
   [ "Korea (The Republic of)",
        "South Korea" ],
   [ "Macao",
        "China, Macao Special Administrative Region",
        "Macao Special Administrative Region of China",
        "Macau S.A.R",
        "Macau S.A.R.",
        "Macau" ],
   [ "Macedonia, The former Yugoslav Republic of",
        "Macedonia" ],
   [ "Micronesia (Federated States of)",
        "Federated States of Micronesia",
        "Micronesia (The Federated States of)",
        "Micronesia, Federated States of",
        "Micronesia, The Federated States of",
        "The Federated States of Micronesia" ],
   [ "Myanmar",
        "The Republic of the Union of Myanmar",
        "Republic of the Union of Myanmar",
        "Burma" ],
   [ "Pitcairn",
        "Pitcairn Island",
        "Pitcairn Islands" ],
   [ "Saint Barthelemy",
        "Saint-Barthelemy" ],
   [ "Saint Helena, Ascension and Tristan da Cunha",
        "Saint Helena" ],
   [ "Saint Martin (French part)",
        "Saint Martin",
        "Saint-Martin (French part)",
        "Saint-Martin" ],
   [ "Solomon Islands",
        "Solomon Islands (The)",
        "Solomon Islands, The",
        "The Solomon Islands" ],
   [ "South Georgia and the South Sandwich Islands",
        "South Georgia and the Islands" ],
   [ "Svalbard and Jan Mayen",
        "Svalbard and Jan Mayen Islands" ],
   [ "Syrian Arab Republic",
        "Syrian Arab Republic (The)",
        "Syrian Arab Republic, The",
        "The Syrian Arab Republic",
        "Syria" ],
   [ "Taiwan (Province of China)",
        "Taiwan",
        "Taiwan, Province of China" ],
   [ "Timor-Leste",
        "East Timor",
        "The Democratic Republic of Timor-Leste",
        "Democratic Republic of Timor-Leste",
        "Timor-Leste, The Democratic Republic of",
        "Timor-Leste, Democratic Republic of",
        "Timor-Leste (The Democratic Republic of)",
        "Timor-Leste (Democratic Republic of)" ],
   [ "The United States of America",
        "The United States",
        "United States",
        "United States, The",
        "United States (The)",
        "US",
        "USA",
        "United States of America" ],
   [ "Venezuela (Bolivarian Republic of)",
        "Venezuela, Bolivarian Republic of",
        "Venezuela, Bolivarian Republic",
        "Venezuela" ],
   [ "Viet Nam",
        "Vietnam" ],
   [ "Virgin Islands (British)",
        "British Virgin Islands",
        "Virgin Islands, British",
        "Virgin Islands (UK)" ],
   [ "Virgin Islands (U.S.)",
        "United States Virgin Islands",
        "Virgin Islands (US)",
        "Virgin Islands, U.S.",
        "Virgin Islands" ],
   [ "Wallis and Futuna",
        "Wallis and Futuna Islands",
        "The Territory of the Wallis and Futuna Islands",
        "Territory of the Wallis and Futuna Islands" ],
   [ "Yemen",
        "The Yemeni Republic",
        "Yemeni Republic",
        "Yemeni Republic, The",
        "Yemeni Republic (The)" ],
   [ "Zambia",
        "The Republic of Zambia",
        "Republic of Zambia",
        "Republic of Zambia, The",
        "Republic of Zambia (The)" ],
   [ "Zimbabwe",
        "The Republic of Zimbabwe",
        "Republic of Zimbabwe",
        "Republic of Zimbabwe, The",
        "Republic of Zimbabwe (The)" ],
];

################################################################################
# ISO 3166-1 countries

$Data{'country'}{'iso'}{'orig'}{'name'} = {
   "Åland Islands"                           => "Aland Islands",
   "Côte d'Ivoire"                           => "Cote d'Ivoire",
   "Curaçao"                                 => "Curacao",
   "Réunion"                                 => "Reunion",
   "Saint Barthélemy"                        => "Saint Barthelemy",
   "Western Sahara*"                         => "Western Sahara",
};

$Data{'country'}{'iso'}{'ignore'} = {
   'name'    => {},
   'alpha-2' => {},
   'alpha-3' => {},
   'numeric' => {},
};

# Unusued
$Data{'country'}{'iso'}{'new'} = {};

################################################################################
# IANA (source of top level domains)

$Data{'country'}{'iana'}{'orig'}{'name'} = {
   "Åland Islands"                           => "Aland Islands",
   "Cocos (keeling) Islands"                 => "Cocos (Keeling) Islands",
   "Congo, The Democratic Republic of The"   => "Congo, The Democratic Republic of the",
   "CÔte D'ivoire"                           => "Cote D'Ivoire",
   "CuraÇao"                                 => "Curacao",
   "Falkland Islands (malvinas)"             => "Falkland Islands (Malvinas)",
   "Holy See (vatican City State)"           => "Holy See (Vatican City State)",
   "RÉunion"                                 => "Reunion",
   "Saint BarthÉlemy"                        => "Saint Barthelemy",
   "Ussr"                                    => "USSR",
   "Virgin Islands, U.s."                    => "Virgin Islands, U.S.",
};

$Data{'country'}{'iana'}{'ignore'} = {
   'name'   => {},
   'dom'    => {},
};

$Data{'country'}{'iana'}{'new'} = {
   'Ascension Island'                        => 1,
   'Netherlands Antilles'                    => 1,
   'Western Sahara'                          => 1,
   'European Union'                          => 1,
   'USSR'                                    => 1,
   'Wallis and Futuna'                       => 1,
   'Yemen'                                   => 1,
   'Zambia'                                  => 1,
   'Zimbabwe'                                => 1,
};

################################################################################
# UN countries

$Data{'country'}{'un'}{'orig'}{'name'} = {
   "&#197;land Islands"                      => "Aland Islands",
   "C&#244;te d&#39;Ivoire"                  => "Cote d'Ivoire",
   "Cura&#231;ao"                            => "Curacao",
   "Democratic People&#39;s Republic of Korea" =>
     "Democratic People's Republic of Korea",
   "Lao People&#39;s Democratic Republic"    => "Lao People's Democratic Republic",
   "R&#233;union"                            => "Reunion",
   "Saint Barth&#233;lemy"                   => "Saint Barthelemy",
   "C&#244;te d’Ivoire"                  => "Cote d'Ivoire",
};

$Data{'country'}{'un'}{'new'} = {
   "Channel Islands"                         => 1,
   "Sark"                                    => 1,
};

################################################################################
# GENC countries

$Data{'country'}{'genc'}{'orig'}{'name'} = {
   "CÔTE D’IVOIRE"                           => "Cote d'Ivoire",
   "CURAÇAO",                                => "Curacao",
   "AKROTIRI"                                => "Akrotiri",
   "ASHMORE AND CARTIER ISLANDS"             => "Ashmore and Cartier Islands",
   "BAKER ISLAND"                            => "Baker Island",
   "BASSAS DA INDIA"                         => "Bassas Da India",
   "BONAIRE, SINT EUSTATIUS, AND SABA"       => "Bonaire, Sint Eustatius, and Saba",
   "CLIPPERTON ISLAND"                       => "Clipperton Island",
   "CORAL SEA ISLANDS"                       => "Coral Sea Islands",
   "DHEKELIA"                                => "Dhekelia",
   "DIEGO GARCIA"                            => "Diego Garcia",
   "ENTITY 1"                                => "Entity 1",
   "ENTITY 2"                                => "Entity 2",
   "ENTITY 3"                                => "Entity 3",
   "ENTITY 4"                                => "Entity 4",
   "ENTITY 5"                                => "Entity 5",
   "ENTITY 6"                                => "Entity 6",
   "EUROPA ISLAND"                           => "Europa Island",
   "GAZA STRIP"                              => "Gaza Strip",
   "GLORIOSO ISLANDS"                        => "Glorioso Islands",
   "GUANTANAMO BAY NAVAL BASE"               => "Guantanamo Bay Naval Base",
   "HOWLAND ISLAND"                          => "Howland Island",
   "JAN MAYEN"                               => "Jan Mayen",
   "JARVIS ISLAND"                           => "Jarvis Island",
   "JOHNSTON ATOLL"                          => "Johnston Atoll",
   "JUAN DE NOVA ISLAND"                     => "Juan de Nova Island",
   "KINGMAN REEF"                            => "Kingman Reef",
   "KOREA, NORTH"                            => "Korea, North",
   "KOREA, SOUTH"                            => "Korea, South",
   "KOSOVO"                                  => "Kosovo",
   "LAOS"                                    => "Laos",
   "MIDWAY ISLANDS"                          => "Midway Islands",
   "MOLDOVA"                                 => "Moldova",
   "NAVASSA ISLAND"                          => "Navassa Island",
   "PALMYRA ATOLL"                           => "Palmyra Atoll",
   "PARACEL ISLANDS"                         => "Paracel Islands",
   "RUSSIA"                                  => "Russia",
   "SAINT HELENA, ASCENSION, AND TRISTAN DA CUNHA" => "Saint Helena, Ascension, and Tristan Da Cunha",
   "SINT MAARTEN"                            => "Sint Maarten",
   "SOUTH GEORGIA AND SOUTH SANDWICH ISLANDS" => "South Georgia and South Sandwich Islands",
   "SPRATLY ISLANDS"                         => "Spratly Islands",
   "SVALBARD"                                => "Svalbard",
   "TANZANIA"                                => "Tanzania",
   "TROMELIN ISLAND"                         => "Tromelin Island",
   "UNKNOWN"                                 => "Unknown",
   "WAKE ISLAND"                             => "Wake Island",
   "WEST BANK"                               => "West Bank",
};

$Data{'country'}{'genc'}{'ignore'} = {
   'name'           => { "ENTITY 1" => 1,
                         "ENTITY 2" => 1,
                         "ENTITY 3" => 1,
                         "ENTITY 4" => 1,
                         "ENTITY 5" => 1,
                         "ENTITY 6" => 1,
                       },
   'genc-alpha-2'   => {},
   'genc-alpha-3'   => {},
   'genc-numeric'   => {},
};

$Data{'country'}{'genc'}{'new'} = {
};

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
