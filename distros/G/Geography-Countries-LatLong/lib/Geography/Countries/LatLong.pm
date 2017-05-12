package Geography::Countries::LatLong;

=head1 NAME

Geography::Countries::LatLong - Mean latitude and longitude

=head1 SYNOPSIS

	use Geography::Countries::LatLong;
	if ( Geography::Countries::LatLong::supports('Hungary') ){
		my $array_ref    = latlong('Hungary');
		my ($lat, $long) = latlongr('Hungary');
	}

=head1 DESCRIPTION

This is version 1.0.

This module provides mean latitude and longitude for a large number
of countries, named in English. Should translations become available,
this module will happily move in C<Geography::Countries::EN::LatLong>.

Regions and continents are not supported - please see the list below.

Look-up is by the English name of the country, as returned by
the C<Geography::Countries> module, of which this is a sub-class
that exports none of its parent's properties or methods.

=head1 CHANGES SINCE VERSION 0.922

The mean values were once arrived at with the following I<MATLAB> code,
where C<name> is a country name recognised by I<MATLAB>:

	% You will need the Mapping Toolbox to run the above snippet.
	function [lat,lon] = country_latlon(name);
	  load worldmtx;
	  c=worldhi(name);
	  lat = mean(c.latlim);
	  lon = mean(c.longlim);
	  fprintf( '"%s" => ["%.4f","%.4f"],', name,lat,lon);
	% end function country_latlon

The current dataset is derived from a variety of public-domain sources.

The data from the old C<$countries_latlong> hash has been preserved in
C<$countries_latlong_old>. To force all routines to the old data,
first call L<Geography::Countries::LatLong::USE_OLD_DATA>.

DEPENDENCIES

This module requires this other modules:

  Geography::Countries

=head2 EXPORT

This module exports the following subroutines:

	countries
	latlong

=cut

use strict;
use base 'Geography::Countries';
use vars qw/@countries $countries %EXPORT_TAGS @EXPORT_OK/;
use vars qw /@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION $countries_latlong $countries_latlong_old/;

@ISA          = qw /Exporter/;
@EXPORT       = qw /country latlong /;
@EXPORT_OK    = qw /countries_latlong countries_latlong_old/;
$VERSION	  = '1.0';

