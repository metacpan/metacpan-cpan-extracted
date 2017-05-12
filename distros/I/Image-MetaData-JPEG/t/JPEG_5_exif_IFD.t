use Test::More tests => 61;
BEGIN { require 't/test_setup.pl'; }

my $tphoto = 't/test_photo.jpg';
my $tdata  = 't/test_photo.desc';
my ($image, $image2, $seg, $hash, $hash2, $d1, $d2, $dt, $ref, $ref2);
my $val = sub { return JPEG_lookup('APP1@IFD0', $_[0]) }; # IFD0/1 indifferent

my $IFD_data = {
    &$val('Make')                  => 'Cooperativa Elettronica Reggiana',
    &$val('Artist')                => 'Stefano Bettelli',
    &$val('ImageDescription')      => 'spiaggia di Marina Romea',
    'Model'                        => 'Kodak DX3900',
    'Orientation'                  => [4],
    'TransferFunction'             => [(1..768)],
    &$val('XResolution')           => [31000, 65536],
    &$val('YResolution')           => [72, 1],
    &$val('ResolutionUnit')        =>  3,
    'Software'                     => 'Image::MetaData::JPEG software',
    'DateTime'                     => ['1996:07:12 14:36:55'],
    'WhitePoint'                   => [12, 16, 8, 16],
    &$val('ReferenceBlackWhite')   => [7, 32, 5, 64, 18, 13, 0,0,0,0,0,0],
    &$val('PrimaryChromaticities') => [(10..21)],
    &$val('Copyright')             => 'GPL',
    &$val('PlanarConfiguration')   =>  2,
    'PhotometricInterpretation'    => [6],
    'YCbCrPositioning'             =>  2,
    'YCbCrCoefficients'            => [1, 14, 34, 45, 65, 12],
    'YCbCrSubSampling'             => [2, 2],
};

my $calculated = {
    'ImageWidth'                   => 640,
    'ImageLength'                  => 480,
    'BitsPerSample'                => [8, 8, 8],
    'Compression'                  => 6,
    'StripOffsets'                 => [(1..10)],
    'SamplesPerPixel'              => 3,
    'RowsPerStrip'                 => 5,
    'StripByteCounts'              => [(5..50)],
    'JPEGInterchangeFormat'        => 600,
    'JPEGInterchangeFormatLength'  => 3420,
    'ExifOffset'                   => 848,
    'GPSInfo'                      => 1264,
};

#=======================================
diag "Testing APP1 Exif data routines (IFD01_DATA)";
#=======================================

BEGIN { use_ok ($::tabname, qw(:Lookups)) or exit; }
BEGIN { use_ok ($::pkgname) or exit; } # this must be loaded second!

#########################
$image = newimage($tphoto, '^APP1$');
$seg   = $image->retrieve_app1_Exif_segment(0);
isnt( $seg, undef, "The Exif segment is there, hi!" );

#########################
$hash = $seg->set_Exif_data($IFD_data, 'IFD0_DATA', 'ADD');
is_deeply( $hash, {}, "all test IFD0 records ADDed" );

#########################
$hash = $seg->set_Exif_data($IFD_data, 'IFD1_DATA', 'ADD');
is_deeply( $hash, {}, "... added also to IFD1" );

#########################
$ref = $seg->search_record_value('IFD0');
isnt( $ref, undef, "... the IFD0 is still present" );

#########################
$ref2 = $seg->search_record_value('GPS', $ref);
isnt( $ref2, undef, "... also the IFD0\@GPS directory" );

#########################
$ref = $seg->search_record_value('SubIFD', $ref);
isnt( $ref, undef, "... also the IFD0\@SubIFD directory" );

#########################
$ref = $seg->search_record_value('Interop', $ref);
isnt( $ref, undef, "... also the IFD0\@SubIFD\@Interop dir." );

#########################
$hash = $seg->set_Exif_data($calculated, 'IFD0_DATA', 'ADD');
is( scalar keys %$hash, scalar keys %$calculated,
    "all forbidden records are rejected in IFD0" );

#########################
$hash = $seg->set_Exif_data($calculated, 'IFD1_DATA', 'ADD');
is( scalar keys %$hash, scalar keys %$calculated,
    "... rejected also in IFD1" );

#########################
$hash = $seg->set_Exif_data($IFD_data, 'IFD0_DATA', 'REPLACE');
is_deeply( $hash, {}, "REPLACing in IFD0 works" );

#########################
$hash = $seg->set_Exif_data($IFD_data, 'IFD1_DATA', 'REPLACE');
is_deeply( $hash, {}, "... also in IFD1 works" );

#########################
$ref = $seg->search_record_value('IFD0');
isnt( $ref, undef, "... the IFD0 is still present" );

#########################
$ref2 = $seg->search_record_value('GPS', $ref);
isnt( $ref2, undef, "... also the IFD0\@GPS directory" );

