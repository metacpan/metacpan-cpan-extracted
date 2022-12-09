use Math::Grid::Coordinates;
use Mojo::Util qw/dumper/;

$\ = "\n"; $, = "\t"; binmode(STDOUT, ":utf8");

my $g = Math::Grid::Coordinates->new({ grid_width => 8, grid_height => 8, page_width => 500, page_height => 700, gutter => 7 });
$g->calculate;


my @pos = $g->positions;

#print sprintf "<path d=\"L %f %f %f %f\" />", map {@$_} @$_ for $g->guides;
print sprintf '<line x1="%f" y1="%f" x2="%f" y2="%f" style="stroke:#898989;stroke-width:0.26458334" />', map {@$_} @$_ for $g->guides;