#
# Arrays of latitude and longitude
# indexed by country names.
#
$countries_latlong_old = {
          'Tuvalu' => [
                        '-8.0000',
                        '178.0000'
                      ],
          'Sweden' => [
                        '62.0000',
                        '15.0000'
                      ],
          'West Bank' => [
                           '32.0000',
                           '35.2500'
                         ],
          'Anguilla' => [
                          '18.2500',
                          '-63.1667'
                        ],
          'Libyan Arab Jamahiriya' => [
                                        '26.33853',
                                        '17.19351'
                                      ],
          'Paracel Islands' => [
                                 '16.5000',
                                 '112.0000'
                               ],
          'Guinea' => [
                        '11.0000',
                        '-10.0000'
                      ],
          'Korea, Republic of' => [
                                    '36.0575',
                                    '127.3356'
                                  ],
          'Midway Island' => [
                               '28.3225',
                               '-177.8170'
                             ],
          'French Southern and Antarctic Lands' => [
                                                     '-43.0000',
                                                     '67.0000'
                                                   ],
          'Keeling Islands' => [
                                 '-11.9947',
                                 '96.8787'
                               ],
          'Guyana' => [
                        '5.0000',
                        '-59.0000'
                      ],
          'Ethiopia' => [
                          '8.0000',
                          '38.0000'
                        ],
          'Equatorial Guinea' => [
                                   '2.0000',
                                   '10.0000'
                                 ],
          'South Africa' => [
                              '-29.0000',
                              '24.0000'
                            ],
          'United States of America' => [
                                          '38.15217',
                                          '-100.25006'
                                        ],
          'Peru' => [
                      '-10.0000',
                      '-76.0000'
                    ],
          'Indonesia' => [
                           '-5.0000',
                           '120.0000'
                         ],
          'Portugal' => [
                          '39.5000',
                          '-8.0000'
                        ],
          'Nigeria' => [
                         '10.0000',
                         '8.0000'
                       ],
          'Cook Islands' => [
                              '-21.2333',
                              '-159.7667'
                            ],
          'Solomon Islands' => [
                                 '-8.0000',
                                 '159.0000'
                               ],
          'Latvia' => [
                        '57.0000',
                        '25.0000'
                      ],
          'Antigua and Barbuda' => [
                                     '17.0500',
                                     '-61.8000'
                                   ],
          'Turkey' => [
                        '39.0000',
                        '35.0000'
                      ],
          'Serbia' => [
                        '44.0000',
                        '21.0000'
                      ],
          'Malawi' => [
                        '-13.5000',
                        '34.0000'
                      ],
          'Gambia, The' => [
                             '13.4667',
                             '-16.5667'
                           ],
          'Indian Ocean' => [
                              '-20.0000',
                              '80.0000'
                            ],
          'Faroe Islands' => [
                               '62.0000',
                               '-7.0000'
                             ],
          'Cayman Islands' => [
                                '19.5000',
                                '-80.5000'
                              ],
          'Mauritius' => [
                           '-20.2833',
                           '57.5500'
                         ],
          'Maldives' => [
                          '3.2500',
                          '73.0000'
                        ],
          'Bangladesh' => [
                            '24.0000',
                            '90.0000'
                          ],
          'Democratic People\'s Republic of Korea' => [
                                                        '40.3017',
                                                        '127.4318'
                                                      ],
          'Netherlands' => [
                             '52.5000',
                             '5.7500'
                           ],
          'Brazil' => [
                        '-10.0000',
                        '-55.0000'
                      ],
          'Korea, Democratic Peoples Republic of' => [
                                                       '40.3017',
                                                       '127.4318'
                                                     ],
          'Madeira Islands' => [
                                 '32.7495',
                                 '-16.7756'
                               ],
          'Japan' => [
                       '36.0000',
                       '138.0000'
                     ],
          'Republic of Guinea' => [
                                    '9.93489',
                                    '-11.28384'
                                  ],
          'Ecuador' => [
                         '-2.0000',
                         '-77.5000'
                       ],
          'United Kingdom of Great Britain and Northern Island' => [ # Typo
                                                                     '55.40342',
                                                                     '-3.21145'
                                                                   ],
          'United Kingdom of Great Britain and Northern Ireland' => [ # Fixed
                                                                     '55.40342',
                                                                     '-3.21145'
                                                                   ],
          'South Georgia And The South Sandwich Islands' => [
                                                              '-56.5656',
                                                              '-34.0227'
                                                            ],
          'Mali' => [
                      '17.0000',
                      '-4.0000'
                    ],
          'United Republic of Tanzania' => [
                                             '-6.36822',
                                             '34.88519'
                                           ],
          'Jamaica' => [
                         '18.2500',
                         '-77.5000'
                       ],
          'Dominica' => [
                          '15.4167',
                          '-61.3333'
                        ],
          'Southern Ocean' => [
                                '-60.0000',
                                '90.0000'
                              ],
          'Israel' => [
                        '31.5000',
                        '34.7500'
                      ],
          'Madagascar' => [
                            '-20.0000',
                            '47.0000'
                          ],
          'Hungary, Republic of' => [
                                      '47.16463',
                                      '19.50894'
                                    ],
          'Cocos Islands' => [
                               '-11.9947',
                               '96.8787'
                             ],
          'Syrian Arab Republic' => [
                                      '34.81491',
                                      '39.00233'
                                    ],
          'Malta' => [
                       '35.8333',
                       '14.5833'
                     ],
          'Saint Pierre and Miquelon' => [
                                           '46.8333',
                                           '-56.3333'
                                         ],
          'Midway Islands' => [
                                '28.2000',
                                '-177.3667'
                              ],
          'American Samoa' => [
                                '-14.3333',
                                '-170.0000'
                              ],
          'Russian Federation' => [
                                    '61.52311',
                                    '105.06381'
                                  ],
          'Micronesia, Federated States of' => [
                                                 '6.9167',
                                                 '158.2500'
                                               ],
          'Antarctica' => [
                            '-90.0000',
                            '0.0000'
                          ],
          'Azerbaijan' => [
                            '40.5000',
                            '47.5000'
                          ],
          'Northern Mariana Islands' => [
                                          '15.2000',
                                          '145.7500'
                                        ],
          'Iraq' => [
                      '33.0000',
                      '44.0000'
                    ],
          'Turks and Caicas Islands' => [
                                          '22.0124',
                                          '-72.7319'
                                        ],
          'Christmas Island' => [
                                  '-10.5000',
                                  '105.6667'
                                ],
          'EU' => [
                    '51',
                    '4.5'
                  ],
          'Guernsey' => [
                          '49.4667',
                          '-2.5833'
                        ],
          'Democratic Yemen' => [
                                  '15.35796',
                                  '48.17329'
                                ],
          'Federated States of Micronesia' => [
                                                '8.4674',
                                                '150.5438'
                                              ],
          'United States Pacific Island Wildlife Refuges, Baker Island' => [
                                                                             '0.2167',
                                                                             '-176.4667'
                                                                           ],
          'Howland Island' => [
                                '0.8000',
                                '-176.6333'
                              ],
          'Belarus' => [
                         '53.0000',
                         '28.0000'
                       ],
          'Vietnam' => [
                         '16.0000',
                         '106.0000'
                       ],
          'Niger' => [
                       '16.0000',
                       '8.0000'
                     ],
          'Ukraine' => [
                         '49.0000',
                         '32.0000'
                       ],
          'Saint Kitts and Nevis' => [
                                       '17.3333',
                                       '-62.7500'
                                     ],
          'Romania' => [
                         '46.0000',
                         '25.0000'
                       ],
          'Greece' => [
                        '39.0000',
                        '22.0000'
                      ],
          'Grenada' => [
                         '12.1167',
                         '-61.6667'
                       ],
          'San Marino' => [
                            '43.7667',
                            '12.4167'
                          ],
          'Federal Republic of Germany' => [
                                             '51.16572',
                                             '10.45275'
                                           ],
          'Mayotte' => [
                         '-12.8333',
                         '45.1667'
                       ],
          'Chile' => [
                       '-30.0000',
                       '-71.0000'
                     ],
          'United States' => [
                               '38.0000',
                               '-97.0000'
                             ],
          'Holy See (Vatican City)' => [
                                         '41.9000',
                                         '12.4500'
                                       ],
          'Vatican City' => [
                                         '41.9000',
                                         '12.4500'
                                       ],
          'Holy See' => [
                                         '41.9000',
                                         '12.4500'
                                       ],
          'Wallis and Futuna' => [
                                   '-13.3000',
                                   '-176.2000'
                                 ],
          'Wallis and Futuna Islands' => [
                                   '-13.3000',
                                   '-176.2000'
                                 ],
          'Heard Island and McDonald Islands' => [
                                                   '-53.1000',
                                                   '72.5167'
                                                 ],
          'Costa Rica' => [
                            '10.0000',
                            '-84.0000'
                          ],
          'France' => [
                        '46.0000',
                        '2.0000'
                      ],
          'Kermadec Islands' => [
                                  '-29.8863',
                                  '-178.2544'
                                ],
          'United States Pacific Island Wildlife Refuges, Howland Island' => [
                                                                               '0.8000',
                                                                               '-176.6333'
                                                                             ],
          'Malaysia' => [
                          '2.5000',
                          '112.5000'
                        ],
          'Comoros' => [
                         '-12.1667',
                         '44.2500'
                       ],
          'Cambodia' => [
                          '13.0000',
                          '105.0000'
                        ],
          'British Indian Ocean Territory' => [
                                                '-6.0000',
                                                '71.5000'
                                              ],
          'Samoa' => [
                       '-13.5833',
                       '-172.3333'
                     ],
          'Rwanda' => [
                        '-2.0000',
                        '30.0000'
                      ],
          'Cote d\'Ivoire' => [
                                '8.0000',
                                '-5.0000'
                              ],
          'Uruguay' => [
                         '-33.0000',
                         '-56.0000'
                       ],
          'Benin' => [
                       '9.5000',
                       '2.2500'
                     ],
          'Netherlands Antilles' => [
                                      '12.2500',
                                      '-68.7500'
                                    ],
          'Mongolia' => [
                          '46.0000',
                          '105.0000'
                        ],
          'Korea, North' => [
                              '40.0000',
                              '127.0000'
                            ],
          'Hungary' => [
                         '47.0000',
                         '20.0000'
                       ],
          'Trinidad and Tobago' => [
                                     '11.0000',
                                     '-61.0000'
                                   ],
          'Saint Lucia' => [
                             '13.8833',
                             '-60.9667'
                           ],
          'Pakistan' => [
                          '30.0000',
                          '70.0000'
                        ],
          'Hong Kong' => [
                           '22.2500',
                           '114.1667'
                         ],
          'French Guyana' => [
                               '3.95180',
                               '-53.07823'
                             ],
          'Suriname' => [
                          '4.0000',
                          '-56.0000'
                        ],
          'Navassa Island' => [
                                '18.4167',
                                '-75.0333'
                              ],
          'Britain' => [
                         '55.40342',
                         '-3.21145'
                       ],
          'Gibraltar' => [
                           '36.1333',
                           '-5.3500'
                         ],
          'Western Sahara' => [
                                '24.5000',
                                '-13.0000'
                              ],
          'Antipodes Islands' => [
                                   '-49.6749',
                                   '178.7925'
                                 ],
          'Eritrea' => [
                         '15.0000',
                         '39.0000'
                       ],
          'Micronesia, Federated States' => [
                                              '8.4674',
                                              '150.5438'
                                            ],
          'Angola' => [
                        '-12.5000',
                        '18.5000'
                      ],
          'Korea, South' => [
                              '37.0000',
                              '127.5000'
                            ],
          'Armenia' => [
                         '40.0000',
                         '45.0000'
                       ],
          'Virgin Islands, British' => [
                                         '18.5350',
                                         '-64.5259'
                                       ],
          'Saudi Arabia' => [
                              '25.0000',
                              '45.0000'
                            ],
          'Guinea-Bissau' => [
                               '12.0000',
                               '-15.0000'
                             ],
          'Turkmenistan' => [
                              '40.0000',
                              '60.0000'
                            ],
          'Kingman Reef' => [
                              '6.4000',
                              '-162.3667'
                            ],
          'Honduras' => [
                          '15.0000',
                          '-86.5000'
                        ],
          'Qatar' => [
                       '25.5000',
                       '51.2500'
                     ],
          'Nicaragua' => [
                           '13.0000',
                           '-85.0000'
                         ],
          'Tokelau' => [
                         '-9.0000',
                         '-172.0000'
                       ],
          'Pitcairn' => [
                          '-24.4930',
                          '-127.7594'
                        ],
          'Iceland' => [
                         '65.0000',
                         '-18.0000'
                       ],
          'Ghana' => [
                       '8.0000',
                       '-2.0000'
                     ],
          'Republic of the Congo' => [
                                       '-0.66207',
                                       '14.92742'
                                     ],
          'Arctic Ocean' => [
                              '90.0000',
                              '0.0000'
                            ],
          'French Polynesia' => [
                                  '-15.0000',
                                  '-140.0000'
                                ],
          'Akrotiri' => [
                          '34.6167',
                          '32.9667'
                        ],
          'Djibouti' => [
                          '11.5000',
                          '43.0000'
                        ],
          'Slovakia' => [
                          '48.6667',
                          '19.5000'
                        ],
          'Lao People\'s Democratic Republic' => [
                                                   '18.20521',
                                                   '103.89504'
                                                 ],
          'Turks and Caicos Islands' => [
                                          '21.7500',
                                          '-71.5833'
                                        ],
          'Tajikistan' => [
                            '39.0000',
                            '71.0000'
                          ],
          'Coral Sea Islands' => [
                                   '-18.0000',
                                   '152.0000'
                                 ],
          'Republic of Niger' => [
                                   '17.61100',
                                   '8.08095'
                                 ],
          'Palmyra Atoll' => [
                               '5.8667',
                               '-162.0667'
                             ],
          'United States Pacific Island Wildlife Refuges, Johnston Atoll' => [
                                                                               '16.7500',
                                                                               '-169.5167'
                                                                             ],
          'Cuba' => [
                      '21.5000',
                      '-80.0000'
                    ],
          'Spain' => [
                       '40.0000',
                       '-4.0000'
                     ],
          'Republic of Moldova' => [
                                     '46.9795',
                                     '28.3772'
                                   ],
          'Guatamala' => [
                           '15.7763',
                           '-90.2323'
                         ],
          'Bolivia' => [
                         '-17.0000',
                         '-65.0000'
                       ],
          'Switzerland' => [
                             '47.0000',
                             '8.0000'
                           ],
          'Faroc Islands' => [
                               '-23.6308',
                               '-148.5444'
                             ],
          'Europa Island' => [
                               '-22.3333',
                               '40.3667'
                             ],
          'Montserrat' => [
                            '16.7500',
                            '-62.2000'
                          ],
          'Pitcairn Islands' => [
                                  '-25.0667',
                                  '-130.1000'
                                ],
          'Montenegro' => [
                            '42.5000',
                            '19.3000'
                          ],
          'Luxembourg' => [
                            '49.7500',
                            '6.1667'
                          ],
          'Brunei' => [
                        '4.5000',
                        '114.6667'
                      ],
          'Iran' => [
                      '32.0000',
                      '53.0000'
                    ],
          'Western Samoa' => [
                               '-13.74787',
                               '-172.10396'
                             ],
          'Martinique' => [
                            '14.6667',
                            '-61.0000'
                          ],
          'Bahamas, The' => [
                              '24.2500',
                              '-76.0000'
                            ],
          'Tanzania' => [
                          '-6.0000',
                          '35.0000'
                        ],
          'Pacific Ocean' => [
                               '0.0000',
                               '-160.0000'
                             ],
          'Glorioso Islands' => [
                                  '-11.5000',
                                  '47.3333'
                                ],
          'Kazakhstan' => [
                            '48.0000',
                            '68.0000'
                          ],
          'Italy' => [
                       '42.8333',
                       '12.8333'
                     ],
          'Republic of Korea' => [
                                   '36.0575',
                                   '127.3356'
                                 ],
          'Zimbabwe' => [
                          '-20.0000',
                          '30.0000'
                        ],
          'East Timor' => [
                            '-8.8333',
                            '125.9167'
                          ],
          'New Zealand' => [
                             '-41.0000',
                             '174.0000'
                           ],
          'Netherlands, Kingdom of the' => [
                                             '52.11200',
                                             '5.29500'
                                           ],
          'Yemen' => [
                       '15.0000',
                       '48.0000'
                     ],
          'Burundi' => [
                         '-3.5000',
                         '30.0000'
                       ],
          'Bahrain' => [
                         '26.0000',
                         '50.5500'
                       ],
          'Jarvis Island' => [
                               '-0.3667',
                               '-160.0167'
                             ],
          'Reunion' => [
                         '-21.1000',
                         '55.6000'
                       ],
          'Ashmore and Cartier Islands' => [
                                             '-12.2333',
                                             '123.0833'
                                           ],
          'Macedonia, The Former Yugoslav Republic of' => [
                                                            '41.61100',
                                                            '21.75141'
                                                          ],
          'Burma' => [
                       '22.0000',
                       '98.0000'
                     ],
          'Heard Island And Mcdonald Islands' => [
                                                   '-53.0507',
                                                   '73.2278'
                                                 ],
          'British Virgin Islands' => [
                                        '18.5000',
                                        '-64.5000'
                                      ],
          'Greenland' => [
                           '72.0000',
                           '-40.0000'
                         ],
          'Denmark' => [
                         '56.0000',
                         '10.0000'
                       ],
          'Andorra' => [
                         '42.5000',
                         '1.5000'
                       ],
          'Norfolk Island' => [
                                '-29.0333',
                                '167.9500'
                              ],
          'Albania' => [
                         '41.0000',
                         '20.0000'
                       ],
          'Congo, Republic of the' => [
                                        '-1.0000',
                                        '15.0000'
                                      ],
          'Nepal' => [
                       '28.0000',
                       '84.0000'
                     ],
          'Tonga' => [
                       '-20.0000',
                       '-175.0000'
                     ],
          'Somalia' => [
                         '10.0000',
                         '49.0000'
                       ],
          'Nauru' => [
                       '-0.5333',
                       '166.9167'
                     ],
          'Falkland Islands (Islas Malvinas)' => [
                                                   '-51.7500',
                                                   '-59.0000'
                                                 ],
          'Mozambique' => [
                            '-18.2500',
                            '35.0000'
                          ],
          'America' => [
                         '38.15217',
                         '-100.25006'
                       ],
          'Antipodes' => [
                           '-49.6749',
                           '178.7925'
                         ],
          'Jan Mayen' => [
                           '71.0000',
                           '-8.0000'
                         ],
          'Virgin Islands, U.S.' => [
                                      '18.0699',
                                      '-64.8257'
                                    ],
          'United States Pacific Island Wildlife Refuges, Kingman Reef' => [
                                                                             '6.3833',
                                                                             '-162.4167'
                                                                           ],
          'Antipodean Islands' => [
                                    '-49.6749',
                                    '178.7925'
                                  ],
          'Virgin Islands' => [
                                '18.3333',
                                '-64.8333'
                              ],
          'Argentina' => [
                           '-34.0000',
                           '-64.0000'
                         ],
          'Gaza Strip' => [
                            '31.4167',
                            '34.3333'
                          ],
          'Federal Islamic Republic of the Comoros' => [
                                                         '-11.88810',
                                                         '43.87701'
                                                       ],
          'Prince Edward Islands' => [
                                       '-46.7943',
                                       '37.7964'
                                     ],
          'Dominican Republic' => [
                                    '19.0000',
                                    '-70.6667'
                                  ],
          'Micronesia' => [
                            '8.4674',
                            '150.5438'
                          ],
          'Micronesia-Polynesia' => [
                            '8.4674',
                            '150.5438'
                          ],
          'Morocco' => [
                         '32.0000',
                         '-5.0000'
                       ],
          'Tunisia' => [
                         '34.0000',
                         '9.0000'
                       ],
          'Guinea, Republic of' => [
                                     '9.93489',
                                     '-11.28384'
                                   ],
          'South Georgia and the South Sandwich Islands' => [
                                                              '-54.5000',
                                                              '-37.0000'
                                                            ],
          'Paraguay' => [
                          '-23.0000',
                          '-58.0000'
                        ],
          'Congo, Democratic Republic of the' => [
                                                   '0.0000',
                                                   '25.0000'
                                                 ],
          'Croatia' => [
                         '45.1667',
                         '15.5000'
                       ],
          'Great Britain' => [
                               '55.40342',
                               '-3.21145'
                             ],
          'Swaziland' => [
                           '-26.5000',
                           '31.5000'
                         ],
          'Dhekelia' => [
                          '34.9833',
                          '33.7500'
                        ],
          'Slovenia' => [
                          '46.1167',
                          '14.8167'
                        ],
          'Belize' => [
                        '17.2500',
                        '-88.7500'
                      ],
          'Botswana' => [
                          '-22.0000',
                          '24.0000'
                        ],
          'India' => [
                       '20.0000',
                       '77.0000'
                     ],
          'Namibia' => [
                         '-22.0000',
                         '17.0000'
                       ],
          'Algeria' => [
                         '28.0000',
                         '3.0000'
                       ],
          'United States Pacific Island Wildlife Refuges, Midway Islands' => [
                                                                               '28.2000',
                                                                               '-177.3667'
                                                                             ],
          'Galapagos Islands' => [
                                   '-0.6223',
                                   '-90.4509'
                                 ],
          'EEC' => [
                     '51',
                     '4.5'
                   ],
          'UK' => [
                    '55.40342',
                    '-3.21145'
                  ],
          'Taiwan' => [
                        '23.5000',
                        '121.0000'
                      ],
          'Netherlands, Antilles' => [
                                       '15.01941',
                                       '-66.05044'
                                     ],
          'Falkland Islands' => [
                                  '-51.9578',
                                  '-59.5288'
                                ],
          'Bulgaria' => [
                          '43.0000',
                          '25.0000'
                        ],
          'Laos' => [
                      '18.0000',
                      '105.0000'
                    ],
          'Macau' => [
                       '22.1667',
                       '113.5500'
                     ],
          'Lebanon' => [
                         '33.8333',
                         '35.8333'
                       ],
          'Thailand' => [
                          '15.0000',
                          '100.0000'
                        ],
          'United States Pacific Island Wildlife Refuges, Palmyra Atoll' => [
                                                                              '5.8833',
                                                                              '-162.0833'
                                                                            ],
          'Barbados' => [
                          '13.1667',
                          '-59.5333'
                        ],
          'United Arab Emirates' => [
                                      '24.0000',
                                      '54.0000'
                                    ],
          'Singapore' => [
                           '1.3667',
                           '103.8000'
                         ],
          'Spratly Islands' => [
                                 '8.6333',
                                 '111.9167'
                               ],
          'Cameroon' => [
                          '6.0000',
                          '12.0000'
                        ],
          'Cocos (Keeling) Islands' => [
                                         '-12.5000',
                                         '96.8333'
                                       ],
          'Germany' => [
                         '51.0000',
                         '9.0000'
                       ],
          'Burkina Faso' => [
                              '13.0000',
                              '-2.0000'
                            ],
          'Belgium' => [
                         '50.8333',
                         '4.0000'
                       ],
          'Monaco' => [
                        '43.7333',
                        '7.4000'
                      ],
          'Hong Kong Special Administrative Region of China' => [
                                                                  '22.3565',
                                                                  '114.1363'
                                                                ],
          'European Union' => [
                                '51',
                                '4.5'
                              ],
          'Comoros, Federal Islamic Republic of the' => [
                                                          '-11.88810',
                                                          '43.87701'
                                                        ],
          'French Guiana' => [
                               '4.0000',
                               '-53.0000'
                             ],
          'Uzbekistan' => [
                            '41.0000',
                            '64.0000'
                          ],
          'Haiti' => [
                       '19.0000',
                       '-72.4167'
                     ],
          'Kiribati' => [
                          '1.4167',
                          '173.0000'
                        ],
          'Bouvet Island' => [
                               '-54.4333',
                               '3.4000'
                             ],
          'Guam' => [
                      '13.4667',
                      '144.7833'
                    ],
          'Libya' => [
                       '25.0000',
                       '17.0000'
                     ],
          'Atlantic Ocean' => [
                                '0.0000',
                                '-25.0000'
                              ],
          'Panama' => [
                        '9.0000',
                        '-80.0000'
                      ],
          'Iran (Islamic Republic of)' => [
                                            '32.42065',
                                            '53.68236'
                                          ],
          'North Korea' => [
                             '40.3017',
                             '127.4318'
                           ],
          'Syria' => [
                       '35.0000',
                       '38.0000'
                     ],
          'Puerto Rico' => [
                             '18.2500',
                             '-66.5000'
                           ],
          'Tromelin Island' => [
                                 '-15.8667',
                                 '54.4167'
                               ],
          'GB' => [
                    '55.40342',
                    '-3.21145'
                  ],
          'Zambia' => [
                        '-15.0000',
                        '30.0000'
                      ],
          'Liechtenstein' => [
                               '47.2667',
                               '9.5333'
                             ],
          'Sri Lanka' => [
                           '7.0000',
                           '81.0000'
                         ],
          'China' => [
                       '35.0000',
                       '105.0000'
                     ],
          'Sierra Leone' => [
                              '8.5000',
                              '-11.5000'
                            ],
          'Congo' => [
                       '-0.66207',
                       '14.92742'
                     ],
          'Estonia' => [
                         '59.0000',
                         '26.0000'
                       ],
          'Democratic Republic of the Congo' => [
                                                  '-4.03479',
                                                  '21.75503'
                                                ],
          'Guatemala' => [
                           '15.5000',
                           '-90.2500'
                         ],
          'Oman' => [
                      '21.0000',
                      '57.0000'
                    ],
          'Ireland' => [
                         '53.0000',
                         '-8.0000'
                       ],
          'Guadeloupe' => [
                            '16.2500',
                            '-61.5833'
                          ],
          'Vanuatu' => [
                         '-16.0000',
                         '167.0000'
                       ],
          'Wake Island' => [
                             '19.2833',
                             '166.6500'
                           ],
          'Czech Republic' => [
                                '49.7500',
                                '15.5000'
                              ],
          'Central African Republic' => [
                                          '7.0000',
                                          '21.0000'
                                        ],
          'Mexico' => [
                        '23.0000',
                        '-102.0000'
                      ],
          'Bahamas' => [
                         '24.6949',
                         '-77.4616'
                       ],
          'Bassas da India' => [
                                 '-21.5000',
                                 '39.8333'
                               ],
          'Juan de Nova Island' => [
                                     '-17.0500',
                                     '42.7500'
                                   ],
          'Niue' => [
                      '-19.0333',
                      '-169.8667'
                    ],
          'Independent State of Samoa' => [
                                            '-13.74787',
                                            '-172.10396'
                                          ],
          'Yugoslavia' => [
                            '44.0660',
                            '20.9225'
                          ],
          'Viet Nam' => [
                          '15.89854',
                          '105.80642'
                        ],
          'United States Pacific Island Wildlife Refuges, Jarvis Island' => [
                                                                              '-0.3833',
                                                                              '-160.0167'
                                                                            ],
          'Saint Helena' => [
                              '-11.9541',
                              '-10.0300'
                            ],
          'Iran, Islamic Republic of' => [
                                           '32.42065',
                                           '53.68236'
                                         ],
          'El Salvador' => [
                             '13.8333',
                             '-88.9167'
                           ],
          'Jersey' => [
                        '49.2500',
                        '-2.1667'
                      ],
          'Brunei Darussalam' => [
                                   '4.5251',
                                   '114.7155'
                                 ],
          'South Korea' => [
                             '36.0575',
                             '127.3356'
                           ],
          'Aruba' => [
                       '12.5000',
                       '-69.9667'
                     ],
          'Poland' => [
                        '52.0000',
                        '20.0000'
                      ],
          'Ivory Coast' => [
                             '7.5469',
                             '-5.5471'
                           ],
          'Togo' => [
                      '8.0000',
                      '1.1667'
                    ],
          'Democratic Peoples Republic of Korea' => [
                                                      '40.3017',
                                                      '127.4318'
                                                    ],
          'Canary Islands' => [
                                '28.5251',
                                '-15.7937'
                              ],
          'Moldova' => [
                         '47.0000',
                         '29.0000'
                       ],
          'United States Virgin Islands' => [
                                              '18.0699',
                                              '-64.8257'
                                            ],
          'Gabon' => [
                       '-1.0000',
                       '11.7500'
                     ],
          'Kenya' => [
                       '1.0000',
                       '38.0000'
                     ],
          'Baker Island' => [
                              '0.2167',
                              '-176.4667'
                            ],
          'Egypt' => [
                       '27.0000',
                       '30.0000'
                     ],
          'Australia' => [
                           '-27.0000',
                           '133.0000'
                         ],
          'Johnston Atoll' => [
                                '16.7500',
                                '-169.5167'
                              ],
          'Macedonia' => [
                           '41.8333',
                           '22.0000'
                         ],
          'United Kingdom' => [
                                '54.0000',
                                '-2.0000'
                              ],
          'Lithuania' => [
                           '56.0000',
                           '24.0000'
                         ],
          'Marshall Islands' => [
                                  '9.0000',
                                  '168.0000'
                                ],
          'Norway' => [
                        '62.0000',
                        '10.0000'
                      ],
          'Canada' => [
                        '60.0000',
                        '-95.0000'
                      ],
          'Cyprus' => [
                        '35.0000',
                        '33.0000'
                      ],
          'Svalbard' => [
                          '78.0000',
                          '20.0000'
                        ],
          'Papua New Guinea' => [
                                  '-6.0000',
                                  '147.0000'
                                ],
          'Bermuda' => [
                         '32.3333',
                         '-64.7500'
                       ],
          'Kyrgyzstan' => [
                            '41.0000',
                            '75.0000'
                          ],
          'Mauritania' => [
                            '20.0000',
                            '-12.0000'
                          ],
          'Zaire' => [
                       '-4.03479',
                       '21.75503'
                     ],
          'Seychelles' => [
                            '-4.5833',
                            '55.6667'
                          ],
          'Russia' => [
                        '60.0000',
                        '100.0000'
                      ],
          'Finland' => [
                         '64.0000',
                         '26.0000'
                       ],
          'Clipperton Island' => [
                                   '10.2833',
                                   '-109.2167'
                                 ],
          'Palau' => [
                       '7.5000',
                       '134.5000'
                     ],
          'Chad' => [
                      '15.0000',
                      '19.0000'
                    ],
          'Fiji' => [
                      '-18.0000',
                      '175.0000'
                    ],
          'Austria' => [
                         '47.3333',
                         '13.3333'
                       ],
          'Cape Verde' => [
                            '16.0000',
                            '-24.0000'
                          ],
          'Jordan' => [
                        '31.0000',
                        '36.0000'
                      ],
          'Lesotho' => [
                         '-29.5000',
                         '28.5000'
                       ],
          'Philippines' => [
                             '13.0000',
                             '122.0000'
                           ],
          'Uganda' => [
                        '1.0000',
                        '32.0000'
                      ],
          'Bhutan' => [
                        '27.5000',
                        '90.5000'
                      ],
          'Sao Tome and Principe' => [
                                       '1.0000',
                                       '7.0000'
                                     ],
          'Saint Vincent and the Grenadines' => [
                                                  '13.2500',
                                                  '-61.2000'
                                                ],
          'Colombia' => [
                          '4.0000',
                          '-72.0000'
                        ],
          'Gambia' => [
                        '13.4454',
                        '-15.3114'
                      ],
          'Liberia' => [
                         '6.5000',
                         '-9.5000'
                       ],
          'USA' => [
                     '38.15217',
                     '-100.25006'
                   ],
          'Côte d\'Ivoire' => [
                                '7.5469',
                                '-5.5471'
                              ],
          'The former Yugoslav Republic of Macedonia' => [
                                                           '41.61100',
                                                           '21.75141'
                                                         ],
          'Taiwan Province of China' => [
                                          '23.60003',
                                          '120.65415'
                                        ],
          'Isle of Man' => [
                             '54.2500',
                             '-4.5000'
                           ],
          'Bosnia and Herzegovina' => [
                                        '44.0000',
                                        '18.0000'
                                      ],
          'Kuwait' => [
                        '29.5000',
                        '45.7500'
                      ],
          'Venezuela' => [
                           '8.0000',
                           '-66.0000'
                         ],
          'The Former Yugoslav Republic of Macedonia' => [
                                                           '41.61100',
                                                           '21.75141'
                                                         ],
          'Georgia' => [
                         '42.0000',
                         '43.5000'
                       ],
          'New Caledonia' => [
                               '-21.5000',
                               '165.5000'
                             ],
          'Afghanistan' => [
                             '33.0000',
                             '65.0000'
                           ],
          'Sudan' => [
                       '15.0000',
                       '30.0000'
                     ],
          'Holland' => [
                         '52.11200',
                         '5.29500'
                       ],
          'Niger, Republic of' => [
                                    '17.61100',
                                    '8.08095'
                                  ],
          'Senegal' => [
                         '14.0000',
                         '-14.0000'
                       ]
};