#########################
$ref = $seg->search_record_value('SubIFD', $ref);
isnt( $ref, undef, "... also the IFD0\@SubIFD directory" );

#########################
$ref = $seg->search_record_value('Interop', $ref);
isnt( $ref, undef, "... also the IFD0\@SubIFD\@Interop dir." );

#########################
$hash = $seg->set_Exif_data($calculated, 'IFD0_DATA', 'REPLACE');
is( scalar keys %$hash, scalar keys %$calculated,
    "all forbidden records rejected when replacing in IFD0" );

#########################
$hash = $seg->set_Exif_data($calculated, 'IFD1_DATA', 'REPLACE');
is( scalar keys %$hash, scalar keys %$calculated,
    "... rejected also in IFD1" );

#########################
$seg->set_Exif_data({}, 'IFD0_DATA', 'REPLACE');
$hash = $seg->get_Exif_data('IFD0_DATA', 'TEXTUAL');
is_deeply( $$hash{'XResolution'}, [72,1], "Automatic IFD0 XResolution works" );

#########################
is_deeply( $$hash{'YResolution'}, [72,1], "... also YResolution" );

#########################
is_deeply( $$hash{'ResolutionUnit'}, [2], "... also ResolutionUnit" );

#########################
is_deeply( $$hash{'YCbCrPositioning'}, [1], "... also YCbCrPositioning" );

#########################
$seg->set_Exif_data({}, 'IFD1_DATA', 'REPLACE');
$hash = $seg->get_Exif_data('IFD1_DATA', 'TEXTUAL');
is_deeply( $$hash{'XResolution'}, [72,1], "Automatic IFD1 XResolution works" );

#########################
is_deeply( $$hash{'YResolution'}, [72,1], "... also YResolution" );

#########################
is_deeply( $$hash{'ResolutionUnit'}, [2], "... also ResolutionUnit" );

#########################
is_deeply( $$hash{'YCbCrSubSampling'}, [2,1], "... also YCbCrSubSampling" );

#########################
is_deeply( $$hash{'PlanarConfiguration'},[1], "... also PlanarConfiguration" );

#########################
$seg->set_Exif_data({'XResolution' => [2,36]}, 'IFD0_DATA', 'REPLACE');
$hash = $seg->get_Exif_data('IFD0_DATA', 'TEXTUAL');
is_deeply( $$hash{'XResolution'}, [2,36], "Manual IFD0 XResolution works" );

#########################
$seg->set_Exif_data({'XResolution' => [2,36]}, 'IFD1_DATA', 'REPLACE');
$hash = $seg->get_Exif_data('IFD1_DATA', 'TEXTUAL');
is_deeply( $$hash{'XResolution'}, [2,36], "... also in IFD1" );

#########################
$seg->set_Exif_data($IFD_data, 'IFD0_DATA', 'REPLACE');
$hash =  $seg->get_Exif_data('IFD0_DATA', 'NUMERIC');
$image->set_Exif_data($IFD_data, 'IFD0_DATA', 'ADD');
$hash2 = $image->get_Exif_data('IFD0_DATA', 'NUMERIC');
is_deeply( $hash, $hash2, "adding through image object in IFD0" );

#########################
$image->remove_app1_Exif_info(-1);
$hash = $image->set_Exif_data($IFD_data, 'IFD1_DATA', 'ADD');
is_deeply( $hash, {}, "adding without the IFD1 dir" );

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
$hash = $image->set_Exif_data({'Make' => undef}, 'IFD0_DATA', 'ADD');
ok( exists $$hash{&$val('Make')}, "Invalid string rejected" );

#########################
$hash = $image->set_Exif_data({'Orientation' => 11}, 'IFD1_DATA', 'ADD');
ok( exists $$hash{&$val('Orientation')}, "Invalid Orientation rejected" );

#########################
$hash = $image->set_Exif_data({'TransferFunction'=>[1,2]}, 'IFD0_DATA', 'ADD');
ok( exists $$hash{&$val('TransferFunction')},"Invalid TransferFunc. rejected");

#########################
$hash = $image->set_Exif_data({'XResolution' => 4}, 'IFD1_DATA', 'ADD');
ok( exists $$hash{&$val('XResolution')}, "Invalid resolution rejected" );

#########################
$hash = $image->set_Exif_data({'ResolutionUnit' => 5}, 'IFD0_DATA', 'ADD');
ok( exists $$hash{&$val('ResolutionUnit')}, "Invalid ResolutionUnit rejected");

#########################
$dt = '1999:05:05 12:00:00';
$hash = $image->set_Exif_data({'DateTime' => $dt}, 'IFD0_DATA', 'ADD');
ok( ! exists $$hash{&$val('DateTime')}, "Standard date/time accepted" );

