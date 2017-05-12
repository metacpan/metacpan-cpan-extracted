use warnings;
use strict;

use utf8;

use Test::Simple tests => 6;

use Geo::Coordinates::Converter::LV03;

# -------------------------------

my $φ_la_chaux_des_breuleux = 47 + 13/60 + 15/3600;
my $λ_la_chaux_des_breuleux =  7 +  1/60 + 41/3600;

my ($x_la_chaux_des_breuleux, $y_la_chaux_des_breuleux) = Geo::Coordinates::Converter::LV03::lat_lng_2_y_x($φ_la_chaux_des_breuleux, $λ_la_chaux_des_breuleux);

ok(sprintf("%0.2f", $x_la_chaux_des_breuleux) eq '568901.92', 'lat_lng_2_y_x (lat of La Chaux des Breuleux)');
ok(sprintf("%0.2f", $y_la_chaux_des_breuleux) eq '230071.03', 'lat_lng_2_y_x (lng of La Chaux des Breuleux)');

# -------------------------------
 
my $φ_beispiel = 46 +  2/60 + 38.87/3600;
my $λ_beispiel =  8 + 43/60 + 49.79/3600;
 
my ($x_beispiel, $y_beispiel) = Geo::Coordinates::Converter::LV03::lat_lng_2_y_x($φ_beispiel, $λ_beispiel);

ok(sprintf("%0.2f", $x_beispiel) eq '699999.76', 'lat_lng_2_y_x (lat of Beispiel)');
ok(sprintf("%0.2f", $y_beispiel) eq  '99999.97', 'lat_lng_2_y_x (lng of Beispiel)');

# -------------------------------
 
my ($φ_beispiel_, $λ_beispiel_) = Geo::Coordinates::Converter::LV03::y_x_2_lat_lng($x_beispiel, $y_beispiel);

ok(sprintf("%0.8f", $φ_beispiel_ - $φ_beispiel) eq '-0.00000398', 'Phi diff');
ok(sprintf("%0.8f", $λ_beispiel_ - $λ_beispiel) eq '-0.00000095', 'Lamda diff');
