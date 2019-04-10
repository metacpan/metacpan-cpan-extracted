#!perl

use constant test_count => 10;

use strict;
use warnings;
use Test::More tests => test_count;

sub GetPoints();

use_ok( 'Geo::Index' );

my $index = Geo::Index->new( { levels=>20, quiet=>1 } );
isa_ok $index, 'Geo::Index', 'Geo::Index object';

my $_points = GetPoints();
$index->IndexPoints( $_points );

my %points_by_name = ( );
map { $points_by_name{$_->{name}} = $_; } @$_points;

my $_results;
my @expected;
my @results;


# All points on globe
my $_all = [ "Abu Dhabi, United Arab Emirates", "Abuja, Nigeria", "Accra, Ghana", "Addis Ababa, Ethiopia", "Algiers, Algeria", "Amman, Jordan", "Amsterdam / The Hague (seat of Government), Netherlands", "Andorra la Vella, Andorra", 
             "Ankara, Turkey", "Antananarivo, Madagascar", "Apia, Samoa", "Ashgabat, Turkmenistan", "Asmara, Eritrea", "Astana, Kazakhstan", "Asuncion, Paraguay", "Athens, Greece", "Baghdad, Iraq", "Baku, Azerbaijan", "Bamako, Mali", 
            "Bandar Seri Begawan, Brunei Darussalam", "Bangkok, Thailand", "Bangui, Central African Republic", "Banjul, Gambia", "Basse-Terre, Guadeloupe", "Basseterre, Saint Kitts and Nevis", "Beijing, China", "Beirut, Lebanon", 
             "Belgrade, Yugoslavia", "Belmopan, Belize", "Berlin, Germany", "Bern, Switzerland", "Bishkek, Kyrgyzstan", "Bissau, Guinea-Bissau", "Bogota, Colombia", "Brasilia, Brazil", "Bratislava, Slovakia", "Brazzaville, Congo", 
             "Bridgetown, Barbados", "Brussels, Belgium", "Bucuresti, Romania", "Budapest, Hungary", "Buenos Aires, Argentina", "Bujumbura, Burundi", "Cairo, Egypt", "Canberra, Australia", "Caracas, Venezuela", "Castries, Saint Lucia", 
             "Cayenne, French Guiana", "Charlotte Amalie, United States Virgin Islands", "Chisinau, Moldova, Republic of", "Conakry, Guinea", "Copenhagen, Denmark", "Dakar, Senegal", "Damascus, Syrian Arab Republic", "Dhaka, Bangladesh", 
             "Dili, East Timor", "Djibouti, Djibouti", "Dodoma, United Republic of Tanzania", "Doha, Qatar", "Dublin, Ireland", "Dushanbe, Tajikistan", "Fort-de-France, Martinique", "Freetown, Sierra Leone", "Funafuti, Tuvalu", 
             "Gaborone, Botswana", "George Town, Cayman Islands", "Georgetown, Guyana", "Guatemala, Guatemala", "Hanoi, Viet Nam", "Harare, Zimbabwe", "Havana, Cuba", "Heard Island and McDonald Islands", "Helsinki, Finland", 
             "Hobart, Tasmania, Australia", "Honiara, Solomon Islands", "Islamabad, Pakistan", "Jakarta, Indonesia", "Jerusalem, Israel", "Kabul, Afghanistan", "Kampala, Uganda", "Kathmandu, Nepal", "Khartoum, Sudan", "Kiev, Ukraine", 
             "Kigali, Rawanda", "Kingston, Jamaica", "Kingston, Norfolk Island", "Kingstown, Saint Vincent and the Greeadines", "Kinshasa, Democratic Republic of the Congo", "Koror, Palau", "Kuala Lumpur, Malaysia", "Kuwait, Kuwait", 
             "La Paz (administrative) / Sucre (legislative), Bolivia", "Libreville, Gabon", "Lilongwe, Malawi", "Lima, Peru", "Lisbon, Portugal", "Ljubljana, Slovenia", "Lome, Togo", "London, United Kingdom of Great Britain and Northern Ireland", 
             "Luanda, Angola", "Lusaka, Zambia", "Luxembourg, Luxembourg", "Macau, Macao, China", "Madrid, Spain", "Malabo, Equatorial Guinea", "Male, Maldives", "Mamoudzou, Mayotte", "Managua, Nicaragua", "Manama, Bahrain", 
             "Manila, Philippines", "Maputo, Mozambique", "Maseru, Lesotho", "Masqat, Oman", "Mbabane (administrative), Swaziland", "McMurdo Station, Antarctica", "Mexico, Mexico", "Minsk, Belarus", "Mogadishu, Somalia", "Monrovia, Liberia", 
             "Montevideo, Uruguay", "Moroni, Comros", "Moskva, Russian Federation", "N'Djamena, Chad", "Nairobi, Kenya", "Nassau, Bahamas", "New Delhi, India", "Niamey, Niger", "Nicosia, Cyprus", "North pole, Arctic", "Nouakchott, Mauritania", 
             "Noumea, New Caledonia", "Nuku'alofa, Tonga", "Nuuk, Greenland", "Oranjestad, Aruba", "Oslo, Norway", "Ottawa, Canada", "Ouagadougou, Burkina Faso", "Pago Pago, American Samoa", "Palikir, Micronesia (Federated States of)", 
             "Panama, Panama", "Papeete, French Polynesia", "Paramaribo, Suriname", "Paris, France", "Phnom Penh, Cambodia", "Port Moresby, Papua New Guinea", "Port-Vila, Vanuatu", "Port-au-Prince, Haiti", 
             "Porto Novo (constitutional) / Cotonou (seat of government), Benin", "Prague, Czech Republic", "Praia, Cape Verde", "Pretoria (administrative) / Cape Town (legislative) / Bloemfontein (judicial), South Africa", 
             "Pyongyang, North Korea", "Quito, Ecuador", "Reykjavik, Iceland", "Riga, Latvia", "Riyadh, Saudi Arabia", "Road Town, British Virgin Islands", "Rome, Italy", "Roseau, Dominica", "Saint-Pierre, Saint Pierre and Miquelon", 
             "Saipan, Northern Mariana Islands", "San Jose, Costa Rica", "San Juan, Puerto Rico", "San Marino, San Marino", "San Salvador, El Salvador", "Santiago, Chile", "Santo Domingo, Dominica Republic", "Sao Tome, Sao Tome and Principe", 
             "Sarajevo, Bosnia and Herzegovina", "Seoul, Republic of Korea", "Skopje, Macedonia (Former Yugoslav Republic)", "Sofia, Bulgaria", "South pole, Antarctica", "St. Peter Port, Guernsey", "Stanley, Falkland Islands (Malvinas)", 
             "Stockholm, Sweden", "Suva, Fiji", "Svalbard, Norway", "T'bilisi, Georgia", "Tallinn, Estonia", "Tarawa, Kiribati", "Tashkent, Uzbekistan", "Tegucigalpa, Honduras", "Tehran, Iran (Islamic Republic of)", "Thimphu, Bhutan", 
             "Tirane, Albania", "Torshavn, Faroe Islands", "Tripoli, Libyan Arab Jamahiriya", "Tunis, Tunisia", "Ushuaia, Argentina", "Vaduz, Liechtenstein", "Valletta, Malta", "Vienna, Austria", "Vientiane, Lao People's Democratic Republic", 
             "Vilnius, Lithuania", "Warsaw, Poland", "Washington DC, United States of America", "Wellington, New Zealand", "West Indies, Antigua and Barbuda", "Willemstad, Netherlands Antilles", "Windhoek, Namibia", "Yamoussoukro, Cote d'Ivoire", 
             "Yangon, Myanmar", "Yaounde, Cameroon", "Yerevan, Armenia", "Zagreb, Croatia" ];