#########################
$hash = $image->get_Exif_data('IFD0_DATA', 'TEXTUAL');
ok( exists $$hash{'DateTime'}, "... gotten back via get_Exif_data" );

#########################
is_deeply( $$hash{'DateTime'}, [$dt."\000"], "... and its value is correct" );

#########################
$dt = '1994:23:23 12:14:61';
$hash = $image->set_Exif_data({'DateTime' => $dt}, 'IFD1_DATA', 'ADD');
ok( exists $$hash{&$val('DateTime')}, "Invalid date/time rejected" );

#########################
$dt = '1821:10:07 04:12:50';
$hash = $image->set_Exif_data({'DateTime' => $dt}, 'IFD1_DATA', 'ADD');
ok( ! exists $$hash{&$val('DateTime')}, "Date in the 19th century accepted" );

#########################
$dt = '1799:10:07 04:12:50';
$hash = $image->set_Exif_data({'DateTime' => $dt}, 'IFD1_DATA', 'ADD');
ok( exists $$hash{&$val('DateTime')}, "Date in the 18th century not accepted");

#########################
$dt = '    :  :     :  :  ';
$hash = $image->set_Exif_data({'DateTime' => $dt}, 'IFD0_DATA', 'ADD');
ok( ! exists $$hash{&$val('DateTime')}, "Blank date/time accepted (1)");

#########################
$dt = ' ' x 19;
$hash = $image->set_Exif_data({'DateTime' => $dt}, 'IFD1_DATA', 'ADD');
ok( ! exists $$hash{&$val('DateTime')}, "Blank date/time accepted (2)");

#########################
$hash = $image->set_Exif_data({'WhitePoint' => [1,2]}, 'IFD0_DATA', 'ADD');
ok( exists $$hash{&$val('WhitePoint')}, "Invalid WhitePoint rejected" );

#########################
$hash = $image->set_Exif_data({'ReferenceBlackWhite' => [(1..18)]},
			      'IFD1_DATA', 'ADD');
ok( exists $$hash{&$val('ReferenceBlackWhite')},
    "Invalid ReferenceBlackWhite rejected" );

#########################
$hash = $image->set_Exif_data({'PrimaryChromaticities' => [(8..40)]},
			      'IFD0_DATA', 'ADD');
ok( exists $$hash{&$val('PrimaryChromaticities')},
    "Invalid PrimaryChromaticities rejected" );

#########################
$hash = $image->set_Exif_data({9999 => 2}, 'IFD0_DATA', 'ADD');
ok( exists $$hash{9999}, "unknown numeric tags are rejected" );

#########################
$hash = $image->set_Exif_data({'Pippero' => 2}, 'IFD1_DATA', 'ADD');
ok( exists $$hash{'Pippero'}, "unknown textual tags are rejected" );

#########################
$hash = $image->set_Exif_data({'TileLength' => 2}, 'IFD0_DATA', 'ADD');
is_deeply( $hash, {}, "a valid field from the additional list" );

#########################
$hash = $image->set_Exif_data({'GrayResponseUnit'=>66000}, 'IFD1_DATA', 'ADD');
ok( exists $$hash{&$val('GrayResponseUnit')}, "... and an invalid one" );

#########################
$hash = $image->set_Exif_data({'JPEGProc' => 100}, 'IFD0_DATA', 'ADD');
ok( exists $$hash{&$val('JPEGProc')}, "... and a forbidden one" );

#########################
$hash = $image->set_Exif_data({'FovCot' => 16.445}, 'IFD1_DATA', 'ADD');
is_deeply( $hash, {}, "a valid float field from the companies' list" );

#########################
$hash = $image->set_Exif_data({'MatrixWorldToScreen' => [map {$_+.5} (1..16)]},
			      'IFD1_DATA', 'ADD');
is_deeply( $hash, {}, "... and a field with 16 floats" );

#########################
$hash = $image->set_Exif_data({'ModelPixelScaleTag' => [map {$_+.5} (1,2,3)]},
			      'IFD1_DATA', 'ADD');
is_deeply( $hash, {}, "... and a field with 3 doubles" );

#########################
$hash = $image->set_Exif_data({'Matteing' => 100}, 'IFD0_DATA', 'ADD');
ok( exists $$hash{&$val('Matteing')}, "... and an obsoleted one" );

#########################
$image->save($ref);
$image2 = newimage($ref, '^APP1$');
is_deeply( $image2->{segments}, $image->{segments}, "Write and reread works");

#########################
$d1 =  $image->get_description();
$d2 = $image2->get_description();
$d1 =~ s/(.*REFERENCE.*-->).*/$1/g; $d1 =~ s/Original.*//g;
$d2 =~ s/(.*REFERENCE.*-->).*/$1/g; $d2 =~ s/Original.*//g;
is( $d1, $d2, "Descriptions are still coincident" );

### Local Variables: ***
### mode:perl ***
### End: ***
