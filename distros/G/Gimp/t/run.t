use strict;
use Test::More;

our ($dir, $DEBUG);
BEGIN {
#  $Gimp::verbose = 1;
  $DEBUG = 0;
  require './t/gimpsetup.pl';
}
use Gimp qw(:DEFAULT net_init=spawn/);

ok((my $i = new Gimp::Image(10,10,RGB)), 'OO Syntax for new image');
ok(
  (my $l = $i->layer_new(10,10,RGBA_IMAGE,"new layer",100,LAYER_MODE_HSV_VALUE_LEGACY)),
  'Different OO syntax for creating a layer',
);
ok(!Gimp->image_insert_layer($l,0,0), 'Yet another OO syntax');
is($l->get_name, "new layer", 'layer name');
ok(
  !$l->paintbrush(50,[1,1,2,2,5,3,7,4,2,8],PAINT_CONSTANT,0),
  'some painting with variable length arrays, default value',
);
ok(
  !$l->paintbrush(30,4,[5,5,8,1],PAINT_CONSTANT,0),
  'paint without default value',
);
ok(
  !Gimp::Plugin->sharpen(RUN_NONINTERACTIVE,$i,$l,10),
  'call plugin through Gimp::Plugin->, use explicit RUN_NONINTERACTIVE',
);
ok(!$l->sharpen(10), 'call with maximum fu magic');
ok(!Gimp->plug_in_sharpen($i,$l,10), 'call plugin using default');

# exercise COLORARRAY - read only as can't find proc that takes as input
my @palettes = Gimp->palettes_get_list("Default");
my @colors = Gimp::Palette->get_colors($palettes[0]);
#require Data::Dumper;warn Data::Dumper::Dumper(scalar @colors), "\n";
cmp_ok(scalar(@colors), '==', 23, 'colorarray correct size');
cmp_ok(scalar(@{ $colors[0] }), '==', 4, 'colorarray 1st el is correct size');

# exercise VECTORS
my $tl = $i->text_layer_new("hi", "Arial", 8, 3);
$i->insert_layer($tl, 0, 0);
my $vectors = $tl->vectors_new_from_text_layer;
cmp_ok(ref($vectors), 'eq', 'Gimp::Vectors', 'vectors object returned');
my $vectorstring = $vectors->export_to_string; # takes VECTORS as input - QED
like($vectorstring, qr/<path id="hi"/, 'vector string plausible');

my $i2 = $i->duplicate;
eval { $i2->become('Gimp::Channel') };
ok($@, 'image become channel exception');
isa_ok($i2, 'Gimp::Image', 'still image');
eval { $i2->become('Gimp::Image') };
is($@, '', 'image become image succeeds');

my $l2 = $i->get_active_layer;
eval { $l2->become('Gimp::Layer') };
is($@, '', 'layer become layer succeeds');
eval { $l2->become('Gimp::Channel') };
ok($@, 'layer become channel exception');

$i2->delete;
ok(!$i->delete, 'remove image');

Gimp::Net::server_quit;
Gimp::Net::server_wait;

done_testing;