$_results = $index->Search( $$_points[0] );
@expected = sort @$_all;
@results = sort map { $_->{name}; } @$_results;
is_deeply( \@results, \@expected, "All points on globe" );

# Max results, sorted
$_results = $index->Search( $points_by_name{'Ushuaia, Argentina'}, { sort_results=>1, max_results=>10 } );
@expected = ( 
              'Ushuaia, Argentina', 
              'Stanley, Falkland Islands (Malvinas)', 
              'Buenos Aires, Argentina', 
              'Santiago, Chile', 
              'Montevideo, Uruguay', 
              'Asuncion, Paraguay', 
              'South pole, Antarctica', 
              'La Paz (administrative) / Sucre (legislative), Bolivia', 
              'Brasilia, Brazil', 
              'McMurdo Station, Antarctica' 
            );
@results = map { $_->{name}; } @$_results;
is_deeply( \@results, \@expected, "Max results, sorted" );

# All points on globe, quick_results=>1
$_results = $index->Search( $$_points[0], { quick_results=>1 } );
@expected = sort @$_all;
@results = ();
foreach my $_set (@$_results) {
 push @results, @$_set if (defined $_set);
}
@results = sort map { $_->{name}; } @results;
is_deeply( \@results, \@expected, "All points on globe, quick_results=>1" );


