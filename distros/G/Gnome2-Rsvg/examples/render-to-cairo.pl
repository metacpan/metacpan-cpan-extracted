use File::Basename qw(basename);
use Gnome2::Rsvg;

my $svg = $ARGV[0];

my $handle = Gnome2::Rsvg::Handle -> new();
open(SVG, $svg) or die("Opening '$svg': $!");
while (<SVG>) {
  $handle -> write($_) or die("Could not parse '$svg'");
}
close(SVG);
$handle -> close() or die("Could not parse '$svg'");

my $dim = $handle -> get_dimensions();
my $surface = Cairo::ImageSurface -> create("argb32",
                                            $dim->{width},
                                            $dim->{height});
my $cr = Cairo::Context -> create($surface);
$handle -> render_cairo($cr);
$surface -> write_to_png(basename($svg) . '.png');
