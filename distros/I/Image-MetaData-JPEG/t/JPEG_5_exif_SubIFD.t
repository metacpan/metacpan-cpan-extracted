use Test::More tests => 52;
BEGIN { require 't/test_setup.pl'; }

my $tphoto = 't/test_photo.jpg';
my $tdata  = 't/test_photo.desc';
my ($image, $image2, $seg, $hash, $d1, $d2, $dt, $data, $ref);
my $uc = sub { my $s = "\376\377";
	       $s .= "\000$_" for split(/ */,$_[0]);
	       $s .= "\000\000"; };
my $val = sub { return JPEG_lookup('APP1@IFD0@SubIFD', $_[0]) };

my $SubIFD_data = {
    &$val('ExposureTime')             => [12, 55],
    &$val('ExposureProgram')          => [7],
    &$val('SpectralSensitivity')      =>  'a lot',
    &$val('ISOSpeedRatings')          => [1, 2, 3, 4],
    'ExifVersion'                     => '0220',
    'DateTimeOriginal'                => ['1996:07:12 14:36:55'],
    'CompressedBitsPerPixel'          => [79, 64],
    'MeteringMode'                    =>  6,
    &$val('LightSource')              =>  17,
    &$val('Flash')                    => [79],
    &$val('SubjectArea')              => [10, 20, 30],
    &$val('UserComment')              => ["Unicode\000asdfgh"],
    'SubSecTime'                      =>  "133     \000",
    'FlashpixVersion'                 => ['0100'],
    'ColorSpace'                      =>  65535,
    'PixelXDimension'                 => [222],
    &$val('RelatedSoundFile')         => ['ALB12_a5.DXf'],
    &$val('FocalPlaneResolutionUnit') =>  3,
    &$val('SubjectLocation')          => [13, 19],
    &$val('SensingMethod')            =>  '7',
    'FileSource'                      => [ "\003" ],
    'SceneType'                       =>  "\001",
    'CFAPattern'                      =>  "\000\003\000\003342623342",
    'ExposureMode'                    => [ 2 ],
    &$val('WhiteBalance')             => [1],
    &$val('GainControl')              => ['3'],
    &$val('DeviceSettingDescription') => "abcd".&$uc("ciao").&$uc("µ¿ÃÐëø"),
    &$val('ImageUniqueID')            => ['123789cd90ffa890' . "\000" x 17],
    '_OwnerName'                      =>  "Owner's Name: Stefano Bettelli\000",
    '_MoireFilter'                    =>  'Moire Filter: OFF',
};

#=======================================
diag "Testing APP1 Exif data routines (SUBIFD_DATA)";
#=======================================

BEGIN { use_ok ($::tabname, qw(:Lookups)) or exit; }
BEGIN { use_ok ($::pkgname) or exit; } # this must be loaded second!

#########################
$image = newimage($tphoto, '^APP1$');
$seg   = $image->retrieve_app1_Exif_segment(0);
isnt( $seg, undef, "The Exif segment is there, hi!" );

#########################
$hash = $seg->set_Exif_data($SubIFD_data, 'SubIFD_DATA', 'REPLACE');
ok( exists $$hash{'ERROR'}, $$hash{'ERROR'} );

#########################
$hash = $seg->set_Exif_data($SubIFD_data, 'SUBIFD_DATA', 'RUN');
ok( exists $$hash{'ERROR'}, $$hash{'ERROR'} );

#########################
$hash = $seg->set_Exif_data($SubIFD_data, 'SUBIFD_DATA', 'ADD');
is_deeply( $hash, {}, "all test SubIFD records ADDed" );

#########################
$hash = $seg->get_Exif_data('SUBIFD_DATA', 'TEXTUAL');
is_deeply( $$hash{'Flash'}, $$SubIFD_data{&$val('Flash')},"numeric keys work");

#########################
$hash = $seg->get_Exif_data('SUBIFD_DATA', 'TEXTUAL');
is_deeply( $$hash{'DateTimeOriginal'}, $$SubIFD_data{'DateTimeOriginal'},
	   "textual keys too" );

#########################
$hash = $seg->set_Exif_data($SubIFD_data, 'SUBIFD_DATA', 'REPLACE');
is_deeply( $hash, {}, "also REPLACing works" );

