use Map::Tube::Athens;

use MIME::Base64 qw/decode_base64/;

my $tube = Map::Tube::Athens->new;

my $name = $tube->name;
open(my $MAP_IMAGE, ">$name.png");
binmode($MAP_IMAGE);
print $MAP_IMAGE decode_base64($tube->as_image);
close($MAP_IMAGE);

my $line = $tube->get_line_by_name('M1');
print $tube->to_string($line),   "\n\n";


my $route = $tube->get_shortest_route('Piraeus', 'Airport');
print $tube->to_string($route) . "\n";


