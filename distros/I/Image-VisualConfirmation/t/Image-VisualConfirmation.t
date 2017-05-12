use Test::More tests => 13;
use Test::Exception;

BEGIN { use_ok('Image::VisualConfirmation') };

# ### Object instantiation ###
throws_ok { Image::VisualConfirmation->new('no_an_hashref') }
    qr/must be an hashref/;

my $vc = Image::VisualConfirmation->new();

isa_ok($vc, 'Image::VisualConfirmation');

# ### Code retrieval ###
ok($vc->code =~ m/\A \w+ \z/xms, 'Code retrieval');

# ### Image retrieval ###
throws_ok { $vc->image_data(an_hash => 'no_an_hashref') }
    qr/must be an hashref/;
    
lives_ok { $vc->image_data({ type => 'png' }) };
lives_ok { $vc->image_data() };
lives_ok { $vc->image_data({ type => 'tga', compress => 1 }) };

throws_ok { $vc->image_data({ type => 'notype' }) }
    qr/format\s+(?:\'notype\'\s+) ?not\s+supported/xms;

my $vc_image = $vc->image;
isa_ok($vc_image, 'Imager');


# ### New image creation ###
throws_ok { $vc->create_new_image(an_hash => 'no_an_hashref') }
    qr/must be an hashref/;

$vc->create_new_image({ code => 'marcus' });
ok($vc->code eq 'marcus', 'Code provided by user');

$vc->create_new_image({ code => sub { return 'julius' } });
ok($vc->code eq 'julius', 'Code provided by user');