#########################
$hash = $seg->set_Exif_data({}, 'SUBIFD_DATA', 'REPLACE');
$hash = $seg->get_Exif_data('SUBIFD_DATA', 'TEXTUAL');
is_deeply( $$hash{'ExifVersion'}, ['0220'], "Automatic ExifVersion works" );

#########################
is_deeply( $$hash{'ComponentsConfiguration'}, ["\001\002\003\000"],
	   "Automatic ComponentsConfiguration works" );

#########################
is_deeply( $$hash{'FlashpixVersion'}, ['0100'],
	   "Automatic FlashpixVersion works" );

#########################
is_deeply( $$hash{'ColorSpace'}, [1], "Automatic ColorSpace works" );

#########################
# Remember that if you want to test with get_dimensions()
# you have to parse also the SOF segment.
is_deeply( [${$$hash{'PixelXDimension'}}[0],
	    ${$$hash{'PixelYDimension'}}[0]],
	   [0, 0], "Meaningful dimensions set to 0x0" );

#########################
$seg->set_Exif_data({'ExifVersion' => ['0210']}, 'SUBIFD_DATA', 'ADD');
$hash = $seg->get_Exif_data('SUBIFD_DATA', 'TEXTUAL');
is_deeply( $$hash{'ExifVersion'}, ['0210'], "Manual ExifVersion works" );

#########################
$hash = $image->set_Exif_data($SubIFD_data, 'SUBIFD_DATA', 'ADD');
is_deeply( $hash, {}, "adding through image object" );

#########################
$image->remove_app1_Exif_info(-1);
$hash = $image->set_Exif_data($SubIFD_data, 'SUBIFD_DATA', 'ADD');
is_deeply( $hash, {}, "adding without the SubIFD dir" );

#########################
$ref = \ (my $buffer = "");
$image->save($ref);
$image2 = newimage($ref, '^APP1$');
is_deeply( $image2->{segments}, $image->{segments}, "Write and reread works");

#########################
$d1 =  $image->get_description();
$d2 = $image2->get_description();
$d1 =~ s/(.*REFERENCE.*-->).*/$1/g; $d1 =~ s/Original.*//g;
$d2 =~ s/(.*REFERENCE.*-->).*/$1/g; $d2 =~ s/Original.*//g;
is( $d1, $d2, "Descriptions after write/read cycle are coincident" );

#########################
$hash = $image->set_Exif_data({'MakerNote'=>"\023b-_"}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('MakerNote')}, "The MakerNote cannot be changed" );

#########################
$hash = $image->set_Exif_data({'FNumber' => [3, -1]}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('FNumber')}, "Invalid rational rejected" );

#########################
$hash = $image->set_Exif_data({'ColorSpace' => 9}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('ColorSpace')}, "Out-of-bound short rejected");

#########################
$hash = $image->set_Exif_data({'ColorSpace' => 'xxx'}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('ColorSpace')}, "Invalid short (a string) rejected");

#########################
$hash = $image->set_Exif_data({'ExifVersion' => '9999'}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('ExifVersion')}, "Invalid Exif version rejected" );

#########################
$dt = '1994:23:23 12:14:61';
$hash = $image->set_Exif_data({'DateTimeOriginal'=>$dt}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('DateTimeOriginal')}, "Invalid date/time rejected" );

#########################
$dt = '1994:06:07 12:14:31';
$hash = $image->set_Exif_data({'DateTimeDigitized'=>$dt,
			       'DateTimeOriginal'=>$dt}, 'SUBIFD_DATA', 'ADD');
is( scalar keys %$hash, 0, "Dates in the 20th century accepted" );

#########################
$dt = '1823:06:07 12:14:31';
$hash = $image->set_Exif_data({'DateTimeDigitized'=>$dt,
			       'DateTimeOriginal'=>$dt}, 'SUBIFD_DATA', 'ADD');
is( scalar keys %$hash, 0, "Dates in the 19th century accepted" );

#########################
$dt = '1756:06:07 12:14:31';
$hash = $image->set_Exif_data({'DateTimeDigitized'=>$dt,
			       'DateTimeOriginal'=>$dt}, 'SUBIFD_DATA', 'ADD');
is( scalar keys %$hash, 2, "Dates in the 18th century rejected" );

#########################
$dt = '1994:23:23 12:14:61';
$hash = $image->set_Exif_data({'DateTimeOriginal'=>$dt}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('DateTimeOriginal')}, "Invalid date/time rejected" );