@expected = (
              'Amsterdam / The Hague (seat of Government), Netherlands  (0 km)',
              'Brussels, Belgium  (192 km)',
              'London, United Kingdom of Great Britain and Northern Ireland  (330 km)',
              'Luxembourg, Luxembourg  (336 km)',
              'Paris, France  (446 km)',
              'St. Peter Port, Guernsey  (585 km)',
              'Berlin, Germany  (592 km)',
              'Copenhagen, Denmark  (621 km)',
              'Bern, Switzerland  (659 km)',
              'Vaduz, Liechtenstein  (667 km)',
              'Prague, Czech Republic  (716 km)',
              'Dublin, Ireland  (727 km)',
              'Oslo, Norway  (892 km)',
              'Vienna, Austria  (947 km)',
              'Ljubljana, Slovenia  (988 km)'
            );


# radius, sort_results=>1
$_results = $index->Search( $points_by_name{"Amsterdam / The Hague (seat of Government), Netherlands"}, { radius=>1_000_000, sort_results=>1 } );
@results = map { "$_->{name}  (".int($_->{search_result_distance}/1000)." km)"; } @$_results;
is_deeply( \@results, \@expected, "radius, sort_results=>1" );


# radius, sort_results=>1, tile_adjust=>1
$_results = $index->Search( $points_by_name{"Amsterdam / The Hague (seat of Government), Netherlands"}, { radius=>1_000_000, sort_results=>1, tile_adjust=>1 } );
@results = map { "$_->{name}  (".int($_->{search_result_distance}/1000)." km)"; } @$_results;
is_deeply( \@results, \@expected, "radius, sort_results=>1, tile_adjust=>1" );


# radius, sort_results=>1, tile_adjust=>-1
$_results = $index->Search( $points_by_name{"Amsterdam / The Hague (seat of Government), Netherlands"}, { radius=>1_000_000, sort_results=>1, tile_adjust=>-1 } );
@results = map { "$_->{name}  (".int($_->{search_result_distance}/1000)." km)"; } @$_results;
is_deeply( \@results, \@expected, "radius, sort_results=>1, tile_adjust=>-1" );


# Pre-condition, sorted
$_results = $index->Search( $points_by_name{"Nairobi, Kenya"}, { pre_condition=>sub { return ($_[0]->{name} =~ /$_[2]/); }, user_data=>'^C' } );
@expected = ( 
              'Cairo, Egypt',
              'Canberra, Australia',
              'Caracas, Venezuela',
              'Castries, Saint Lucia',
              'Cayenne, French Guiana',
              'Charlotte Amalie, United States Virgin Islands',
              'Chisinau, Moldova, Republic of',
              'Conakry, Guinea',
              'Copenhagen, Denmark'
            );
@results = sort map { $_->{name}; } @$_results;
is_deeply( \@results, \@expected, "Pre-condition, sorted" );


# Post-condition, sorted
$_results = $index->Search( $points_by_name{"Kiev, Ukraine"}, { post_condition=>sub { return ($_[0]->{name} =~ /$_[2]/); }, user_data=>'^D' } );
@expected = ( 
              'Dakar, Senegal',
              'Damascus, Syrian Arab Republic',
              'Dhaka, Bangladesh',
              'Dili, East Timor',
              'Djibouti, Djibouti',
              'Dodoma, United Republic of Tanzania',
              'Doha, Qatar',
              'Dublin, Ireland',
              'Dushanbe, Tajikistan'
            );