$countries_latlong = {
"Afghanistan" => [33.0000, 65.0000],
 "Akrotiri" => [34.6167, 32.9667],
 "Albania" => [41.0000, 20.0000],
 "Algeria" => [28.0000, 3.0000],
 "American Samoa" => [-14.3333, -170.0000],
 "Andorra" => [42.5000, 1.5000],
 "Angola" => [-12.5000, 18.5000],
 "Anguilla" => [18.2500, -63.1667],
 "Antarctica" => [-90.0000, 0.0000],
 "Antigua and Barbuda" => [17.0500, -61.8000],
 "Arctic Ocean" => [90.0000, 0.0000],
 "Argentina" => [-34.0000, -64.0000],
 "Armenia" => [40.0000, 45.0000],
 "Aruba" => [12.5000, -69.9667],
 "Ashmore and Cartier Islands" => [-12.2333, 123.0833],
 "Atlantic Ocean" => [0.0000, -25.0000],
 "Australia" => [-27.0000, 133.0000],
 "Austria" => [47.3333, 13.3333],
 "Azerbaijan" => [40.5000, 47.5000],
 "Bahamas, The" => [24.2500, -76.0000],
 "Bahamas" => [24.2500, -76.0000],
 "Bahrain" => [26.0000, 50.5500],
 "Baker Island" => [0.2167, -176.4667],
 "Bangladesh" => [24.0000, 90.0000],
 "Barbados" => [13.1667, -59.5333],
 "Bassas da India" => [-21.5000, 39.8333],
 "Belarus" => [53.0000, 28.0000],
 "Belgium" => [50.8333, 4.0000],
 "Belize" => [17.2500, -88.7500],
 "Benin" => [9.5000, 2.2500],
 "Bermuda" => [32.3333, -64.7500],
 "Bhutan" => [27.5000, 90.5000],
 "Bolivia" => [-17.0000, -65.0000],
 "Bosnia and Herzegovina" => [44.0000, 18.0000],
 "Botswana" => [-22.0000, 24.0000],
 "Bouvet Island" => [-54.4333, 3.4000],
 "Brazil" => [-10.0000, -55.0000],
 "British Indian Ocean Territory" => [-6.0000, 71.5000],
 "British Virgin Islands" => [18.5000, -64.5000],
 "Virgin Islands, British" => [18.5000, -64.5000],
 "Brunei" => [4.5000, 114.6667],
 "Bulgaria" => [43.0000, 25.0000],
 "Burkina Faso" => [13.0000, -2.0000],
 "Burma" => [22.0000, 98.0000],
 "Burundi" => [-3.5000, 30.0000],
 "Cambodia" => [13.0000, 105.0000],
 "Cameroon" => [6.0000, 12.0000],
 "Canada" => [60.0000, -95.0000],
 "Cape Verde" => [16.0000, -24.0000],
 "Cayman Islands" => [19.5000, -80.5000],
 "Central African Republic" => [7.0000, 21.0000],
 "Chad" => [15.0000, 19.0000],
 "Chile" => [-30.0000, -71.0000],
 "China" => [35.0000, 105.0000],
 "Christmas Island" => [-10.5000, 105.6667],
 "Clipperton Island" => [10.2833, -109.2167],
 "Cocos (Keeling) Islands" => [-12.5000, 96.8333],
 "Keeling Islands" => [-12.5000, 96.8333],
 "Cocos Islands" => [-12.5000, 96.8333],
 "Cocos" => [-12.5000, 96.8333],
 "Colombia" => [4.0000, -72.0000],
 "Comoros" => [-12.1667, 44.2500],
 'Comoros, Federal Islamic Republic of the' => [-12.1667, 44.2500],
 'Federal Islamic Republic of the Comoros' => [-12.1667, 44.2500],
 "Congo, Democratic Republic of the" => [0.0000, 25.0000],
 "Democratic Republic of the Congo" => [0.0000, 25.0000],
 "Congo, Republic of the" => [-1.0000, 15.0000],
 "Republic of the Congo" => [-1.0000, 15.0000],
 "Cook Islands" => [-21.2333, -159.7667],
 "Coral Sea Islands" => [-18.0000, 152.0000],
 "Costa Rica" => [10.0000, -84.0000],
 "Cote d'Ivoire" => [8.0000, -5.0000],
 'Côte d\'Ivoire' => [8.0000, -5.0000],
 'Ivory Coast' => [8.0000, -5.0000],
 'The Ivory Coast' => [8.0000, -5.0000],
 "Croatia" => [45.1667, 15.5000],
 "Cuba" => [21.5000, -80.0000],
 "Cyprus" => [35.0000, 33.0000],
 "Czech Republic" => [49.7500, 15.5000],
 "Denmark" => [56.0000, 10.0000],
 "Dhekelia" => [34.9833, 33.7500],
 "Djibouti" => [11.5000, 43.0000],
 "Dominica" => [15.4167, -61.3333],
 "Dominican Republic" => [19.0000, -70.6667],
 "East Timor" => [-8.8333, 125.9167],
 "Ecuador" => [-2.0000, -77.5000],
 "Egypt" => [27.0000, 30.0000],
 "El Salvador" => [13.8333, -88.9167],
 "Equatorial Guinea" => [2.0000, 10.0000],
 "Eritrea" => [15.0000, 39.0000],
 "Estonia" => [59.0000, 26.0000],
 "Ethiopia" => [8.0000, 38.0000],
 "Europa Island" => [-22.3333, 40.3667],
 "Falkland Islands (Islas Malvinas)" => [-51.7500, -59.0000],
 "Falkland Islands" => [-51.7500, -59.0000],
 "Faroe Islands" => [62.0000, -7.0000],
 "Fiji" => [-18.0000, 175.0000],
 "Finland" => [64.0000, 26.0000],
 "France" => [46.0000, 2.0000],
 "French Guiana" => [4.0000, -53.0000],
 "French Polynesia" => [-15.0000, -140.0000],
 "French Southern and Antarctic Lands" => [-43.0000, 67.0000],
 "Gabon" => [-1.0000, 11.7500],
 "Gambia, The" => [13.4667, -16.5667],
 "Gambia" => [13.4667, -16.5667],
 "Gaza Strip" => [31.4167, 34.3333],
 "Georgia" => [42.0000, 43.5000],
 "Germany" => [51.0000, 9.0000],
 'Federal Republic of Germany' => [51.0000, 9.0000],
 "Ghana" => [8.0000, -2.0000],
 "Gibraltar" => [36.1333, -5.3500],
 "Glorioso Islands" => [-11.5000, 47.3333],
 "Greece" => [39.0000, 22.0000],
 "Greenland" => [72.0000, -40.0000],
 "Grenada" => [12.1167, -61.6667],
 "Guadeloupe" => [16.2500, -61.5833],
 "Guam" => [13.4667, 144.7833],
 "Guatemala" => [15.5000, -90.2500],
 "Guernsey" => [49.4667, -2.5833],
 "Guinea" => [11.0000, -10.0000],
 "Republic of Guinea" => [11.0000, -10.0000],
 "Guinea, Republic of" => [11.0000, -10.0000],
 "Guinea-Bissau" => [12.0000, -15.0000],
 "Guyana" => [5.0000, -59.0000],
 "French Guyana" => [5.0000, -59.0000],
 "Haiti" => [19.0000, -72.4167],
 "Heard Island and McDonald Islands" => [-53.1000, 72.5167],
 'Heard Island And Mcdonald Islands' => [-53.1000, 72.5167],
 "Holy See (Vatican City)" => [41.9000, 12.4500],
 "Holy See" => [41.9000, 12.4500],
 "The Holy See" => [41.9000, 12.4500],
 "Holy See, The" => [41.9000, 12.4500],
 "Vatican City" => [41.9000, 12.4500],
 "Vatican City, The" => [41.9000, 12.4500],
 "The Vatican City" => [41.9000, 12.4500],
 "Honduras" => [15.0000, -86.5000],
 "Hong Kong" => [22.2500, 114.1667],
 "Hong Kong Special Administrative Region of China" => [22.2500, 114.1667],
 "Howland Island" => [0.8000, -176.6333],
 "Hungary" => [47.0000, 20.0000],
 "Hungary, Repulic of" => [47.0000, 20.0000],
 "Iceland" => [65.0000, -18.0000],
 "India" => [20.0000, 77.0000],
 "Indian Ocean" => [-20.0000, 80.0000],
 "Indonesia" => [-5.0000, 120.0000],
 "Iran" => [32.0000, 53.0000],
 'Iran (Islamic Republic of)' => [32.0000, 53.0000],
 'Iran, Islamic Republic of' => [32.0000, 53.0000],
 "Iraq" => [33.0000, 44.0000],
 "Ireland" => [53.0000, -8.0000],
 "Isle of Man" => [54.2500, -4.5000],
 "Israel" => [31.5000, 34.7500],
 "Italy" => [42.8333, 12.8333],
 "Jamaica" => [18.2500, -77.5000],
 "Jan Mayen" => [71.0000, -8.0000],
 "Japan" => [36.0000, 138.0000],
 "Jarvis Island" => [-0.3667, -160.0167],
 "Jersey" => [49.2500, -2.1667],
 "Johnston Atoll" => [16.7500, -169.5167],
 "Jordan" => [31.0000, 36.0000],
 "Juan de Nova Island" => [-17.0500, 42.7500],
 "Kazakhstan" => [48.0000, 68.0000],
 "Kenya" => [1.0000, 38.0000],
 "Kingman Reef" => [6.4000, -162.3667],
 "Kiribati" => [1.4167, 173.0000],
 "Korea, North" => [40.0000, 127.0000],
 "North Korea" => [40.0000, 127.0000],
 'Korea, Republic of' => [40.0000, 127.0000],
 'Democratic People\'s Republic of Korea' => [40.0000, 127.0000],
 'Democratic Peoples Republic of Korea' => [40.0000, 127.0000],
 'Korea, Democratic Peoples Republic of' => [40.0000, 127.0000],
 "Korea, South" => [37.0000, 127.5000],
 'Republic of Korea' => [37.0000, 127.5000],
 'South Korea' => [37.0000, 127.5000],
 "Kuwait" => [29.5000, 45.7500],
 "Kyrgyzstan" => [41.0000, 75.0000],
 "Laos" => [18.0000, 105.0000],
 'Lao People\'s Democratic Republic' => [18.0000, 105.0000],
 'People\'s Democratic Republic of Laos' => [18.0000, 105.0000],
 'People\'s Democratic Republic of Lao' => [18.0000, 105.0000],
 "Latvia" => [57.0000, 25.0000],
 "Lebanon" => [33.8333, 35.8333],
 "Lesotho" => [-29.5000, 28.5000],
 "Liberia" => [6.5000, -9.5000],
 "Libya" => [25.0000, 17.0000],
 'Libyan Arab Jamahiriya' => [25.0000, 17.0000],
 "Liechtenstein" => [47.2667, 9.5333],
 "Lithuania" => [56.0000, 24.0000],
 "Luxembourg" => [49.7500, 6.1667],
 "Macau" => [22.1667, 113.5500],
 "Macedonia" => [41.8333, 22.0000],
 'Macedonia, The Former Yugoslav Republic of' => [41.8333, 22.0000],
 'The Former Yugoslav Republic of Macedonia' => [41.8333, 22.0000],
 'The former Yugoslav Republic of Macedonia' => [41.8333, 22.0000],
 "Madagascar" => [-20.0000, 47.0000],
 "Malawi" => [-13.5000, 34.0000],
 "Malaysia" => [2.5000, 112.5000],
 "Maldives" => [3.2500, 73.0000],
 "Mali" => [17.0000, -4.0000],
 "Malta" => [35.8333, 14.5833],
 "Marshall Islands" => [9.0000, 168.0000],
 "Martinique" => [14.6667, -61.0000],
 "Mauritania" => [20.0000, -12.0000],
 "Mauritius" => [-20.2833, 57.5500],
 "Mayotte" => [-12.8333, 45.1667],
 "Mexico" => [23.0000, -102.0000],
 "Micronesia, Federated States of" => [6.9167, 158.2500],
 "Federated States of Micronesia" => [6.9167, 158.2500],
 "Micronesia" => [6.9167, 158.2500],
 "Micronesia, Federated States" => [6.9167, 158.2500],
 "Midway Islands" => [28.2000, -177.3667],
 "Moldova" => [47.0000, 29.0000],
 "Moldova, Republic of" => [47.0000, 29.0000],
 "Monaco" => [43.7333, 7.4000],
 "Mongolia" => [46.0000, 105.0000],
 "Montenegro" => [42.5000, 19.3000],
 "Montserrat" => [16.7500, -62.2000],
 "Morocco" => [32.0000, -5.0000],
 "Mozambique" => [-18.2500, 35.0000],
 "Namibia" => [-22.0000, 17.0000],
 "Nauru" => [-0.5333, 166.9167],
 "Navassa Island" => [18.4167, -75.0333],
 "Nepal" => [28.0000, 84.0000],
 "Netherlands" => [52.5000, 5.7500],
 'Netherlands, Kingdom of the' => [52.5000, 5.7500],
 "Holland" => [52.5000, 5.7500],
 "Netherlands Antilles" => [12.2500, -68.7500],
 "Netherlands, Antilles" => [12.2500, -68.7500],
 "New Caledonia" => [-21.5000, 165.5000],
 "New Zealand" => [-41.0000, 174.0000],
 "Nicaragua" => [13.0000, -85.0000],
 "Niger" => [16.0000, 8.0000],
 "Niger, Republic of" => [16.0000, 8.0000],
 "Nigeria" => [10.0000, 8.0000],
 "Niue" => [-19.0333, -169.8667],
 "Norfolk Island" => [-29.0333, 167.9500],
 "Northern Mariana Islands" => [15.2000, 145.7500],
 "Norway" => [62.0000, 10.0000],
 "Oman" => [21.0000, 57.0000],
 "Pacific Ocean" => [0.0000, -160.0000],
 "Pakistan" => [30.0000, 70.0000],
 "Palau" => [7.5000, 134.5000],
 "Palmyra Atoll" => [5.8667, -162.0667],
 "Panama" => [9.0000, -80.0000],
 "Papua New Guinea" => [-6.0000, 147.0000],
 "Paracel Islands" => [16.5000, 112.0000],
 "Paraguay" => [-23.0000, -58.0000],
 "Peru" => [-10.0000, -76.0000],
 "Philippines" => [13.0000, 122.0000],
 "Pitcairn Islands" => [-25.0667, -130.1000],
 "Pitcairn" => [-25.0667, -130.1000],
 "Poland" => [52.0000, 20.0000],
 "Portugal" => [39.5000, -8.0000],
 "Puerto Rico" => [18.2500, -66.5000],
 "Qatar" => [25.5000, 51.2500],
 "Reunion" => [-21.1000, 55.6000],
 "Romania" => [46.0000, 25.0000],
 "Russia" => [60.0000, 100.0000],
 "Russian Federation" => [60.0000, 100.0000],
 "Russian Federation, The" => [60.0000, 100.0000],
 "The Russian Federation" => [60.0000, 100.0000],
 "USSR" => [60.0000, 100.0000],
 "The Soviet Union" => [60.0000, 100.0000],
 "Rwanda" => [-2.0000, 30.0000],
 "Saint Kitts and Nevis" => [17.3333, -62.7500],
 "Saint Lucia" => [13.8833, -60.9667],
 "Saint Pierre and Miquelon" => [46.8333, -56.3333],
 "Saint Vincent and the Grenadines" => [13.2500, -61.2000],
 "Samoa" => [-13.5833, -172.3333],
 "San Marino" => [43.7667, 12.4167],
 "Sao Tome and Principe" => [1.0000, 7.0000],
 "Saudi Arabia" => [25.0000, 45.0000],
 "Senegal" => [14.0000, -14.0000],
 "Serbia" => [44.0000, 21.0000],
 "Seychelles" => [-4.5833, 55.6667],
 "Sierra Leone" => [8.5000, -11.5000],
 "Singapore" => [1.3667, 103.8000],
 "Slovakia" => [48.6667, 19.5000],
 "Slovenia" => [46.1167, 14.8167],
 "Solomon Islands" => [-8.0000, 159.0000],
 "Somalia" => [10.0000, 49.0000],
 "South Africa" => [-29.0000, 24.0000],
 "South Georgia and the South Sandwich Islands" => [-54.5000, -37.0000],
 'South Georgia And The South Sandwich Islands' => [-54.5000, -37.0000],
 "Southern Ocean" => [-60.0000, 90.0000],
 "Spain" => [40.0000, -4.0000],
 "Spratly Islands" => [8.6333, 111.9167],
 "Sri Lanka" => [7.0000, 81.0000],
 "Sudan" => [15.0000, 30.0000],
 "Suriname" => [4.0000, -56.0000],
 "Svalbard" => [78.0000, 20.0000],
 "Swaziland" => [-26.5000, 31.5000],
 "Sweden" => [62.0000, 15.0000],
 "Switzerland" => [47.0000, 8.0000],
 "Syria" => [35.0000, 38.0000],
 'Syrian Arab Republic' => [35.0000, 38.0000],
 "Taiwan" => [23.5000, 121.0000],
 'Taiwan Province of China' => [23.5000, 121.0000], # Not really a provience of china but if it helps you find it
 "Tajikistan" => [39.0000, 71.0000],
 "Tanzania" => [-6.0000, 35.0000],
 "United Republic of Tanzania" => [-6.0000, 35.0000],
 "Tanzania, United Republic of" => [-6.0000, 35.0000],
 "Thailand" => [15.0000, 100.0000],
 "Togo" => [8.0000, 1.1667],
 "Tokelau" => [-9.0000, -172.0000],
 "Tonga" => [-20.0000, -175.0000],
 "Trinidad and Tobago" => [11.0000, -61.0000],
 "Tromelin Island" => [-15.8667, 54.4167],
 "Tunisia" => [34.0000, 9.0000],
 "Turkey" => [39.0000, 35.0000],
 "Turkmenistan" => [40.0000, 60.0000],
 "Turks and Caicos Islands" => [21.7500, -71.5833],
 'Turks and Caicas Islands' => [21.7500, -71.5833],
 "Tuvalu" => [-8.0000, 178.0000],
 "Uganda" => [1.0000, 32.0000],
 "Ukraine" => [49.0000, 32.0000],
 "United Arab Emirates" => [24.0000, 54.0000],
 "United Kingdom" => [54.0000, -2.0000],
 'United Kingdom of Great Britain and Northern Ireland' => [54.0000, -2.0000],
 'UK' => [54.0000, -2.0000],
 'GB' => [54.0000, -2.0000],
 'Great Britain' => [54.0000, -2.0000],
 'Britain' => [54.0000, -2.0000],
 "United States" => [38.0000, -97.0000],
 'United States of America' => [38.0000, -97.0000],
 'America' => [38.0000, -97.0000],
 'US' => [38.0000, -97.0000],
 'USA' => [38.0000, -97.0000],
 "United States Pacific Island Wildlife Refuges, Baker Island" => [0.2167, -176.4667],
 "United States Pacific Island Wildlife Refuges, Howland Island" => [0.8000, -176.6333],
 "United States Pacific Island Wildlife Refuges, Jarvis Island" => [-0.3833, -160.0167],
 "United States Pacific Island Wildlife Refuges, Johnston Atoll" => [16.7500, -169.5167],
 "United States Pacific Island Wildlife Refuges, Kingman Reef" => [6.3833, -162.4167],
 "United States Pacific Island Wildlife Refuges, Midway Islands" => [28.2000, -177.3667],
 "United States Pacific Island Wildlife Refuges, Palmyra Atoll" => [5.8833, -162.0833],
 "Uruguay" => [-33.0000, -56.0000],
 "Uzbekistan" => [41.0000, 64.0000],
 "Vanuatu" => [-16.0000, 167.0000],
 "Venezuela" => [8.0000, -66.0000],
 "Vietnam" => [16.0000, 106.0000],
 "Viet Nam" => [16.0000, 106.0000],
 "Virgin Islands" => [18.3333, -64.8333],
 "United States Virgin Islands" => [18.3333, -64.8333],
 "Virgin Islands, U.S." => [18.3333, -64.8333],
 "Virgin Islands, US" => [18.3333, -64.8333],
 "Wake Island" => [19.2833, 166.6500],
 "Wallis and Futuna" => [-13.3000, -176.2000],
 'Wallis and Futuna Islands' => [-13.3000, -176.2000],
 "West Bank" => [32.0000, 35.2500],
 "Western Sahara" => [24.5000, -13.0000],
 "Yemen" => [15.0000, 48.0000],
 "Democratic Yemen" => [15.0000, 48.0000],
 "Zambia" => [-15.0000, 30.0000],
 "Zimbabwe" => [-20.0000, 30.0000],
};