#########################
$dt = '    :  :     :  :  ';
$hash = $image->set_Exif_data({'DateTimeOriginal'=>$dt}, 'SUBIFD_DATA', 'ADD');
ok( ! exists $$hash{&$val('DateTimeOriginal')}, "Blank date/time accepted(1)");

#########################
$dt = ' ' x 19;
$hash = $image->set_Exif_data({'DateTimeOriginal'=>$dt}, 'SUBIFD_DATA', 'ADD');
ok( ! exists $$hash{&$val('DateTimeOriginal')}, "Blank date/time accepted(2)");

#########################
$hash = $image->set_Exif_data
    ({'ComponentsConfiguration' => "\004\006\005\000"}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('ComponentsConfiguration')}, "Invalid CCfg rejected" );

#########################
$hash = $image->set_Exif_data
    ({'ComponentsConfiguration' => '1230'}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('ComponentsConfiguration')}, "'Char' CCfg rejected" );

#########################
$hash = $image->set_Exif_data({'FileSource' => '3'}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('FileSource')}, "'Char' FileSource rejected" );

#########################
$hash = $image->set_Exif_data({'FileSource' => 3}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('FileSource')}, "Numeric FileSource rejected" );

#########################
$hash = $image->set_Exif_data({'SceneType' => '1'}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('SceneType')}, "'Char' SceneType rejected" );

#########################
$hash = $image->set_Exif_data({'SceneType' => 1}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('SceneType')}, "Numeric SceneType rejected" );

#########################
$hash = $image->set_Exif_data({'BrightnessValue'=>[-4]}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('BrightnessValue')}, "Invalid s-rational rejected" );

#########################
$hash = $image->set_Exif_data({'LightSource' => 16}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('LightSource')}, "Out-of-bound LightSource rejected" );

#########################
$hash = $image->set_Exif_data({'Flash' => 26}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('Flash')}, "Out-of-bound Flash rejected" );

#########################
$hash = $image->set_Exif_data({'SubjectArea' => 26}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('SubjectArea')}, "Invalid SubjectArea rejected" );

#########################
$hash = $image->set_Exif_data({'UserComment' => 'zzz'}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('UserComment')},"Plain string invalid as UserComment");

#########################
$hash = $image->set_Exif_data({'SubSecTime' => '130ms'}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('SubSecTime')}, "Letters not accepted in SubSecTime" );

#########################
$data = 'FILE.DAT';
$hash = $image->set_Exif_data({'RelatedSoundFile'=>$data},'SUBIFD_DATA','ADD');
ok( exists $$hash{&$val('RelatedSoundFile')},
    "Non-conforming RelatedSoundFile rejected" );

#########################
$hash = $image->set_Exif_data({'InteroperabilityOffset' => 'calculated'},
			      'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('InteroperabilityOffset')}, "Offsets are invalid" );

#########################
$data = "\000\003\000\003203046715"; # 7 is invalid
$hash = $image->set_Exif_data({'CFAPattern' => $data}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('CFAPattern')}, "Invalid CFAPattern rejected (1)" );

#########################
$data = "\000\003\000\00220304"; # wrong size
$hash = $image->set_Exif_data({'CFAPattern' => $data}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('CFAPattern')}, "Invalid CFAPattern rejected (2)" );

#########################
$data = 'xxxxdummy';
$hash = $image->set_Exif_data({'DeviceSettingDescription' => $data},
			      'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('DeviceSettingDescription')}, 
    "Non UCS-2 in DeviceSettingDescription rejected" );

#########################
$data = ('f' x 30) . '-' . ('a' x 3);
$hash = $image->set_Exif_data({'ImageUniqueID'=>$data}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('ImageUniqueID')}, "Invalid ImageUniqueID rejected" );

#########################
$hash = $image->set_Exif_data({'_Lens' => '1/16'}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{&$val('_Lens')}, "Invalid Photoshop tag rejected" );

#########################
$hash = $image->set_Exif_data({9999 => 2}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{9999}, "unknown numeric tags are rejected" );

#########################
$hash = $image->set_Exif_data({'Pippero' => 2}, 'SUBIFD_DATA', 'ADD');
ok( exists $$hash{'Pippero'}, "unknown textual tags are rejected" );

### Local Variables: ***
### mode:perl ***
### End: ***
