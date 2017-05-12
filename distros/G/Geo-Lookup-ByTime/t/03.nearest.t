use Test::More tests => 308;
use Data::Dumper;

use Geo::Lookup::ByTime qw(hav_distance);

my $base_time = time();

# Travel between cities in 20 minutes? It's like the future or something.
my $delta_time = 20 * 60;

my @cities = (
    ['Afghanistan',         'Kabul',            34.28,  69.11],
    ['Albania',             'Tirane',           41.18,  19.49],
    ['Algeria',             'Algiers',          36.42,  3.8],
    ['American Samoa',      'Pago Pago',        -14.16, -170.43],
    ['Andorra',             'Andorra la Vella', 42.31,  1.32],
    ['Angola',              'Luanda',           -8.50,  13.15],
    ['Antigua and Barbuda', 'W. Indies',        17.20,  -61.48],
    ['Argentina',           'Buenos Aires',     -36.30, -60.0],
    ['Armenia',             'Yerevan',          40.10,  44.31],
    ['Aruba',               'Oranjestad',       12.32,  -70.2],
    ['Australia',           'Canberra',         -35.15, 149.8],
    ['Austria',             'Vienna',           48.12,  16.22],
    ['Azerbaijan',          'Baku',             40.29,  49.56],
    ['Bahamas',             'Nassau',           25.5,   -77.20],
    ['Bahrain',             'Manama',           26.10,  50.30],
    ['Bangladesh',          'Dhaka',            23.43,  90.26],
    ['Barbados',            'Bridgetown',       13.5,   -59.30],
    ['Belarus',             'Minsk',            53.52,  27.30],
    ['Belgium',             'Brussels',         50.51,  4.21],
    ['Belize',              'Belmopan',         17.18,  -88.30],
    [
        'Benin', 'Porto-Novo (constitutional cotonou (seat of gvnt)',
        6.23, 2.42
    ],
    ['Bhutan',  'Thimphu',                           27.31,  89.45],
    ['Bolivia', 'La Paz (adm.)/sucre (legislative)', -16.20, -68.10],
    ['Bosnia and Herzegovina',   'Sarajevo',            43.52,  18.26],
    ['Botswana',                 'Gaborone',            -24.45, 25.57],
    ['Brazil',                   'Brasilia',            -15.47, -47.55],
    ['British Virgin Islands',   'Road Town',           18.27,  -64.37],
    ['Brunei Darussalam',        'Bandar Seri Begawan', 4.52,   115.0],
    ['Bulgaria',                 'Sofia',               42.45,  23.20],
    ['Burkina Faso',             'Ouagadougou',         12.15,  -1.30],
    ['Burundi',                  'Bujumbura',           -3.16,  29.18],
    ['Cambodia',                 'Phnom Penh',          11.33,  104.55],
    ['Cameroon',                 'Yaounde',             3.50,   11.35],
    ['Canada',                   'Ottawa',              45.27,  -75.42],
    ['Cape Verde',               'Praia',               15.2,   -23.34],
    ['Cayman Islands',           'George Town',         19.20,  -81.24],
    ['Central African Republic', 'Bangui',              4.23,   18.35],
    ['Chad',                     'N\'Djamena',          12.10,  14.59],
    ['Chile',                    'Santiago',            -33.24, -70.40],
    ['China',                    'Beijing',             39.55,  116.20],
    ['Colombia',                 'Bogota',              4.34,   -74.0],
    ['Comros',                   'Moroni',              -11.40, 43.16],
    ['Congo',                    'Brazzaville',         -4.9,   15.12],
    ['Costa Rica',               'San Jose',            9.55,   -84.2],
    ['Cote d\'Ivoire',           'Yamoussoukro',        6.49,   -5.17],
    ['Croatia',                  'Zagreb',              45.50,  15.58],
    ['Cuba',                     'Havana',              23.8,   -82.22],
    ['Cyprus',                   'Nicosia',             35.10,  33.25],
    ['Czech Republic',           'Prague',              50.5,   14.22],
    ['Democratic People\'s Republic of', 'P\'yongyang', 39.9,  125.30],
    ['Democratic Republic of the Congo', 'Kinshasa',    -4.20, 15.15],
    ['Denmark',                          'Copenhagen',  55.41, 12.34],
    ['Djibouti',                         'Djibouti',    11.8,  42.20],
    ['Dominica',                         'Roseau',      15.20, -61.24],
    ['Dominica Republic',           'Santo Domingo',  18.30,  -69.59],
    ['East Timor',                  'Dili',           -8.29,  125.34],
    ['Ecuador',                     'Quito',          -0.15,  -78.35],
    ['Egypt',                       'Cairo',          30.1,   31.14],
    ['El Salvador',                 'San Salvador',   13.40,  -89.10],
    ['Equatorial Guinea',           'Malabo',         3.45,   8.50],
    ['Eritrea',                     'Asmara',         15.19,  38.55],
    ['Estonia',                     'Tallinn',        59.22,  24.48],
    ['Ethiopia',                    'Addis Ababa',    9.2,    38.42],
    ['Falkland Islands (Malvinas)', 'Stanley',        -51.40, -59.51],
    ['Faroe Islands',               'Torshavn',       62.5,   -6.56],
    ['Fiji',                        'Suva',           -18.6,  178.30],
    ['Finland',                     'Helsinki',       60.15,  25.3],
    ['France',                      'Paris',          48.50,  2.20],
    ['French Guiana',               'Cayenne',        5.5,    -52.18],
    ['French Polynesia',            'Papeete',        -17.32, -149.34],
    ['Gabon',                       'Libreville',     0.25,   9.26],
    ['Gambia',                      'Banjul',         13.28,  -16.40],
    ['Georgia',                     'T\'bilisi',      41.43,  44.50],
    ['Germany',                     'Berlin',         52.30,  13.25],
    ['Ghana',                       'Accra',          5.35,   -0.6],
    ['Greece',                      'Athens',         37.58,  23.46],
    ['Greenland',                   'Nuuk',           64.10,  -51.35],
    ['Guadeloupe',                  'Basse-Terre',    16.0,   -61.44],
    ['Guatemala',                   'Guatemala',      14.40,  -90.22],
    ['Guernsey',                    'St. Peter Port', 49.26,  -2.33],
    ['Guinea',                      'Conakry',        9.29,   -13.49],
    ['Guinea-Bissau',               'Bissau',         11.45,  -15.45],
    ['Guyana',                      'Georgetown',     6.50,   -58.12],
    ['Haiti',                       'Port-au-Prince', 18.40,  -72.20],
    ['Heard Island and McDonald Islands', ' ',           -53.0, 74.0],
    ['Honduras',                          'Tegucigalpa', 14.5,  -87.14],
    ['Hungary',                           'Budapest',    47.29, 19.5],
    ['Iceland',                           'Reykjavik',   64.10, -21.57],
    ['India',                             'New Delhi',   28.37, 77.13],
    ['Indonesia',                         'Jakarta',     -6.9,  106.49],
    ['Iran (Islamic Republic of)',        'Tehran',      35.44, 51.30],
    ['Iraq',                              'Baghdad',     33.20, 44.30],
    ['Ireland',                           'Dublin',      53.21, -6.15],
    ['Israel',                            'Jerusalem',   31.71, -35.10],
    ['Italy',                             'Rome',        41.54, 12.29],
    ['Jamaica',                           'Kingston',    18.0,  -76.50],
    ['Jordan',                            'Amman',       31.57, 35.52],
    ['Kazakhstan',                        'Astana',      51.10, 71.30],
    ['Kenya',                             'Nairobi',     -1.17, 36.48],
    ['Kiribati',                          'Tarawa',      1.30,  173.0],
    ['Kuwait',                            'Kuwait',      29.30, 48.0],
    ['Kyrgyzstan',                        'Bishkek',     42.54, 74.46],
    ['Lao People\'s Democratic Republic', 'Vientiane',   17.58, 102.36],
    ['Latvia',                            'Riga',        56.53, 24.8],
    ['Lebanon',                           'Beirut',      33.53, 35.31],
    ['Lesotho',                'Maseru',         -29.18, 27.30],
    ['Liberia',                'Monrovia',       6.18,   -10.47],
    ['Libyan Arab Jamahiriya', 'Tripoli',        32.49,  13.7],
    ['Liechtenstein',          'Vaduz',          47.8,   9.31],
    ['Lithuania',              'Vilnius',        54.38,  25.19],
    ['Luxembourg',             'Luxembourg',     49.37,  6.9],
    ['Macao, China',           'Macau',          22.12,  113.33],
    ['Madagascar',             'Antananarivo',   -18.55, 47.31],
    ['Malawi',                 'Lilongwe',       -14.0,  33.48],
    ['Malaysia',               'Kuala Lumpur',   3.9,    101.41],
    ['Maldives',               'Male',           4.0,    73.28],
    ['Mali',                   'Bamako',         12.34,  -7.55],
    ['Malta',                  'Valletta',       35.54,  14.31],
    ['Martinique',             'Fort-de-France', 14.36,  -61.2],
    ['Mauritania',             'Nouakchott',     -20.10, 57.30],
    ['Mayotte',                'Mamoudzou',      -12.48, 45.14],
    ['Mexico',                 'Mexico',         19.20,  -99.10],
    ['Micronesia (Federated States of)', 'Palikir',   6.55,   158.9],
    ['Moldova, Republic of',             'Chisinau',  47.2,   28.50],
    ['Mozambique',                       'Maputo',    -25.58, 32.32],
    ['Myanmar',                          'Yangon',    16.45,  96.20],
    ['Namibia',                          'Windhoek',  -22.35, 17.4],
    ['Nepal',                            'Kathmandu', 27.45,  85.20],
    ['Netherlands', 'Amsterdam/The Hague (seat of Gvnt)', 52.23, 4.54],
    ['Netherlands Antilles',      'Willemstad',   12.5,   -69.0],
    ['New Caledonia',             'Noumea',       -22.17, 166.30],
    ['New Zealand',               'Wellington',   -41.19, 174.46],
    ['Nicaragua',                 'Managua',      12.6,   -86.20],
    ['Niger',                     'Niamey',       13.27,  2.6],
    ['Nigeria',                   'Abuja',        9.5,    7.32],
    ['Norfolk Island',            'Kingston',     -45.20, 168.43],
    ['Northern Mariana Islands',  'Saipan',       15.12,  145.45],
    ['Norway',                    'Oslo',         59.55,  10.45],
    ['Oman',                      'Masqat',       23.37,  58.36],
    ['Pakistan',                  'Islamabad',    33.40,  73.10],
    ['Palau',                     'Koror',        7.20,   134.28],
    ['Panama',                    'Panama',       9.0,    -79.25],
    ['Papua New Guinea',          'Port Moresby', -9.24,  147.8],
    ['Paraguay',                  'Asuncion',     -25.10, -57.30],
    ['Peru',                      'Lima',         -12.0,  -77.0],
    ['Philippines',               'Manila',       14.40,  121.3],
    ['Poland',                    'Warsaw',       52.13,  21.0],
    ['Portugal',                  'Lisbon',       38.42,  -9.10],
    ['Puerto Rico',               'San Juan',     18.28,  -66.7],
    ['Qatar',                     'Doha',         25.15,  51.35],
    ['Republic of Korea',         'Seoul',        37.31,  126.58],
    ['Romania',                   'Bucuresti',    44.27,  26.10],
    ['Russian Federation',        'Moskva',       55.45,  37.35],
    ['Rawanda',                   'Kigali',       -1.59,  30.4],
    ['Saint Kitts and Nevis',     'Basseterre',   17.17,  -62.43],
    ['Saint Lucia',               'Castries',     14.2,   -60.58],
    ['Saint Pierre and Miquelon', 'Saint-Pierre', 46.46,  -56.12],
    ['Saint vincent and the Greenadines', 'Kingstown', 13.10,  -61.10],
    ['Samoa',                             'Apia',      -13.50, -171.50],
    ['San Marino',            'San Marino', 43.55, 12.30],
    ['Sao Tome and Principe', 'Sao Tome',   0.10,  6.39],
    ['Saudi Arabia',          'Riyadh',     24.41, 46.42],
    ['Senegal',               'Dakar',      14.34, -17.29],
    ['Sierra Leone',          'Freetown',   8.30,  -13.17],
    ['Slovakia',              'Bratislava', 48.10, 17.7],
    ['Slovenia',              'Ljubljana',  46.4,  14.33],
    ['Solomon Islands',       'Honiara',    -9.27, 159.57],
    ['Somalia',               'Mogadishu',  2.2,   45.25],
    [
        'South Africa',
        'Pretoria (adm.) / Cap Town (Legislative) / Bloemfontein (Judicial)',
        -25.44,
        28.12
    ],
    ['Spain',                'Madrid',         40.25,  -3.45],
    ['Sudan',                'Khartoum',       15.31,  32.35],
    ['Suriname',             'Paramaribo',     5.50,   -55.10],
    ['Swaziland',            'Mbabane (Adm.)', -26.18, 31.6],
    ['Sweden',               'Stockholm',      59.20,  18.3],
    ['Switzerland',          'Bern',           46.57,  7.28],
    ['Syrian Arab Republic', 'Damascus',       33.30,  36.18],
    ['Tajikistan',           'Dushanbe',       38.33,  68.48],
    ['Thailand',             'Bangkok',        13.45,  100.35],
    [
        'The Former Yugoslav Republic of Macedonia', 'Skopje', 42.1,
        21.26
    ],
    ['Togo',                 'Lome',        6.9,    1.20],
    ['Tonga',                'Nuku\'alofa', -21.10, -174.0],
    ['Tunisia',              'Tunis',       36.50,  10.11],
    ['Turkey',               'Ankara',      39.57,  32.54],
    ['Turkmenistan',         'Ashgabat',    38.0,   57.50],
    ['Tuvalu',               'Funafuti',    -8.31,  179.13],
    ['Uganda',               'Kampala',     0.20,   32.30],
    ['Ukraine',              'Kiev (Rus)',  50.30,  30.28],
    ['United Arab Emirates', 'Abu Dhabi',   24.28,  54.22],
    [
        'United Kingdom of Great Britain and Northern Ireland',
        'London', 51.36, -0.5
    ],
    ['United Republic of Tanzania', 'Dodoma',        -6.8,  35.45],
    ['United States of America',    'Washington DC', 39.91, -77.2],
    [
        'United States of Virgin Islands', 'Charlotte Amalie',
        18.21,                             -64.56
    ],
    ['Uruguay',    'Montevideo', -34.50, -56.11],
    ['Uzbekistan', 'Tashkent',   41.20,  69.10],
    ['Vanuatu',    'Port-Vila',  -17.45, 168.18],
    ['Venezuela',  'Caracas',    10.30,  -66.55],
    ['Viet Nam',   'Hanoi',      21.5,   105.55],
    ['Yugoslavia', 'Belgrade',   44.50,  20.37],
    ['Zambia',     'Lusaka',     -15.28, 28.16],
    ['Zimbabwe',   'Harare',     -17.43, 31.2]
);