=head1 SUBROUTINES

=head2 latlong ($country_name)

Returns as a 1x2 anonymous array the latitude and longitude
for the country supplied as the sole argument, or C<undef> if
the country is not supported.

=cut

sub latlong ($) {
	shift if $_[0] eq __PACKAGE__;
	my $country = shift;
	return undef if not $country;
	return undef if not exists $countries_latlong->{$country};
	return wantarray? @{$countries_latlong->{$country}} : $countries_latlong->{$country};
}


=head2 supports ($country)

Returns a true value if the sole argument is a country name supported by this module;
otherwise, returns C<undef>.

=cut

sub supports ($) {
	shift if $_[0] eq __PACKAGE__;
	my $country = shift;
	return undef unless $country;
	return exists $countries_latlong->{$country};
}

=head2 unsupported

C<warn>s to C<STDERR> a list of C<Geography::Countries::countries>
that are not supported by this module.

=cut

sub unsupported {
	shift if $_[0] eq __PACKAGE__;
	warn "The following are not supported by ".__PACKAGE__.":\n";
	foreach (&Geography::Countries::countries){
		if (ref $countries_latlong->{$_} ne 'ARRAY'){
			warn "\t$_\n";
		}
	}
}


=head2 country

Just C<Geography::Countries>'s routine.

