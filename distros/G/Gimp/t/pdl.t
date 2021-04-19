use strict;
use Test::More;
our ($dir, $DEBUG);
my $pdl_operations;
BEGIN {
#  $Gimp::verbose = 1;
  $DEBUG = 0;
  require './t/gimpsetup.pl';
  $pdl_operations = <<'EOF';
use PDL;

sub setpixel {
  my ($i, $l, $x, $y, $colour) = @_;
  my $region = $l->get->pixel_rgn($x, $y, 1, 1, 1, 0);
  my $piddle = pdl [ @{$colour}[0..2] ]; # canonicalise_colour adds alpha!
  $piddle *= 255; # so it's bytes, not floats
  $region->set_pixel($piddle, $x, $y);
#  $l->merge_shadow(1);
  $l->update($l->bounds);
}

sub getpixel {
  my ($i, $l, $x, $y) = @_;
  my $region = $l->get->pixel_rgn($l->bounds,0,0);
  my $piddle = $region->get_pixel($x,$y);
  return unpdl $piddle;
}

sub iterate {
  my ($i, $l, $inc) = @_;
  my @bounds = $l->bounds;
  {
    # in block so $src/$dst go out of scope before merge
    my $src = Gimp::PixelRgn->new($l,@bounds,0,0);
    my $dst = Gimp::PixelRgn->new($l,@bounds,1,1);
    my $iter = Gimp->pixel_rgns_register($dst);
    do {
      my $pdl = $src->get_rect($dst->x,$dst->y,$dst->w,$dst->h);
      $pdl += $inc;
      $dst->data($pdl);
    } while (Gimp->pixel_rgns_process($iter));
  }
  $l->merge_shadow(1);
  $l->update(@bounds);
}
EOF

  use Config;
  write_plugin($DEBUG, "test_pdl_filter", $Config{startperl}.
    " -w\nBEGIN { \$Gimp::verbose = ".int($Gimp::verbose||0).'; }'.
    <<'EOF'.$pdl_operations);

use strict;
use Gimp;
use Gimp::Fu;

sub boilerplate_params {
  my ($testing, $menuloc) = @_;
  (
    ("exercise gimp-perl filter testing $testing") x 2,
    ("boilerplate id") x 2,
    "20140310",
    N_$menuloc,
    "*",
  );
}

&register(
  "test_pdl_getpixel",
  boilerplate_params('filter', '<Image>/Filters'),
  [
    [PF_INT16, "x", "X coord of pixel", 0],
    [PF_INT16, "y", "Y coord of pixel", 0],
  ],
  [
    [PF_COLOR, "color", "Colour of pixel", ],
  ],
  \&getpixel,
);

&register(
  "test_pdl_setpixel",
  boilerplate_params('filter', '<Image>/Filters'),
  [
    [PF_INT16, "x", "X coord of pixel", 0],
    [PF_INT16, "y", "Y coord of pixel", 0],
    [PF_COLOR, "color", "Colour to set pixel", [128, 128, 128], ],
  ],
  [],
  \&setpixel,
);

&register(
  "test_pdl_iterate",
  boilerplate_params('filter', '<Image>/Filters'),
  [
    [PF_INT16, "inc", "Amount to increment each byte", 1],
  ],
  [],
  \&iterate,
);

exit main;
EOF
}
use Gimp qw(:DEFAULT net_init=spawn/);

ok((my $i = Gimp::Image->new(10,10,RGB)), 'new image');
ok(
  (my $l = $i->layer_new(10,10,RGB_IMAGE,"new layer",100,LAYER_MODE_HSV_VALUE_LEGACY)),
  'make layer',
);
ok(!$i->insert_layer($l,0,0), 'insert layer');

my $fgcolour = [ 255, 128, 0 ];
my @setcoords = (1, 1);
my $setcolour = [ 16, 16, 16 ];
Gimp::Context->push;
Gimp::Context->set_foreground($fgcolour);

$l->fill(FILL_FOREGROUND);
ok(
  cmp_colour(
    [ @{$l->test_pdl_getpixel(@setcoords)}[0..2] ],
    Gimp::canonicalize_color($fgcolour),
  ),
  'getpixel initial colour'
);
$l->test_pdl_setpixel(@setcoords, $setcolour);
ok(
  cmp_colour(
    [ @{$l->test_pdl_getpixel(@setcoords)}[0..2] ],
    Gimp::canonicalize_color($setcolour),
  ),
  'getpixel colour after setpixel'
);
ok(
  cmp_colour(
    [ @{$l->test_pdl_getpixel(map { $_+1 } @setcoords)}[0..2] ],
    Gimp::canonicalize_color($fgcolour),
  ),
  'getpixel other pixel after setpixel'
);
$l->test_pdl_iterate(3);
ok(
  cmp_colour(
    [ @{$l->test_pdl_getpixel(@setcoords)}[0..2] ],
    Gimp::canonicalize_color([ map { $_+3 } @$setcolour ]),
  ),
  'getpixel colour after iterate'
);

eval $pdl_operations;
$l->fill(FILL_FOREGROUND);
ok(
  cmp_colour(
    Gimp::canonicalize_color(getpixel($i, $l, @setcoords)),
    Gimp::canonicalize_color($fgcolour),
  ),
  'net getpixel initial colour'
);
setpixel($i, $l, @setcoords, Gimp::canonicalize_color($setcolour));
ok(
  cmp_colour(
    Gimp::canonicalize_color(getpixel($i, $l, @setcoords)),
    Gimp::canonicalize_color($setcolour),
  ),
  'net getpixel colour after setpixel'
);
ok(
  cmp_colour(
    Gimp::canonicalize_color(getpixel($i, $l, map { $_+1 } @setcoords)),
    Gimp::canonicalize_color($fgcolour),
  ),
  'net getpixel other pixel after setpixel'
);
iterate($i, $l, 3);
ok(
  cmp_colour(
    Gimp::canonicalize_color(getpixel($i, $l, @setcoords)),
    Gimp::canonicalize_color([ map { $_+3 } @$setcolour ]),
  ),
  'net getpixel colour after iterate'
);

Gimp::Context->pop;

Gimp::Net::server_quit;
Gimp::Net::server_wait;

done_testing;
