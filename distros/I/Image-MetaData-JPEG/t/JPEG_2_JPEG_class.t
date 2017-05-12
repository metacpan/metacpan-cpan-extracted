use Test::More tests => 62;
BEGIN { require 't/test_setup.pl'; }

my $tphoto = 't/test_photo.jpg';
my $tdata  = 't/test_photo.desc';
my $cphoto = 't/test_photo_copy.jpg';
my $ref    = '\[REFERENCE\].*-->.*$';
my $trim = sub { join '\n', map { s/^.*\"(.*)\".*$/$1/; $_ }
		 grep { /0:/ } split '\n', $_[0] };
my $fake = sub { my $s = newsegment('COM',\ "Fake $_[0] segment");
		 $s->{name} = $_[0]; return $s; };
my ($lines, $image, $image_2, $error, $handle, $buffer, $seg,
    $status, @desc, @desc_2, $h1, $h2, $num, $num2, @segs1, @segs2);

#=======================================
diag "Testing [Image::MetaData::JPEG]";
#=======================================

BEGIN { use_ok ($::pkgname) or exit; }
BEGIN { use_ok ($::segname) or exit; }

#########################
ok( -s $tphoto, "Test photo exists" );

#########################
$image = newimage("'Invalid'");
ok( ! $image, 'Fail OK: ' . &$trim($::pkgname->Error()) );

#########################
$image = newimage(undef);
ok( ! $image, 'Fail OK: ' . &$trim($::pkgname->Error()) );

#########################
$image = newimage(\ '');
ok( ! $image, 'Fail OK: ' . &$trim($::pkgname->Error()) );

#########################
$image = newimage($tphoto);
ok( $image, "Plain constructor" );

#########################
isa_ok( $image, $::pkgname );

#########################
open($handle, "<", $tphoto); binmode($handle); # for Windows
read($handle, $buffer, -s $tphoto); close($handle);
$image_2 = newimage(\ $buffer);
ok( $image_2, "Constructor with reference" );

#########################
is_deeply( $image->{segments}, $image_2->{segments}, "Objects coincide" );

#########################
$error = $::pkgname->Error();
is( $error, undef, "Ctor error unset (default)" );

#########################
$image = newimage($tphoto, "COM|SOF");
ok( $image, "Restricted constructor" );

#########################
$image = newimage($tphoto, "COM|SOF", "FASTREADONLY");
ok( $image, "Fast constructor" );

#########################
ok( -e $tdata, "Metadata file exists" );
open(ZZ, $tdata); $lines = my @a = <ZZ>; close(ZZ);

#########################
$image = newimage($tphoto);
@desc  = map { s/$ref//; $_ } split /\n/, $image->get_description();
is( @desc, $lines, "Description from file" );

#########################
open(ZZ, $tdata); @desc_2 = map { chomp; s/$ref//; $_ } <ZZ>; close(ZZ);
is_deeply( \@desc, \@desc_2, "Detailed description check");

#########################
open($handle, "<", $tphoto); binmode($handle); # for Windows
read($handle, $buffer, -s $tphoto); close($handle);
$image_2 = newimage(\ $buffer);
@desc_2 = map { s/$ref//; $_ } split /\n/, $image_2->get_description();
is( @desc_2, $lines, "Description from reference" );

#########################
$h1 = shift @desc; $h2 = shift @desc_2;
isnt( $h1, $h2, "Descriptions differing (header)" );

#########################
is_deeply( \@desc, \@desc_2, "The two descriptions are the same" );

#########################
$num = scalar grep { /^\s*\d+B <.*>\s*$/ } @desc;
"dddxx" =~ /dddxx/; # test stupid Perl behaviour with m//
is( scalar $image->get_segments(), $num, "Get all segments (undef string)" );

#########################
"dddxx" =~ /dddxx/; # test stupid Perl behaviour with m//
is( scalar $image->get_segments(""), $num, "Get all segments (empty string)" );

#########################
is( $image->get_segments("^S"), 3, "Segments beginning with S" );

#########################
is_deeply( [$image->get_segments("^S", "INDEXES")], [0, 7, 10],
	   "Segments through their indexes" );

#########################
is_deeply( [$image->get_dimensions()], [432, 288], "Image dimensions" );

#########################
is( $image->find_new_app_segment_position('APP1'), 4, "New APPx position" );

#########################
ok( $image->save($cphoto), "Exit status of save()" );
unlink $cphoto;

#########################
ok( eval { $image->save(\ ($buffer = "")); }, "Image saved to memory" );

#########################
$image_2 = newimage(\ $buffer);
isa_ok( $image_2, $::pkgname );

#########################
is_deeply( $image->{segments}, $image_2->{segments},
	   "From-disk and in-memory compare equal" );

#########################
$image = newimage($tphoto, 'COM');
ok( $image->save(\ ($buffer = "")), "Exit status of save() (2)" );

#########################
is_deeply( [$image->get_dimensions()], [0, 0],
	   "No dimensions without SOF segment" );

#########################
$image = newimage($tphoto, 'APP1$', "FASTREADONLY");
ok( ! $image->save(\ ($buffer = "")), "Do not save incomplete files" );

#########################
is( $image->get_segments(), 1, "Number of APP1 segments");

#########################
is( $image->find_new_app_segment_position('APP1'), 0,
    "find_new_app_segment_position not fooled by only 1 segment" );

#########################
$image = newimage($tphoto);
$num  = scalar $image->get_segments();
$num2 = scalar $image->get_segments('^(APP\d{1,2}|COM)$');
$image->drop_segments('METADATA');
is( scalar $image->get_segments(), $num - $num2, "All metadata erased" );

#########################
is( scalar $image->get_segments('^(APP\d{1,2}|COM)$'), 0,
    "... infact, they are no more there" );

#########################
eval { $image->drop_segments() };
isnt( $@, '', "drop_segments' regex cannot be undefined" );

#########################
eval { $image->drop_segments('') };
isnt( $@, '', "drop_segments' regex cannot be an empty string" );

#########################
$image = newimage($tphoto);
$num  = scalar $image->get_segments();
$num2 = scalar $image->get_segments('^COM$');
$image->drop_segments('COM');
is( scalar $image->get_segments(), $num - $num2, "All comments erased" );

#########################
$image = newimage($tphoto);
$num  = scalar $image->get_segments();
$num2 = scalar $image->get_segments('^APP\d{1,2}$');
$image->drop_segments('APP\d{1,2}');
is( scalar $image->get_segments(), $num - $num2, "All APP segments erased" );

#########################
@segs1 = $image->get_segments();
eval { $image->insert_segments() };
is( $@, '', "insert_segments without a segment does not fail" );

#########################
@segs2 = $image->get_segments();
is_deeply( \ @segs1, \ @segs2, "... but segments are not changed" );

#########################
$seg = newsegment('COM', \ 'dummy');
eval { $image->insert_segments($seg, 0) };
isnt( $@, '', "... pos=0 fails miserably" );

#########################
eval { $image->insert_segments($seg, scalar $image->get_segments()) };
isnt( $@, '', "... pos=last also" );

#########################
@segs2 = $image->get_segments();
is_deeply( \ @segs1, \ @segs2, "... segments still unchanged" );

#########################
$image->insert_segments($seg, 3);
@segs1 = $image->get_segments();
splice @segs2, 3, 0, $seg;
is_deeply( \ @segs1, \ @segs2, "inserting a segment with pos=3" );

#########################
splice @segs2, $image->find_new_app_segment_position('COM'), 0, $seg;
$image->insert_segments($seg);
@segs1 = $image->get_segments();
is_deeply( \ @segs1, \ @segs2, "... now with automatic positioning" );

#########################
$image->insert_segments([$seg, $seg], 9);
@segs1 = $image->get_segments();
splice @segs2, 9, 0, $seg, $seg;
is_deeply( \ @segs1, \ @segs2, "inserting more than one segment" );

#########################
$image->insert_segments([$seg, $seg], 1, 3);
@segs1 = $image->get_segments();
splice @segs2, 1, 3, $seg, $seg;
is_deeply( \ @segs1, \ @segs2, "overwriting instead of inserting" );

#########################
@{$image->{segments}} = $image->get_segments('^(SOI|EOI)$');
is_deeply( [map { $_->{name} } $image->get_segments()], 
	   ['SOI', 'EOI'], "only SOI and EOI left" );

#########################
$image->insert_segments(&$fake('COM')); # SOI, COM, EOI
is_deeply( $image->{segments}[1], &$fake('COM'), "insert with only SOI/EOI" );

#########################
$image->{segments}[1] = &$fake('SOF_0'); # SOI, SOF_0, EOI
is_deeply( $image->{segments}[1], &$fake('SOF_0'), "insertion of a fake SOF" );

#########################
$image->insert_segments(&$fake('COM')); # SOI, COM, SOF_0, EOI
is_deeply( $image->{segments}[1], &$fake('COM'), "insert in [SOI, SOF]" );

#########################
$image->{segments}[1] = &$fake('APP2'); # SOI, APP2, SOF_0, EOI
$image->insert_segments(&$fake('COM')); # SOI, APP2, COM, SOF_0, EOI
is_deeply( $image->{segments}[2], &$fake('COM'), "insert COM after APPx" );

#########################
$image->insert_segments(&$fake('APP0')); # SOI, APP0, APP2, COM, SOF_0, EOI
is_deeply( $image->{segments}[1], &$fake('APP0'), "insert APP0 before APP2" );

#########################
$image->insert_segments(&$fake('APP9')); # SOI,APP0,APP2,APP9,COM,SOF_0,EOI
is_deeply( $image->{segments}[3], &$fake('APP9'), "insert APP9 after APP2" );

#########################
$image->insert_segments(&$fake('APP0')); # SOI,APP0,APP0,APP2,APP9,COM,SOF0,EOI
is_deeply( $image->{segments}[2], &$fake('APP0'), "insert APP0 after APP0" );

#########################
$image->{segments}[1] = &$fake('APP1'); # SOI,APP1,APP0,APP2,APP9,COM,SOF0,EOI
$image->insert_segments(&$fake('APP1')); #SOI,2APP1,APP0,APP2,APP9,COM,SOF0,EOI
is_deeply( $image->{segments}[2], &$fake('APP1'),
	   "insert APP1 after APP1 with before APP0" );

#########################
$image->drop_segments('COM');
$image->{segments}[2] = &$fake('COM'); # SOI,APP1,COM,APP0,APP2,APP9...
$image->insert_segments(&$fake('COM')); # SOI,APP1,COM,COM,APP0,APP2,APP9...
is_deeply( $image->{segments}[3], &$fake('COM'),
	   "insert COM after COM among APPx" );

#########################
$image->drop_segments('COM');
$image->insert_segments(&$fake('COM')); # SOI,APP1,APP0,APP2,APP9,COM...
is_deeply( $image->{segments}[5], &$fake('COM'),
	   "insert COM after all APPx" );

#########################
$image->insert_segments(&$fake('APP7')); # SOI,APP1,APP0,APP2,APP7,APP9,COM...
is_deeply( $image->{segments}[4], &$fake('APP7'), "insert APP7 among APPx" );

#########################
$image->{segments}[1] = &$fake('COM'); # SOI,COM,APP0,APP2,APP7,APP9,COM...
$image->provide_app1_Exif_segment();
$num = ($image->get_segments('^APP1$', 'INDEXES'))[0];
is( $num, 3, "provide_app1_Exif_segment finds its way ..." );

### Local Variables: ***
### mode:perl ***
### End: ***