=cut

sub country {
	shift if $_[0] eq __PACKAGE__;
	return Geography::Countries::country(@_);
}

=head1 full_status

Returns a hash that describes what is and is not supported by L<Geography::Countries>,
in relation to this module. Keys are C<code2 code3 numcode countries absent>, of which
all but the last relate to the lists returned by the L<countrY> method
(L<Geography::Countries/The "country" subroutine.>). These entries may be on the
'todo' list of the relevant ISO groups, or of the L<Geography::Countries> author,
though my money is on the former.

The C<absent> key lists country names that are not supported: these are on my own
'todo' list.

The current value of this hash is:

	{
	  'code2' => [
				   'Isle of Man'
				 ],
	  'code3' => [
				   'Antarctica',
				   'Christmas Island',
				   'Mayotte',
				   'Heard Island and McDonald Islands',
				   'British Indian Ocean Territory',
				   'Heard Island And Mcdonald Islands',
				   'South Georgia and the South Sandwich Islands',
				   'Cocos (Keeling) Islands',
				   'Bouvet Island'
				 ],
	  'numcode' => [
					 'Antarctica',
					 'Christmas Island',
					 'Mayotte',
					 'Heard Island and McDonald Islands',
					 'British Indian Ocean Territory',
					 'Heard Island And Mcdonald Islands',
					 'South Georgia and the South Sandwich Islands',
					 'Cocos (Keeling) Islands',
					 'Bouvet Island'
				   ],
	  'countries' => [],
	  'absent' => [
				  'Antipodean Islands',
				  'Antipodes',
				  'Antipodes Islands',
				  'Brunei Darussalam',
				  'Canary Islands',
				  'EEC',
				  'EU',
				  'European Union',
				  'Faroc Islands',
				  'Galapagos Islands',
				  'Guatamala',
				  'Independent State of Samoa',
				  'Kermadec Islands',
				  'Madeira Islands',
				  'Micronesia-Polynesia',
				  'Prince Edward Islands',
				  'Saint Helena',
				  'Western Samoa',
				  'Yugoslavia',
				  'Zaire'
			],
	}