sub cities {
    my $time = $base_time;
    my $pos  = 0;
    my $max  = @cities;
    return sub {
        return if $pos >= $max;
        my $city = $cities[$pos++];
        my $pt   = {
            name => join(', ', $city->[1], $city->[0]),
            lat  => $city->[2],
            lon  => $city->[3],
            time => $time
        };
        $time += $delta_time;
        return $pt;
    };
}

sub brute_force_nearest {
    my $tm        = shift;
    my $best_time = undef;
    my $best_city = undef;

    my $iter = cities();
    while (my $city = $iter->()) {
        my $time = abs($tm - $city->{time});
        if (!defined($best_time) || $time < $best_time) {
            $best_time = $time;
            $best_city = $city;
        }
    }

    return ($best_city, $best_time);
}

my $index = Geo::Lookup::ByTime->new(cities());
my ($first, $last) = $index->time_range();
is($first, $base_time, 'first time');
is($last, $base_time + (scalar(@cities) - 1) * $delta_time,
    'last time');

my $dtime = int(($last - $first) / 100);
for (my $rtm = $first; $rtm < $last; $rtm += $dtime) {
    my $tm = $rtm + 0.1;
    my ($synpt, $realpt, $dist) = $index->nearest($tm);
    my $syn2 = $index->nearest($tm);
    is_deeply($synpt, $syn2, 'both modes return the same point');
    my ($best_city, $best_time) = brute_force_nearest($tm);
    is_deeply($realpt, $best_city, 'best match found');

    # Check distance limit works
    my $limit = 1_000_000;
    my ($got, $rp, $d) = $index->nearest($tm, $limit);
    ok(!defined($got) || $d <= $limit, 'limit works');
}

# Ends of range
my ($syn, $real, $dist) = $index->nearest($first);
ok(defined($syn), 'got first');
is($dist, 0, 'first distance ok');

($syn, $real, $dist) = $index->nearest($last);
ok(defined($syn), 'got last');
is($dist, 0, 'last distance ok');

($syn, $real, $dist) = $index->nearest($first - 1);
is($syn, undef, 'before first');

($syn, $real, $dist) = $index->nearest($last + 1);
is($syn, undef, 'after last');