@results = sort map { $_->{name}; } @$_results;
is_deeply( \@results, \@expected, "Post-condition, sorted" );





done_testing;


sub GetPoints() {
	return [
	         { lat=>-90.0, lon=>0.0, name=>"South pole, Antarctica" }, 
	         { lat=>-77.846323, lon=>166.668235, name=>"McMurdo Station, Antarctica" }, 
	         { lat=>90.0, lon=>0.0, name=>"North pole, Arctic" }, 
	         { lat=>34.28, lon=>69.11, name=>"Kabul, Afghanistan" }, 
	         { lat=>41.18, lon=>19.49, name=>"Tirane, Albania" }, 
	         { lat=>36.42, lon=>3.08, name=>"Algiers, Algeria" }, 
	         { lat=>-14.16, lon=>-170.43, name=>"Pago Pago, American Samoa" }, 
	         { lat=>42.31, lon=>1.32, name=>"Andorra la Vella, Andorra" }, 
	         { lat=>-8.50, lon=>13.15, name=>"Luanda, Angola" }, 
	         { lat=>17.20, lon=>-61.48, name=>"West Indies, Antigua and Barbuda" }, 
	         { lat=>-36.30, lon=>-60.00, name=>"Buenos Aires, Argentina" }, 
	         { lat=>-54.801944, lon=>-68.303056, name=>"Ushuaia, Argentina" }, 
	         { lat=>40.10, lon=>44.31, name=>"Yerevan, Armenia" }, 
	         { lat=>12.32, lon=>-70.02, name=>"Oranjestad, Aruba" }, 
	         { lat=>-35.15, lon=>149.08, name=>"Canberra, Australia" }, 
	         { lat=>-42.88188, lon=>147.32683, name=>"Hobart, Tasmania, Australia" }, 
	         { lat=>48.12, lon=>16.22, name=>"Vienna, Austria" }, 
	         { lat=>40.29, lon=>49.56, name=>"Baku, Azerbaijan" }, 
	         { lat=>25.05, lon=>-77.20, name=>"Nassau, Bahamas" }, 
	         { lat=>26.10, lon=>50.30, name=>"Manama, Bahrain" }, 
	         { lat=>23.43, lon=>90.26, name=>"Dhaka, Bangladesh" }, 
	         { lat=>13.05, lon=>-59.30, name=>"Bridgetown, Barbados" }, 
	         { lat=>53.52, lon=>27.30, name=>"Minsk, Belarus" }, 
	         { lat=>50.51, lon=>4.21, name=>"Brussels, Belgium" }, 
	         { lat=>17.18, lon=>-88.30, name=>"Belmopan, Belize" }, 
	         { lat=>6.23, lon=>2.42, name=>"Porto Novo (constitutional) / Cotonou (seat of government), Benin" }, 
	         { lat=>27.31, lon=>89.45, name=>"Thimphu, Bhutan" }, 
	         { lat=>-16.20, lon=>-68.10, name=>"La Paz (administrative) / Sucre (legislative), Bolivia" }, 
	         { lat=>43.52, lon=>18.26, name=>"Sarajevo, Bosnia and Herzegovina" }, 
	         { lat=>-24.45, lon=>25.57, name=>"Gaborone, Botswana" }, 
	         { lat=>-15.47, lon=>-47.55, name=>"Brasilia, Brazil" }, 
	         { lat=>18.27, lon=>-64.37, name=>"Road Town, British Virgin Islands" }, 
	         { lat=>4.52, lon=>115.00, name=>"Bandar Seri Begawan, Brunei Darussalam" }, 
	         { lat=>42.45, lon=>23.20, name=>"Sofia, Bulgaria" }, 
	         { lat=>12.15, lon=>-1.30, name=>"Ouagadougou, Burkina Faso" }, 
	         { lat=>-3.16, lon=>29.18, name=>"Bujumbura, Burundi" }, 
	         { lat=>11.33, lon=>104.55, name=>"Phnom Penh, Cambodia" }, 
	         { lat=>3.50, lon=>11.35, name=>"Yaounde, Cameroon" }, 
	         { lat=>45.27, lon=>-75.42, name=>"Ottawa, Canada" }, 
	         { lat=>15.02, lon=>-23.34, name=>"Praia, Cape Verde" }, 
	         { lat=>19.20, lon=>-81.24, name=>"George Town, Cayman Islands" }, 
	         { lat=>4.23, lon=>18.35, name=>"Bangui, Central African Republic" }, 
	         { lat=>12.10, lon=>14.59, name=>"N'Djamena, Chad" }, 
	         { lat=>-33.24, lon=>-70.40, name=>"Santiago, Chile" }, 
	         { lat=>39.55, lon=>116.20, name=>"Beijing, China" }, 
	         { lat=>4.34, lon=>-74.00, name=>"Bogota, Colombia" }, 
	         { lat=>-11.40, lon=>43.16, name=>"Moroni, Comros" }, 
	         { lat=>-4.09, lon=>15.12, name=>"Brazzaville, Congo" }, 
	         { lat=>9.55, lon=>-84.02, name=>"San Jose, Costa Rica" }, 
	         { lat=>6.49, lon=>-5.17, name=>"Yamoussoukro, Cote d'Ivoire" }, 
	         { lat=>45.50, lon=>15.58, name=>"Zagreb, Croatia" }, 
	         { lat=>23.08, lon=>-82.22, name=>"Havana, Cuba" }, 
	         { lat=>35.10, lon=>33.25, name=>"Nicosia, Cyprus" }, 
	         { lat=>50.05, lon=>14.22, name=>"Prague, Czech Republic" }, 
	         { lat=>-4.20, lon=>15.15, name=>"Kinshasa, Democratic Republic of the Congo" }, 
	         { lat=>55.41, lon=>12.34, name=>"Copenhagen, Denmark" }, 
	         { lat=>11.08, lon=>42.20, name=>"Djibouti, Djibouti" }, 
	         { lat=>15.20, lon=>-61.24, name=>"Roseau, Dominica" }, 
	         { lat=>18.30, lon=>-69.59, name=>"Santo Domingo, Dominica Republic" }, 
	         { lat=>-8.29, lon=>125.34, name=>"Dili, East Timor" }, 
	         { lat=>-0.15, lon=>-78.35, name=>"Quito, Ecuador" }, 
	         { lat=>30.01, lon=>31.14, name=>"Cairo, Egypt" }, 
	         { lat=>13.40, lon=>-89.10, name=>"San Salvador, El Salvador" }, 
	         { lat=>3.45, lon=>8.50, name=>"Malabo, Equatorial Guinea" }, 
	         { lat=>15.19, lon=>38.55, name=>"Asmara, Eritrea" }, 
	         { lat=>59.22, lon=>24.48, name=>"Tallinn, Estonia" }, 
	         { lat=>9.02, lon=>38.42, name=>"Addis Ababa, Ethiopia" }, 
	         { lat=>-51.40, lon=>-59.51, name=>"Stanley, Falkland Islands (Malvinas)" }, 
	         { lat=>62.05, lon=>-6.56, name=>"Torshavn, Faroe Islands" }, 
	         { lat=>-18.06, lon=>178.30, name=>"Suva, Fiji" }, 
	         { lat=>60.15, lon=>25.03, name=>"Helsinki, Finland" }, 
	         { lat=>48.50, lon=>2.20, name=>"Paris, France" }, 
	         { lat=>5.05, lon=>-52.18, name=>"Cayenne, French Guiana" }, 
	         { lat=>-17.32, lon=>-149.34, name=>"Papeete, French Polynesia" }, 
	         { lat=>0.25, lon=>9.26, name=>"Libreville, Gabon" }, 
	         { lat=>13.28, lon=>-16.40, name=>"Banjul, Gambia" }, 
	         { lat=>41.43, lon=>44.50, name=>"T'bilisi, Georgia" }, 
	         { lat=>52.30, lon=>13.25, name=>"Berlin, Germany" }, 
	         { lat=>5.35, lon=>-0.06, name=>"Accra, Ghana" }, 
	         { lat=>37.58, lon=>23.46, name=>"Athens, Greece" }, 
	         { lat=>64.1175, lon=>-51.738889, name=>"Nuuk, Greenland" }, 
	         { lat=>16.00, lon=>-61.44, name=>"Basse-Terre, Guadeloupe" }, 
	         { lat=>14.40, lon=>-90.22, name=>"Guatemala, Guatemala" }, 
	         { lat=>49.26, lon=>-2.33, name=>"St. Peter Port, Guernsey" }, 
	         { lat=>9.29, lon=>-13.49, name=>"Conakry, Guinea" }, 
	         { lat=>11.45, lon=>-15.45, name=>"Bissau, Guinea-Bissau" }, 
	         { lat=>6.50, lon=>-58.12, name=>"Georgetown, Guyana" }, 
	         { lat=>18.40, lon=>-72.20, name=>"Port-au-Prince, Haiti" }, 
	         { lat=>-53.00, lon=>74.00, name=>"Heard Island and McDonald Islands" }, 
	         { lat=>14.05, lon=>-87.14, name=>"Tegucigalpa, Honduras" }, 
	         { lat=>47.29, lon=>19.05, name=>"Budapest, Hungary" }, 
	         { lat=>64.133333, lon=>-21.933333, name=>"Reykjavik, Iceland" }, 
	         { lat=>28.37, lon=>77.13, name=>"New Delhi, India" }, 
	         { lat=>-6.09, lon=>106.49, name=>"Jakarta, Indonesia" }, 
	         { lat=>35.44, lon=>51.30, name=>"Tehran, Iran (Islamic Republic of)" }, 
	         { lat=>33.20, lon=>44.30, name=>"Baghdad, Iraq" }, 
	         { lat=>53.21, lon=>-6.15, name=>"Dublin, Ireland" }, 
	         { lat=>31.71, lon=>35.10, name=>"Jerusalem, Israel" }, 
	         { lat=>41.54, lon=>12.29, name=>"Rome, Italy" }, 
	         { lat=>18.00, lon=>-76.50, name=>"Kingston, Jamaica" }, 
	         { lat=>31.57, lon=>35.52, name=>"Amman, Jordan" }, 
	         { lat=>51.10, lon=>71.30, name=>"Astana, Kazakhstan" }, 
	         { lat=>-1.17, lon=>36.48, name=>"Nairobi, Kenya" }, 
	         { lat=>1.30, lon=>173.00, name=>"Tarawa, Kiribati" }, 
	         { lat=>29.30, lon=>48.00, name=>"Kuwait, Kuwait" }, 
	         { lat=>42.54, lon=>74.46, name=>"Bishkek, Kyrgyzstan" }, 
	         { lat=>17.58, lon=>102.36, name=>"Vientiane, Lao People's Democratic Republic" }, 
	         { lat=>56.53, lon=>24.08, name=>"Riga, Latvia" }, 
	         { lat=>33.53, lon=>35.31, name=>"Beirut, Lebanon" }, 
	         { lat=>-29.18, lon=>27.30, name=>"Maseru, Lesotho" }, 
	         { lat=>6.18, lon=>-10.47, name=>"Monrovia, Liberia" }, 
	         { lat=>32.49, lon=>13.07, name=>"Tripoli, Libyan Arab Jamahiriya" }, 
	         { lat=>47.08, lon=>9.31, name=>"Vaduz, Liechtenstein" }, 
	         { lat=>54.38, lon=>25.19, name=>"Vilnius, Lithuania" }, 
	         { lat=>49.37, lon=>6.09, name=>"Luxembourg, Luxembourg" }, 
	         { lat=>22.12, lon=>113.33, name=>"Macau, Macao, China" }, 
	         { lat=>-18.55, lon=>47.31, name=>"Antananarivo, Madagascar" }, 
	         { lat=>42.01, lon=>21.26, name=>"Skopje, Macedonia (Former Yugoslav Republic)" }, 
	         { lat=>-14.00, lon=>33.48, name=>"Lilongwe, Malawi" }, 
	         { lat=>3.09, lon=>101.41, name=>"Kuala Lumpur, Malaysia" }, 
	         { lat=>4.00, lon=>73.28, name=>"Male, Maldives" }, 
	         { lat=>12.34, lon=>-7.55, name=>"Bamako, Mali" }, 
	         { lat=>35.54, lon=>14.31, name=>"Valletta, Malta" }, 
	         { lat=>14.36, lon=>-61.02, name=>"Fort-de-France, Martinique" }, 
	         { lat=>-20.10, lon=>57.30, name=>"Nouakchott, Mauritania" }, 
	         { lat=>-12.48, lon=>45.14, name=>"Mamoudzou, Mayotte" }, 
	         { lat=>19.20, lon=>-99.10, name=>"Mexico, Mexico" }, 
	         { lat=>6.55, lon=>158.09, name=>"Palikir, Micronesia (Federated States of)" }, 
	         { lat=>47.02, lon=>28.50, name=>"Chisinau, Moldova, Republic of" }, 
	         { lat=>-25.58, lon=>32.32, name=>"Maputo, Mozambique" }, 
	         { lat=>16.45, lon=>96.20, name=>"Yangon, Myanmar" }, 
	         { lat=>-22.35, lon=>17.04, name=>"Windhoek, Namibia" }, 
	         { lat=>27.45, lon=>85.20, name=>"Kathmandu, Nepal" }, 
	         { lat=>52.23, lon=>4.54, name=>"Amsterdam / The Hague (seat of Government), Netherlands" }, 
	         { lat=>12.05, lon=>-69.00, name=>"Willemstad, Netherlands Antilles" }, 
	         { lat=>-22.17, lon=>166.30, name=>"Noumea, New Caledonia" }, 
	         { lat=>-41.19, lon=>174.46, name=>"Wellington, New Zealand" }, 
	         { lat=>12.06, lon=>-86.20, name=>"Managua, Nicaragua" }, 
	         { lat=>13.27, lon=>2.06, name=>"Niamey, Niger" }, 
	         { lat=>9.05, lon=>7.32, name=>"Abuja, Nigeria" }, 
	         { lat=>-45.20, lon=>168.43, name=>"Kingston, Norfolk Island" }, 
	         { lat=>39.09, lon=>125.30, name=>"Pyongyang, North Korea" }, 
	         { lat=>15.12, lon=>145.45, name=>"Saipan, Northern Mariana Islands" }, 
	         { lat=>59.55, lon=>10.45, name=>"Oslo, Norway" }, 
	         { lat=>78.666667, lon=>16.333333, name=>"Svalbard, Norway" }, 
	         { lat=>23.37, lon=>58.36, name=>"Masqat, Oman" }, 
	         { lat=>33.40, lon=>73.10, name=>"Islamabad, Pakistan" }, 
	         { lat=>7.20, lon=>134.28, name=>"Koror, Palau" }, 
	         { lat=>9.00, lon=>-79.25, name=>"Panama, Panama" }, 
	         { lat=>-9.24, lon=>147.08, name=>"Port Moresby, Papua New Guinea" }, 
	         { lat=>-25.10, lon=>-57.30, name=>"Asuncion, Paraguay" }, 
	         { lat=>-12.00, lon=>-77.00, name=>"Lima, Peru" }, 
	         { lat=>14.40, lon=>121.03, name=>"Manila, Philippines" }, 
	         { lat=>52.13, lon=>21.00, name=>"Warsaw, Poland" }, 
	         { lat=>38.42, lon=>-9.10, name=>"Lisbon, Portugal" }, 
	         { lat=>18.28, lon=>-66.07, name=>"San Juan, Puerto Rico" }, 
	         { lat=>25.15, lon=>51.35, name=>"Doha, Qatar" }, 
	         { lat=>37.31, lon=>126.58, name=>"Seoul, Republic of Korea" }, 
	         { lat=>44.27, lon=>26.10, name=>"Bucuresti, Romania" }, 
	         { lat=>55.45, lon=>37.35, name=>"Moskva, Russian Federation" }, 
	         { lat=>-1.59, lon=>30.04, name=>"Kigali, Rawanda" }, 
	         { lat=>17.17, lon=>-62.43, name=>"Basseterre, Saint Kitts and Nevis" }, 
	         { lat=>14.02, lon=>-60.58, name=>"Castries, Saint Lucia" }, 
	         { lat=>46.46, lon=>-56.12, name=>"Saint-Pierre, Saint Pierre and Miquelon" }, 
	         { lat=>13.10, lon=>-61.10, name=>"Kingstown, Saint Vincent and the Greeadines" }, 
	         { lat=>-13.50, lon=>-171.50, name=>"Apia, Samoa" }, 
	         { lat=>43.55, lon=>12.30, name=>"San Marino, San Marino" }, 
	         { lat=>0.10, lon=>6.39, name=>"Sao Tome, Sao Tome and Principe" }, 
	         { lat=>24.41, lon=>46.42, name=>"Riyadh, Saudi Arabia" }, 
	         { lat=>14.34, lon=>-17.29, name=>"Dakar, Senegal" }, 
	         { lat=>8.30, lon=>-13.17, name=>"Freetown, Sierra Leone" }, 
	         { lat=>48.10, lon=>17.07, name=>"Bratislava, Slovakia" }, 
	         { lat=>46.04, lon=>14.33, name=>"Ljubljana, Slovenia" }, 
	         { lat=>-9.27, lon=>159.57, name=>"Honiara, Solomon Islands" }, 
	         { lat=>2.02, lon=>45.25, name=>"Mogadishu, Somalia" }, 
	         { lat=>-25.44, lon=>28.12, name=>"Pretoria (administrative) / Cape Town (legislative) / Bloemfontein (judicial), South Africa" }, 
	         { lat=>40.25, lon=>-3.45, name=>"Madrid, Spain" }, 
	         { lat=>15.31, lon=>32.35, name=>"Khartoum, Sudan" }, 
	         { lat=>5.50, lon=>-55.10, name=>"Paramaribo, Suriname" }, 
	         { lat=>-26.18, lon=>31.06, name=>"Mbabane (administrative), Swaziland" }, 
	         { lat=>59.20, lon=>18.03, name=>"Stockholm, Sweden" }, 
	         { lat=>46.57, lon=>7.28, name=>"Bern, Switzerland" }, 
	         { lat=>33.30, lon=>36.18, name=>"Damascus, Syrian Arab Republic" }, 
	         { lat=>38.33, lon=>68.48, name=>"Dushanbe, Tajikistan" }, 
	         { lat=>13.45, lon=>100.35, name=>"Bangkok, Thailand" }, 
	         { lat=>6.09, lon=>1.20, name=>"Lome, Togo" }, 
	         { lat=>-21.10, lon=>-174.00, name=>"Nuku'alofa, Tonga" }, 
	         { lat=>36.50, lon=>10.11, name=>"Tunis, Tunisia" }, 
	         { lat=>39.57, lon=>32.54, name=>"Ankara, Turkey" }, 
	         { lat=>38.00, lon=>57.50, name=>"Ashgabat, Turkmenistan" }, 
	         { lat=>-8.31, lon=>179.13, name=>"Funafuti, Tuvalu" }, 
	         { lat=>0.20, lon=>32.30, name=>"Kampala, Uganda" }, 
	         { lat=>50.30, lon=>30.28, name=>"Kiev, Ukraine" }, 
	         { lat=>24.28, lon=>54.22, name=>"Abu Dhabi, United Arab Emirates" }, 
	         { lat=>51.36, lon=>-0.05, name=>"London, United Kingdom of Great Britain and Northern Ireland" }, 
	         { lat=>-6.08, lon=>35.45, name=>"Dodoma, United Republic of Tanzania" }, 
	         { lat=>39.91, lon=>-77.02, name=>"Washington DC, United States of America" }, 
	         { lat=>18.21, lon=>-64.56, name=>"Charlotte Amalie, United States Virgin Islands" }, 
	         { lat=>-34.50, lon=>-56.11, name=>"Montevideo, Uruguay" }, 
	         { lat=>41.20, lon=>69.10, name=>"Tashkent, Uzbekistan" }, 
	         { lat=>-17.45, lon=>168.18, name=>"Port-Vila, Vanuatu" }, 
	         { lat=>10.30, lon=>-66.55, name=>"Caracas, Venezuela" }, 
	         { lat=>21.05, lon=>105.55, name=>"Hanoi, Viet Nam" }, 
	         { lat=>44.50, lon=>20.37, name=>"Belgrade, Yugoslavia" }, 
	         { lat=>-15.28, lon=>28.16, name=>"Lusaka, Zambia" }, 
	         { lat=>-17.43, lon=>31.02, name=>"Harare, Zimbabwe" } 
	];
}