=cut

sub full_status {
	return {
          'code2' => [
                       'Isle of Man'
                     ],
          'code3' => [
                       'Antarctica',
                       'Christmas Island',
                       'Mayotte',
                       'Heard Island and McDonald Islands',
                       'British Indian Ocean Territory',
                       'Heard Island And Mcdonald Islands',
                       'South Georgia and the South Sandwich Islands',
                       'Cocos (Keeling) Islands',
                       'Bouvet Island'
                     ],
          'numcode' => [
                         'Antarctica',
                         'Christmas Island',
                         'Mayotte',
                         'Heard Island and McDonald Islands',
                         'British Indian Ocean Territory',
                         'Heard Island And Mcdonald Islands',
                         'South Georgia and the South Sandwich Islands',
                         'Cocos (Keeling) Islands',
                         'Bouvet Island'
                       ],
          'countries' => [],
          'absent' => [
					  'Antipodean Islands',
					  'Antipodes',
					  'Antipodes Islands',
					  'Brunei Darussalam',
					  'Canary Islands',
					  'EEC',
					  'EU',
					  'European Union',
					  'Faroc Islands',
					  'Galapagos Islands',
					  'Guatamala',
					  'Independent State of Samoa',
					  'Kermadec Islands',
					  'Madeira Islands',
					  'Micronesia-Polynesia',
					  'Prince Edward Islands',
					  'Saint Helena',
					  'Western Samoa',
					  'Yugoslavia',
					  'Zaire'
				],
        };
}

=head2 USE_OLD_DATA

Sets the module to use data from veresion 0.922.

=cut

sub USE_OLD_DATA {
	return $countries_latlong = $countries_latlong_old;
}

1;

__END__


=head1 UNSUPPORTED NAMES

It is no reflection on the countries listed: I just don't have the data at the time of writing.
All help appreicated, especially for Tibet, whose plight is being ignored by the Western powers
against all ethical rhetoric, in favour of cheap trade with the totalitarian state that occupies
this ancient land.

	Democratic Kampuchea
	Faeroe Islands
	French Southern Territories
	Melanesia
	Myanmar
	Pacific Islands (Trust Territory)
	Upper Volta
	Tibet

=head1 AUTHOR

Lee Goddard - lgoddard -at- cpan -dot- org

=head2 THANKS

Many thanks to Morten Bjørnsvik for checking and supplying data.

=head1 SEE ALSO

L<perl>, L<Geography::Countries>.

=head1 COPYRIGHT

Made publically available under the same terms as Perl itself.
