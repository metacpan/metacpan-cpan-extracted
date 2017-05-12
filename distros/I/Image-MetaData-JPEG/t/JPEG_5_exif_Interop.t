use Test::More tests => 30;
BEGIN { require 't/test_setup.pl'; }

my $tphoto = 't/test_photo.jpg';
my $tdata  = 't/test_photo.desc';
my ($image, $image2, $seg, $hash, $hash2, $d1, $d2, $x_dim, $y_dim, $ref);

my $data2 = {
    0x1000                  => "Exif JPEG Ver. 2.1\000",
    0x1001                  => 234,
    'RelatedImageLength'    => 128 };

my $Interop_data = {
    'InteroperabilityIndex' => "R98",
    0x0002                  => "0123", };

@$Interop_data{keys %$data2} = values %$data2;

#=======================================
diag "Testing APP1 Exif data routines (INTEROP_DATA)";
#=======================================

BEGIN { use_ok ($::pkgname) or exit; }

#########################
$image = newimage($tphoto, '^(APP1|SOS)$');
$seg   = $image->retrieve_app1_Exif_segment(0);
isnt( $seg, undef, "The Exif segment is there, hi!" );

#########################
$hash = $seg->set_Exif_data($Interop_data, 'INTEROP_DETA', 'REPLACE');
ok( exists $$hash{'ERROR'}, $$hash{'ERROR'} );

#########################
$hash = $seg->set_Exif_data($Interop_data, 'INTEROP_DATA', 'UPDATE');
ok( exists $$hash{'ERROR'}, $$hash{'ERROR'} );

#########################
$hash = $seg->set_Exif_data($Interop_data, 'INTEROP_DATA', 'ADD');
is_deeply( $hash, {}, "all test Interop records ADDed" );

#########################
$hash = $seg->get_Exif_data('INTEROP_DATA', 'TEXTUAL');
is_deeply( $$hash{'RelatedImageWidth'}, [ $$Interop_data{0x1001} ],
	   "numeric keys work" );

#########################
$hash = $seg->get_Exif_data('INTEROP_DATA', 'TEXTUAL');
is_deeply( $$hash{'RelatedImageLength'},[$$Interop_data{'RelatedImageLength'}],
	   "textual keys too" );

#########################
$hash = $seg->set_Exif_data($Interop_data, 'INTEROP_DATA', 'REPLACE');
is_deeply( $hash, {}, "also REPLACing works" );

#########################
$hash = $seg->set_Exif_data($data2, 'INTEROP_DATA', 'REPLACE');
is_deeply( $hash, {}, "Replacing without mandatory tags works" );

#########################
$hash = $seg->get_Exif_data('INTEROP_DATA', 'TEXTUAL');
is_deeply( $$hash{'InteroperabilityIndex'}, ["R98\000"],
	   "Automatic Index works" );

#########################
is_deeply( $$hash{'InteroperabilityVersion'}, ["0100"],
	   "Automatic Version works" );

#########################
$hash = $seg->set_Exif_data
    ({'InteroperabilityIndex' => "ABC"}, 'INTEROP_DATA', 'ADD');
ok( exists $$hash{0x1}, "A wrong index cannot be set" );

#########################
$hash = $image->set_Exif_data($Interop_data, 'INTEROP_DATA', 'ADD');
is_deeply( $hash, {}, "adding through image object" );

#########################
$image->remove_app1_Exif_info(-1);
$hash = $image->set_Exif_data($data2, 'INTEROP_DATA', 'ADD');
is_deeply( $hash, {}, "adding without the Interop. dir" );

#########################
$ref = \ (my $buffer = "");
$image->save($ref);
$image2 = newimage($ref, '^(APP1|SOS)$');
is_deeply( $image2->{segments}, $image->{segments}, "Write and reread works");

#########################
$d1 =  $image->get_description();
$d2 = $image2->get_description();
$d1 =~ s/(.*REFERENCE.*-->).*/$1/g; $d1 =~ s/Original.*//g;
$d2 =~ s/(.*REFERENCE.*-->).*/$1/g; $d2 =~ s/Original.*//g;
is( $d1, $d2, "Descriptions after write/read cycle are coincident" );

#########################
$image = newimage($tphoto, '^(APP1|SOS)$');
$hash = $image->set_Exif_data({0x1 =>"R97"}, 'INTEROP_DATA', 'ADD');
ok( exists $$hash{1}, "Malformed Index rejected" );

#########################
$hash = $image->set_Exif_data({0x2 => 13}, 'INTEROP_DATA', 'ADD');
ok( exists $$hash{2}, "Malformed Version rejected" );

#########################
$hash = $image->set_Exif_data({0x1001 => "pippo"}, 'INTEROP_DATA', 'ADD');
ok( exists $$hash{0x1001}, "Malformed X dimension rejected" );

#########################
$hash = $image->set_Exif_data({0x1002 => "pluto"}, 'INTEROP_DATA', 'ADD');
ok( exists $$hash{0x1002}, "Malformed Y dimension rejected" );

#########################
$hash = $image->set_Exif_data({0x1002 => -13}, 'INTEROP_DATA', 'ADD');
ok( exists $$hash{0x1002}, "A negative dimension is invalid" );

#########################
$hash = $image->set_Exif_data({9999 => 2}, 'INTEROP_DATA', 'ADD');
ok( exists $$hash{9999}, "unknown numeric tags are rejected" );

#########################
$hash = $image->set_Exif_data({'Pippero' => 2}, 'INTEROP_DATA', 'ADD');
ok( exists $$hash{'Pippero'}, "unknown textual tags are rejected" );

#########################
$hash = $image->forge_interoperability_IFD();
is_deeply( $hash, {}, "Forge Interop. IFD is not rejected" );

#########################
$hash = $image->get_Exif_data('INTEROP_DATA', 'NUMERIC');
is_deeply( $$hash{1}, ["R98\000"], "... automatic Index ok" );

#########################
is_deeply( $$hash{2}, ["0100"], "... automatic Version ok" );

#########################
is_deeply( $$hash{0x1000}, ["Exif JPEG Ver. 2.2\000"],
	   "... automatic FileFormat ok" );

#########################
($x_dim, $y_dim) = $image->get_dimensions();
is_deeply( [$$hash{0x1001}, $$hash{0x1002}], [ [$x_dim], [$y_dim] ],
	   "... automatic dimensions ok" );

#########################
$image->remove_app1_Exif_info(-1);
$image->forge_interoperability_IFD();
$hash2 = $image->get_Exif_data('INTEROP_DATA', 'NUMERIC');
is_deeply( $hash2, $hash, "same result after deleting Exif data and forging");

#########################
$image->save($ref);
$image2 = newimage($ref, '^(APP1|SOS)$');
is_deeply( $image2->{segments}, $image->{segments}, "Write and reread works");

### Local Variables: ***
### mode:perl ***
### End: ***
