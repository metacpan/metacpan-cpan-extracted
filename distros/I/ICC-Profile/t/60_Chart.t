#!/usr/bin/perl -w

# ICC::Support::Chart test module / 2018-03-26
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 225;

# YAML reference files were created with 'chart_to_YAML.pl'.

# local variables
my ($chart, $chart2, $chart3, $chart4, $chart5, $chart6, $chart7, $chart8, $chart9, $chart10);
my ($array, $hash, $yaml, $slice, $rowx, $colx, @context);

# does module load
BEGIN { use_ok('ICC::Support::Chart') };

# test class methods
can_ok('ICC::Support::Chart', qw(new header array size matrix_size rows cols fmt_keys context test keyword created slice colorimetry));
can_ok('ICC::Support::Chart', qw(id name rgb cmyk hex nCLR device ctv lab xyz density rgbv spectral nm wavelength iwtpt wtpt bkpt oba_index));
can_ok('ICC::Support::Chart', qw(add_rows add_cols add_avg add_fmt add_ctv add_lab add_xyz add_density add_udf add_date splice_rows splice_cols remove_rows remove_cols));
can_ok('ICC::Support::Chart', qw(select_matrix select_template find ramp range randomize analyze write writeASCII writeCxF3 writeTIFF writeASE sdump));
can_ok('Math::Matrix', qw(rotate flip randomize));


# make empty Chart object
$chart = ICC::Support::Chart->new();

# test object class
isa_ok($chart, 'ICC::Support::Chart');

# test object structure
ok(ref($chart->[0]) eq 'HASH', 'header hash');
ok(ref($chart->[1]) eq 'ARRAY', 'data array');
ok(ref($chart->[2]) eq 'ARRAY', 'colorimetry array');
ok(ref($chart->[3]) eq 'ARRAY', 'header line array');
ok(ref($chart->[4]) eq 'HASH', 'SAMPLE_ID hash');

# make header hash
$hash = {'aaa' => 1, 'bbb' => 2, 'ccc' => 3};

# set object header hash
$chart->header($hash);

# get header hash and compare
is_deeply($chart->header(), $hash, 'get/set header hash');

# make data array
$array = [[qw(SAMPLE_ID CMYK_C CMYK_M CMYK_Y CMYK_K)], [3, 0, 0, 0, 0], [1, 10, 10, 10, 10], [2, 20, 20, 20, 20]];

# set object array
$chart->array($array);

# get data array and compare
is_deeply($chart->array(), $array, 'get/set data array');

# make Chart object from data array
$chart = ICC::Support::Chart->new($array);

# test object structure
ok(ref($chart->[0]) eq 'HASH', 'header hash');
ok(ref($chart->[2]) eq 'ARRAY', 'colorimetry array');

# test object data elements
is_deeply($chart->[1], $array, 'data array');
ok((3 == grep {$chart->[4]{$chart->[1][$_][0]} == $_} (1 .. 3)), 'SAMPLE_ID hash');

# read YAML equivalent of CMYK-Lab CGATS ASCII file
$yaml = YAML::Tiny->read(File::Spec->catfile('t', 'data', 'CMYK-Lab_ASCII.yml'));

# make Chart object from CMYK-Lab CGATS ASCII file (Windows CR-LF line ending)
$chart = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'CMYK-Lab_ASCII_CRLF.txt'));

# test file path
ok($chart->[0]{'file_path'} eq File::Spec->catfile('t', 'data', 'CMYK-Lab_ASCII_CRLF.txt'), 'CMYK-Lab_ASCII_CRLF file path');

# test record separator
ok($chart->[0]{'read_rs'} eq "\015\012", 'CRLF record separator');

# compare object elements
is_deeply($chart->[1], $yaml->[1], 'CMYK-Lab_ASCII_CRLF data');
is_deeply($chart->[2], $yaml->[2], 'CMYK-Lab_ASCII_CRLF colorimetry');
is_deeply($chart->[3], $yaml->[3], 'CMYK-Lab_ASCII_CRLF header lines');
is_deeply($chart->[4], $yaml->[4], 'CMYK-Lab_ASCII_CRLF SAMPLE_ID hash');

# make Chart object from CMYK-Lab CGATS ASCII file (Mac Classic CR line ending)
$chart = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'CMYK-Lab_ASCII_CR.txt'));

# test file path
ok($chart->[0]{'file_path'} eq File::Spec->catfile('t', 'data', 'CMYK-Lab_ASCII_CR.txt'), 'CMYK-Lab_ASCII_CR file path');

# test record separator
ok($chart->[0]{'read_rs'} eq "\015", 'CR record separator');

# compare object elements
is_deeply($chart->[1], $yaml->[1], 'CMYK-Lab_ASCII_CR data');
is_deeply($chart->[2], $yaml->[2], 'CMYK-Lab_ASCII_CR colorimetry');
is_deeply($chart->[3], $yaml->[3], 'CMYK-Lab_ASCII_CR header lines');
is_deeply($chart->[4], $yaml->[4], 'CMYK-Lab_ASCII_CR SAMPLE_ID hash');

# make Chart object from CMYK-Lab CGATS ASCII file (Unix LF line ending)
$chart = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'CMYK-Lab_ASCII_LF.txt'));

# test file path
ok($chart->[0]{'file_path'} eq File::Spec->catfile('t', 'data', 'CMYK-Lab_ASCII_LF.txt'), 'CMYK-Lab_ASCII_LF file path');

# test record separator
ok($chart->[0]{'read_rs'} eq "\012", 'LF record separator');

# compare object elements
is_deeply($chart->[1], $yaml->[1], 'CMYK-Lab_ASCII_LF data');
is_deeply($chart->[2], $yaml->[2], 'CMYK-Lab_ASCII_LF colorimetry');
is_deeply($chart->[3], $yaml->[3], 'CMYK-Lab_ASCII_LF header lines');
is_deeply($chart->[4], $yaml->[4], 'CMYK-Lab_ASCII_LF SAMPLE_ID hash');

# read YAML equivalent of RGB-Spectral CGATS ASCII file
$yaml = YAML::Tiny->read(File::Spec->catfile('t', 'data', 'RGB-Spectral_ASCII.yml'));

# make Chart object from RGB-Spectral CGATS ASCII file (Unix LF line ending)
$chart2 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'RGB-Spectral_ASCII.txt'));

# test file path
ok($chart2->[0]{'file_path'} eq File::Spec->catfile('t', 'data', 'RGB-Spectral_ASCII.txt'), 'RGB-Spectral_ASCII file path');

# test record separator
ok($chart2->[0]{'read_rs'} eq "\012", 'LF record separator');

# compare object elements
is_deeply($chart2->[1], $yaml->[1], 'RGB-Spectral_ASCII data');
is_deeply($chart2->[2], $yaml->[2], 'RGB-Spectral_ASCII colorimetry');
is_deeply($chart2->[3], $yaml->[3], 'RGB-Spectral_ASCII header lines');
is_deeply($chart2->[4], $yaml->[4], 'RGB-Spectral_ASCII SAMPLE_ID hash');

# read YAML equivalent of CMYK-Spectral CGATS ASCII file
$yaml = YAML::Tiny->read(File::Spec->catfile('t', 'data', 'CMYK-Spectral_ASCII.yml'));

# make Chart object from CMYK-Spectral CGATS ASCII file (Unix LF line ending)
$chart3 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'CMYK-Spectral_ASCII.txt'));

# test file path
ok($chart3->[0]{'file_path'} eq File::Spec->catfile('t', 'data', 'CMYK-Spectral_ASCII.txt'), 'CMYK-Spectral_ASCII file path');

# test record separator
ok($chart3->[0]{'read_rs'} eq "\012", 'LF record separator');

# compare object elements
is_deeply($chart3->[1], $yaml->[1], 'CMYK-Spectral_ASCII data');
is_deeply($chart3->[2], $yaml->[2], 'CMYK-Spectral_ASCII colorimetry');
is_deeply($chart3->[3], $yaml->[3], 'CMYK-Spectral_ASCII header lines');
is_deeply($chart3->[4], $yaml->[4], 'CMYK-Spectral_ASCII SAMPLE_ID hash');

# read YAML equivalent of Hex-Spectral CGATS ASCII file
$yaml = YAML::Tiny->read(File::Spec->catfile('t', 'data', 'Hex-Spectral_ASCII.yml'));

# make Chart object from Hex-Spectral CGATS ASCII file (Unix LF line ending)
$chart4 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'Hex-Spectral_ASCII.txt'));

# test file path
ok($chart4->[0]{'file_path'} eq File::Spec->catfile('t', 'data', 'Hex-Spectral_ASCII.txt'), 'Hex-Spectral_ASCII file path');

# test record separator
ok($chart4->[0]{'read_rs'} eq "\012", 'LF record separator');

# compare object elements
is_deeply($chart4->[1], $yaml->[1], 'Hex-Spectral_ASCII data');
is_deeply($chart4->[2], $yaml->[2], 'Hex-Spectral_ASCII colorimetry');
is_deeply($chart4->[3], $yaml->[3], 'Hex-Spectral_ASCII header lines');
is_deeply($chart4->[4], $yaml->[4], 'Hex-Spectral_ASCII SAMPLE_ID hash');

# read YAML equivalent of CMYK-Lab CxF3 file
$yaml = YAML::Tiny->read(File::Spec->catfile('t', 'data', 'CMYK-Lab_CxF3.yml'));

# make Chart object from CMYK-Lab CxF3 file
$chart5 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'CMYK-Lab_CxF3.mxf'));

# test file path
ok($chart5->[0]{'file_path'} eq File::Spec->catfile('t', 'data', 'CMYK-Lab_CxF3.mxf'), 'CMYK-Lab_CxF3 file path');

# test record separator
ok($chart5->[0]{'read_rs'} eq "\n", 'record separator');

# compare object elements
is_deeply($chart5->[1], $yaml->[1], 'CMYK-Lab_CxF3 data');
is_deeply($chart5->[2], $yaml->[2], 'CMYK-Lab_CxF3 colorimetry');
is_deeply($chart5->[3], $yaml->[3], 'CMYK-Lab_CxF3 header lines');
is_deeply($chart5->[4], $yaml->[4], 'CMYK-Lab_CxF3 SAMPLE_ID hash');

# read YAML equivalent of RGB-Spectral CxF3 file
$yaml = YAML::Tiny->read(File::Spec->catfile('t', 'data', 'RGB-Spectral_CxF3.yml'));

# make Chart object from RGB-Spectral CxF3 file
$chart6 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'RGB-Spectral_CxF3.mxf'));

# test file path
ok($chart6->[0]{'file_path'} eq File::Spec->catfile('t', 'data', 'RGB-Spectral_CxF3.mxf'), 'RGB-Spectral_CxF3 file path');

# test record separator
ok($chart6->[0]{'read_rs'} eq "\n", 'record separator');

# compare object elements
is_deeply($chart6->[1], $yaml->[1], 'RGB-Spectral_CxF3 data');
is_deeply($chart6->[2], $yaml->[2], 'RGB-Spectral_CxF3 colorimetry');
is_deeply($chart6->[3], $yaml->[3], 'RGB-Spectral_CxF3 header lines');
is_deeply($chart6->[4], $yaml->[4], 'RGB-Spectral_CxF3 SAMPLE_ID hash');

# read YAML equivalent of CMYK-Spectral CxF3 file
$yaml = YAML::Tiny->read(File::Spec->catfile('t', 'data', 'CMYK-Spectral_CxF3.yml'));

# make Chart object from CMYK-Spectral CxF3 file
$chart7 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'CMYK-Spectral_CxF3.mxf'));

# test file path
ok($chart7->[0]{'file_path'} eq File::Spec->catfile('t', 'data', 'CMYK-Spectral_CxF3.mxf'), 'CMYK-Spectral_CxF3 file path');

# test record separator
ok($chart7->[0]{'read_rs'} eq "\n", 'record separator');

# compare object elements
is_deeply($chart7->[1], $yaml->[1], 'CMYK-Spectral_CxF3 data');
is_deeply($chart7->[2], $yaml->[2], 'CMYK-Spectral_CxF3 colorimetry');
is_deeply($chart7->[3], $yaml->[3], 'CMYK-Spectral_CxF3 header lines');
is_deeply($chart7->[4], $yaml->[4], 'CMYK-Spectral_CxF3 SAMPLE_ID hash');

# read YAML equivalent of Hex-Spectral CxF3 file
$yaml = YAML::Tiny->read(File::Spec->catfile('t', 'data', 'Hex-Spectral_CxF3.yml'));

# make Chart object from Hex-Spectral CxF3 file
$chart8 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'Hex-Spectral_CxF3.mxf'));

# test file path
ok($chart8->[0]{'file_path'} eq File::Spec->catfile('t', 'data', 'Hex-Spectral_CxF3.mxf'), 'Hex-Spectral_CxF3 file path');

# test record separator
ok($chart8->[0]{'read_rs'} eq "\n", 'record separator');

# compare object elements
is_deeply($chart8->[1], $yaml->[1], 'Hex-Spectral_CxF3 data');
is_deeply($chart8->[2], $yaml->[2], 'Hex-Spectral_CxF3 colorimetry');
is_deeply($chart8->[3], $yaml->[3], 'Hex-Spectral_CxF3 header lines');
is_deeply($chart8->[4], $yaml->[4], 'Hex-Spectral_CxF3 SAMPLE_ID hash');

# read YAML equivalent of CMYK-Lab ASCII Averaged chart
$yaml = YAML::Tiny->read(File::Spec->catfile('t', 'data', 'CMYK-Lab_ASCII_AVG.yml'));

# make Chart object from CMYK-Lab ASCII folder, Averaging
$chart9 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'CMYK-Lab_ASCII'));

# test file path
ok($chart9->[0]{'file_path'} eq File::Spec->catfile('t', 'data', 'CMYK-Lab_ASCII'), 'CMYK-Lab_ASCII file path');

# test record separator
ok($chart9->[0]{'read_rs'} eq "\012", 'LF record separator');

# compare object elements
ok(cmp_matrix($chart9->[1], $yaml->[1]), 'CMYK-Lab ASCII Averaged folder data');
is_deeply($chart9->[2], $yaml->[2], 'CMYK-Lab ASCII Averaged folder colorimetry');
is_deeply($chart9->[3], $yaml->[3], 'CMYK-Lab ASCII Averaged folder header lines');
is_deeply($chart9->[4], $yaml->[4], 'CMYK-Lab ASCII Averaged folder SAMPLE_ID hash');

# read YAML equivalent of CMYK-Lab ASCII Appended chart
$yaml = YAML::Tiny->read(File::Spec->catfile('t', 'data', 'CMYK-Lab_ASCII_APPEND.yml'));

# make Chart object from CMYK-Lab ASCII folder, Appending
$chart10 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'CMYK-Lab_ASCII'), {'folder' => 'APPEND'});

# test file path
ok($chart10->[0]{'file_path'} eq File::Spec->catfile('t', 'data', 'CMYK-Lab_ASCII'), 'CMYK-Lab_ASCII file path');

# test record separator
ok($chart10->[0]{'read_rs'} eq "\012", 'LF record separator');

# compare object elements
is_deeply($chart10->[1], $yaml->[1], 'CMYK-Lab ASCII Appended folder data');
is_deeply($chart10->[2], $yaml->[2], 'CMYK-Lab ASCII Appended folder colorimetry');
is_deeply($chart10->[3], $yaml->[3], 'CMYK-Lab ASCII Appended folder header lines');
is_deeply($chart10->[4], $yaml->[4], 'CMYK-Lab ASCII Appended folder SAMPLE_ID hash');

# get chart data upper indices
$rowx = $#{$chart->[1]};
$colx = $#{$chart->[1][0]};

# test 'slice' method (no arguments)
is_deeply(bless($chart->slice(), 'ARRAY'), obj_slice($chart, 1, [1 .. $rowx], [0 .. $colx]), 'slice - no arguments');

# test 'slice' method (rows 1 - 3)
is_deeply(bless($chart->slice([1 .. 3]), 'ARRAY'), obj_slice($chart, 1, [1 .. 3], [0 .. $colx]), 'slice - rows 1 - 3');

# test 'slice' method (rows 1 - 3, columns 2 - 5)
is_deeply(bless($chart->slice([1 .. 3], [2 .. 5]), 'ARRAY'), obj_slice($chart, 1, [1 .. 3], [2 .. 5]), 'slice - rows 1 - 3, columns 2 - 5');

# test 'slice' method (replace)
$chart->slice([1 .. 3], [1 .. 3], obj_slice($chart, 1, [7 .. 9], [4 .. 6]));
is_deeply(bless($chart->slice([1 .. 3], [1 .. 3]), 'ARRAY'), obj_slice($chart, 1, [7 .. 9], [4 .. 6]), 'replace data slice');

# test 'rows' method
is_deeply($chart->rows(qw(165 166 167 168)), [7, 6, 5, 4], 'CMYK-Lab_ASCII_LF rows method string');
is_deeply($chart->rows(165, 166, 167, 168), [7, 6, 5, 4], 'CMYK-Lab_ASCII_LF rows method numeric');

# test 'rows' method (undef result)
is($chart->rows(qw(165 166 167 XXX)), undef, 'CMYK-Lab_ASCII_LF rows method undefined');

# test 'cols' method (no context)
is_deeply($chart->cols(qw(SAMPLE_ID SAMPLE_NAME CMYK_C CMYK_M CMYK_Y CMYK_K XYZ_X XYZ_Y XYZ_Z LAB_L LAB_A LAB_B)), [0 .. 11], 'CMYK-Lab_ASCII_LF cols method');
is_deeply($chart2->cols(qw(SAMPLE_ID SAMPLE_NAME RGB_R RGB_G RGB_B nm380 nm390)), [0 .. 6], 'RGB-Spectral_ASCII cols method');
is_deeply($chart3->cols(qw(SAMPLE_ID SAMPLE_NAME CMYK_C CMYK_M CMYK_Y CMYK_K nm380 nm390)), [0 .. 7], 'CMYK-Spectral_ASCII cols method');
is_deeply($chart4->cols(qw(SAMPLE_ID SAMPLE_NAME 6CLR_1 6CLR_2 6CLR_3 6CLR_4 6CLR_5 6CLR_6 nm380 nm390)), [0 .. 9], 'Hex-Spectral_ASCII cols method');
is_deeply($chart5->cols(qw(CMYK_C CMYK_M CMYK_Y CMYK_K LAB_L LAB_A LAB_B)), [0 .. 6], 'CMYK-Lab_CxF3 cols method');
is_deeply($chart6->cols(qw(RGB_R RGB_G RGB_B nm380 nm390)), [0 .. 4], 'RGB-Spectral_CxF3 cols method');
is_deeply($chart7->cols(qw(CMYK_C CMYK_M CMYK_Y CMYK_K nm380 nm390)), [0 .. 5], 'CMYK-Spectral_CxF3 cols method');
is_deeply($chart8->cols(qw(6CLR_1 6CLR_2 6CLR_3 6CLR_4 6CLR_5 6CLR_6 nm380 nm390)), [0 .. 7], 'Hex-Spectral_CxF3 cols method');

# test 'cols' method (with context)
is_deeply($chart5->cols(qw(Target|CMYK_C Target|CMYK_M Target|CMYK_Y Target|CMYK_K M0_Measurement|LAB_L)), [0 .. 4], 'CMYK-Lab_CxF3 cols method w|context');
is_deeply($chart6->cols(qw(Target|RGB_R Target|RGB_G Target|RGB_B M0_Measurement|nm380)), [0 .. 3], 'RGB-Spectral_CxF3 cols method w|context');
is_deeply($chart7->cols(qw(Target|CMYK_C Target|CMYK_M Target|CMYK_Y Target|CMYK_K M0_Measurement|nm380)), [0 .. 4], 'CMYK-Spectral_CxF3 cols method w|context');
is_deeply($chart8->cols(qw(Target|6CLR_1 Target|6CLR_2 Target|6CLR_3 Target|6CLR_4 Target|6CLR_5 Target|6CLR_6 M0_Measurement|nm380)), [0 .. 6], 'Hex-Spectral_CxF3 cols method w|context');

# test 'cols' method (undef result)
is($chart->cols(qw(SAMPLE_ID CMYK_X)), undef, 'CMYK-Lab_ASCII_LF cols method undefined');
is($chart5->cols(qw(SAMPLE_ID Target|CMYK_X)), undef, 'CMYK-Lab_CxF3 cols method undefined');
is($chart5->cols(qw(SAMPLE_ID X|CMYK_C)), undef, 'CMYK-Lab_CxF3 cols method undefined');

# test 'fmt_keys' method
is_deeply($chart->fmt_keys(0 .. 11), [qw(SAMPLE_ID SAMPLE_NAME CMYK_C CMYK_M CMYK_Y CMYK_K XYZ_X XYZ_Y XYZ_Z LAB_L LAB_A LAB_B)], 'CMYK-Lab_ASCII_LF fmt_keys method');
is_deeply($chart5->fmt_keys(0 .. 4), [qw(Target|CMYK_C Target|CMYK_M Target|CMYK_Y Target|CMYK_K M0_Measurement|LAB_L)], 'CMYK-Lab_CxF3 fmt_keys method');
ok(! defined($chart->fmt_keys(0 .. 12)), 'CMYK-Lab_ASCII_LF fmt_keys method undefined');

# test 'context' method
# get context of column slice
is($chart5->context([0 .. 3]), 'Target', 'CMYK-Lab_CxF3 context method');
ok(! defined($chart->context([2 .. 5])), 'CMYK-Lab_ASCII_LF context method undefined');

# get context of column slice as an array
@context = $chart5->context([0 .. 3]);
is_deeply(\@context, [('Target') x 4], 'CMYK-Lab_CxF3 context method as array');
@context = $chart->context([2 .. 5]);
is_deeply(\@context, [(undef) x 4], 'CMYK-Lab_ASCII_LF context method as array undefined');

# set context of keys
$chart->context([2 .. 5], 'Target');
is_deeply($chart->fmt_keys(0 .. 11), [qw(SAMPLE_ID SAMPLE_NAME Target|CMYK_C Target|CMYK_M Target|CMYK_Y Target|CMYK_K XYZ_X XYZ_Y XYZ_Z LAB_L LAB_A LAB_B)], 'CMYK-Lab_ASCII_LF context method set');

# change context of keys
$chart->context([2 .. 5], 'XXX');
is_deeply($chart->fmt_keys(0 .. 11), [qw(SAMPLE_ID SAMPLE_NAME XXX|CMYK_C XXX|CMYK_M XXX|CMYK_Y XXX|CMYK_K XYZ_X XYZ_Y XYZ_Z LAB_L LAB_A LAB_B)], 'CMYK-Lab_ASCII_LF context method change');

# remove context
$chart->context([2 .. 5], undef);
is_deeply($chart->fmt_keys(0 .. 11), [qw(SAMPLE_ID SAMPLE_NAME CMYK_C CMYK_M CMYK_Y CMYK_K XYZ_X XYZ_Y XYZ_Z LAB_L LAB_A LAB_B)], 'CMYK-Lab_ASCII_LF context method remove');

# re-load chart
$chart = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'CMYK-Lab_ASCII_LF.txt'));

# test 'test' method (no context)
is_deeply(test_classes($chart), [0, 4, 3, 0, 3, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1], 'CMYK-Lab_ASCII_LF test all classes');
is_deeply(test_classes($chart2), [3, 0, 0, 0, 0, 0, 0, 36, 0, 0, 0, 0, 0, 1, 1], 'RGB-Spectral_ASCII test all classes');
is_deeply(test_classes($chart3), [0, 4, 0, 0, 0, 0, 0, 36, 0, 0, 0, 0, 0, 1, 1], 'CMYK-Spectral_ASCII test all classes');
is_deeply(test_classes($chart4), [0, 0, 0, 0, 0, 0, 6, 36, 0, 0, 0, 0, 0, 1, 1], 'Hex-Spectral_ASCII test all classes');
is_deeply(test_classes($chart5), [0, 4, 0, 0, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0], 'CMYK-Lab_CxF3 test all classes');
is_deeply(test_classes($chart6), [3, 0, 0, 0, 0, 0, 0, 36, 0, 0, 0, 0, 0, 0, 0], 'RGB-Spectral_CxF3 test all classes');
is_deeply(test_classes($chart7), [0, 4, 0, 0, 0, 0, 0, 36, 0, 0, 0, 0, 0, 0, 0], 'CMYK-Spectral_CxF3 test all classes');
is_deeply(test_classes($chart8), [0, 0, 0, 0, 0, 0, 6, 36, 0, 0, 0, 0, 0, 0, 0], 'Hex-Spectral_CxF3 test all classes');

# test 'test' method (with context)
is_deeply(test_classes($chart, 'Target'), [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 'CMYK-Lab_ASCII_LF test all classes w/context');
is_deeply(test_classes($chart5, 'Target'), [0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 'CMYK-Lab_CxF3 test all classes w/context');
is_deeply(test_classes($chart5, 'M0_Measurement'), [0, 0, 0, 0, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0], 'CMYK-Lab_CxF3 test all classes w/context');
is_deeply(test_classes($chart6, 'Target'), [3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 'RGB-Spectral_CxF3 test all classes w/context');
is_deeply(test_classes($chart6, 'M0_Measurement'), [0, 0, 0, 0, 0, 0, 0, 36, 0, 0, 0, 0, 0, 0, 0], 'RGB-Spectral_CxF3 test all classes w/context');
is_deeply(test_classes($chart7, 'Target'), [0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 'CMYK-Spectral_CxF3 test all classes w/context');
is_deeply(test_classes($chart7, 'M0_Measurement'), [0, 0, 0, 0, 0, 0, 0, 36, 0, 0, 0, 0, 0, 0, 0], 'CMYK-Spectral_CxF3 test all classes w/context');
is_deeply(test_classes($chart8, 'Target'), [0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0], 'Hex-Spectral_CxF3 test all classes w/context');
is_deeply(test_classes($chart8, 'M0_Measurement'), [0, 0, 0, 0, 0, 0, 0, 36, 0, 0, 0, 0, 0, 0, 0], 'Hex-Spectral_CxF3 test all classes w/context');

# test shortcut methods (no context)
is_deeply(test_shortcuts($chart), [[0], [1], [], [2 .. 5], [], [], [2 .. 5], [], [9 .. 11], [6 .. 8], [], []], 'CMYK-Lab_ASCII_LF test all shortcuts');
is_deeply(test_shortcuts($chart2), [[0], [1], [2 .. 4], [], [], [], [2 .. 4], [], [], [], [], [5 .. 40]], 'RGB-Spectral_ASCII test all shortcuts');
is_deeply(test_shortcuts($chart3), [[0], [1], [], [2 .. 5], [], [], [2 .. 5], [], [], [], [], [6 .. 41]], 'CMYK-Spectral_ASCII test all shortcuts');
is_deeply(test_shortcuts($chart4), [[0], [1], [], [], [2 .. 7], [2 .. 7], [2 .. 7], [], [], [], [], [8 .. 43]], 'Hex-Spectral_ASCII test all shortcuts');
is_deeply(test_shortcuts($chart5), [[], [], [], [0 .. 3], [], [], [0 .. 3], [], [4 .. 6], [], [], []], 'CMYK-Lab_CxF3 test all shortcuts');
is_deeply(test_shortcuts($chart6), [[], [], [0 .. 2], [], [], [], [0 .. 2], [], [], [], [], [3 .. 38]], 'RGB-Spectral_CxF3 test all shortcuts');
is_deeply(test_shortcuts($chart7), [[], [], [], [0 .. 3], [], [], [0 .. 3], [], [], [], [], [4 .. 39]], 'CMYK-Spectral_CxF3 test all shortcuts');
is_deeply(test_shortcuts($chart8), [[], [], [], [], [0 .. 5], [0 .. 5], [0 .. 5], [], [], [], [], [6 .. 41]], 'Hex-Spectral_CxF3 test all shortcuts');

# test shortcut methods (with context)
is_deeply(test_shortcuts($chart, {'context' => 'Target'}), [[], [], [], [], [], [], [], [], [], [], [], []], 'CMYK-Lab_ASCII_LF test all shortcuts w/context');
is_deeply(test_shortcuts($chart5, {'context' => 'Target'}), [[], [], [], [0 .. 3], [], [], [0 .. 3], [], [], [], [], []], 'CMYK-Lab_CxF3 test all shortcuts w/context');
is_deeply(test_shortcuts($chart5, {'context' => 'M0_Measurement'}), [[], [], [], [], [], [], [], [], [4 .. 6], [], [], []], 'CMYK-Lab_CxF3 test all shortcuts w/context');
is_deeply(test_shortcuts($chart6, {'context' => 'Target'}), [[], [], [0 .. 2], [], [], [], [0 .. 2], [], [], [], [], []], 'RGB-Spectral_CxF3 test all shortcuts w/context');
is_deeply(test_shortcuts($chart6, {'context' => 'M0_Measurement'}), [[], [], [], [], [], [], [], [], [], [], [], [3 .. 38]], 'RGB-Spectral_CxF3 test all shortcuts w/context');
is_deeply(test_shortcuts($chart7, {'context' => 'Target'}), [[], [], [], [0 .. 3], [], [], [0 .. 3], [], [], [], [], []], 'CMYK-Spectral_CxF3 test all shortcuts w/context');
is_deeply(test_shortcuts($chart7, {'context' => 'M0_Measurement'}), [[], [], [], [], [], [], [], [], [], [], [], [4 .. 39]], 'CMYK-Spectral_CxF3 test all shortcuts w/context');
is_deeply(test_shortcuts($chart8, {'context' => 'Target'}), [[], [], [], [], [0 .. 5], [0 .. 5], [0 .. 5], [], [], [], [], []], 'Hex-Spectral_CxF3 test all shortcuts w/context');
is_deeply(test_shortcuts($chart8, {'context' => 'M0_Measurement'}), [[], [], [], [], [], [], [], [], [], [], [], [6 .. 41]], 'Hex-Spectral_CxF3 test all shortcuts w/context');

# test shortcut methods (get data)
is_deeply(bless($chart->id([]), 'ARRAY'), obj_slice($chart, 1, [1 .. $#{$chart->[1]}], $chart->id()), 'CMYK-Lab_ASCII_LF test get ID data');
is_deeply(bless($chart->name([]), 'ARRAY'), obj_slice($chart, 1, [1 .. $#{$chart->[1]}], $chart->name()), 'CMYK-Lab_ASCII_LF test get NAME data');
is_deeply(bless($chart->cmyk([]), 'ARRAY'), obj_slice($chart, 1, [1 .. $#{$chart->[1]}], $chart->cmyk()), 'CMYK-Lab_ASCII_LF test get CMYK data');
is_deeply(bless($chart->xyz([]), 'ARRAY'), obj_slice($chart, 1, [1 .. $#{$chart->[1]}], $chart->xyz()), 'CMYK-Lab_ASCII_LF test get XYZ data');
is_deeply(bless($chart->lab([]), 'ARRAY'), obj_slice($chart, 1, [1 .. $#{$chart->[1]}], $chart->lab()), 'CMYK-Lab_ASCII_LF test get L*a*b* data');
is_deeply(bless($chart2->rgb([]), 'ARRAY'), obj_slice($chart2, 1, [1 .. $#{$chart2->[1]}], $chart2->rgb()), 'RGB-Spectral_ASCII test get RGB data');
is_deeply(bless($chart2->spectral([]), 'ARRAY'), obj_slice($chart2, 1, [1 .. $#{$chart2->[1]}], $chart2->spectral()), 'RGB-Spectral_ASCII test get spectral data');
is_deeply(bless($chart3->cmyk([]), 'ARRAY'), obj_slice($chart3, 1, [1 .. $#{$chart3->[1]}], $chart3->cmyk()), 'CMYK-Spectral_ASCII_LF test get CMYK data');
is_deeply(bless($chart3->spectral([]), 'ARRAY'), obj_slice($chart3, 1, [1 .. $#{$chart3->[1]}], $chart3->spectral()), 'CMYK-Spectral_ASCII test get spectral data');
is_deeply(bless($chart4->hex([]), 'ARRAY'), obj_slice($chart4, 1, [1 .. $#{$chart4->[1]}], $chart4->hex()), 'Hex-Spectral_ASCII test get Hex data');
is_deeply(bless($chart4->spectral([]), 'ARRAY'), obj_slice($chart4, 1, [1 .. $#{$chart4->[1]}], $chart4->spectral()), 'Hex-Spectral_ASCII test get spectral data');
is_deeply(bless($chart5->cmyk([]), 'ARRAY'), obj_slice($chart5, 1, [1 .. $#{$chart5->[1]}], $chart5->cmyk()), 'CMYK-Lab_CxF3 test get CMYK data');
is_deeply(bless($chart5->lab([]), 'ARRAY'), obj_slice($chart5, 1, [1 .. $#{$chart5->[1]}], $chart5->lab()), 'CMYK-Lab_CxF3 test get L*a*b* data');
is_deeply(bless($chart6->rgb([]), 'ARRAY'), obj_slice($chart6, 1, [1 .. $#{$chart6->[1]}], $chart6->rgb()), 'RGB-Spectral_CxF3 test get RGB data');
is_deeply(bless($chart6->spectral([]), 'ARRAY'), obj_slice($chart6, 1, [1 .. $#{$chart6->[1]}], $chart6->spectral()), 'RGB-Spectral_CxF3 test get spectral data');
is_deeply(bless($chart7->cmyk([]), 'ARRAY'), obj_slice($chart7, 1, [1 .. $#{$chart7->[1]}], $chart7->cmyk()), 'CMYK-Spectral_CxF3 test get CMYK data');
is_deeply(bless($chart7->spectral([]), 'ARRAY'), obj_slice($chart7, 1, [1 .. $#{$chart7->[1]}], $chart7->spectral()), 'CMYK-Spectral_CxF3 test get spectral data');
is_deeply(bless($chart8->hex([]), 'ARRAY'), obj_slice($chart8, 1, [1 .. $#{$chart8->[1]}], $chart8->hex()), 'Hex-Spectral_CxF3 test get Hex data');
is_deeply(bless($chart8->spectral([]), 'ARRAY'), obj_slice($chart8, 1, [1 .. $#{$chart8->[1]}], $chart8->spectral()), 'Hex-Spectral_CxF3 test get spectral data');
is_deeply(bless($chart4->nCLR([]), 'ARRAY'), obj_slice($chart4, 1, [1 .. $#{$chart4->[1]}], $chart4->hex()), 'Hex-Spectral_ASCII test get nCLR data');
is_deeply(bless($chart->id([3 .. 7]), 'ARRAY'), obj_slice($chart, 1, [3 .. 7], $chart->id()), 'CMYK-Lab_ASCII_LF test get ID data');
is_deeply(bless($chart->name([3 .. 7]), 'ARRAY'), obj_slice($chart, 1, [3 .. 7], $chart->name()), 'CMYK-Lab_ASCII_LF test get NAME data');
is_deeply(bless($chart->cmyk([3 .. 7]), 'ARRAY'), obj_slice($chart, 1, [3 .. 7], $chart->cmyk()), 'CMYK-Lab_ASCII_LF test get CMYK data');
is_deeply(bless($chart->xyz([3 .. 7]), 'ARRAY'), obj_slice($chart, 1, [3 .. 7], $chart->xyz()), 'CMYK-Lab_ASCII_LF test get XYZ data');
is_deeply(bless($chart->lab([3 .. 7]), 'ARRAY'), obj_slice($chart, 1, [3 .. 7], $chart->lab()), 'CMYK-Lab_ASCII_LF test get L*a*b* data');
is_deeply(bless($chart2->rgb([3 .. 7]), 'ARRAY'), obj_slice($chart2, 1, [3 .. 7], $chart2->rgb()), 'RGB-Spectral_ASCII test get RGB data');
is_deeply(bless($chart2->spectral([3 .. 7]), 'ARRAY'), obj_slice($chart2, 1, [3 .. 7], $chart2->spectral()), 'RGB-Spectral_ASCII test get spectral data');
is_deeply(bless($chart4->hex([3 .. 7]), 'ARRAY'), obj_slice($chart4, 1, [3 .. 7], $chart4->hex()), 'Hex-Spectral_ASCII test get Hex data');
is_deeply(bless($chart4->nCLR([3 .. 7]), 'ARRAY'), obj_slice($chart4, 1, [3 .. 7], $chart4->hex()), 'Hex-Spectral_ASCII test get nCLR data');

# test shortcut methods (get device data)
is_deeply(bless($chart->device([]), 'ARRAY'), div_slice(obj_slice($chart, 1, [1 .. $#{$chart->[1]}], $chart->cmyk()), [(100) x 4]), 'CMYK-Lab_ASCII_LF test get device data');
is_deeply(bless($chart2->device([]), 'ARRAY'), div_slice(obj_slice($chart2, 1, [1 .. $#{$chart2->[1]}], $chart2->rgb()), [(255) x 3]), 'RGB-Spectral_ASCII test get device data');
is_deeply(bless($chart4->device([]), 'ARRAY'), div_slice(obj_slice($chart4, 1, [1 .. $#{$chart4->[1]}], $chart4->hex()), [(100) x 6]), 'Hex-Spectral_ASCII test get device data');

# test shortcut methods (get data with context)
ok(! defined($chart->cmyk([], {'context' => 'Target'})), 'CMYK-Lab_ASCII_LF test get CMYK data w/context undefined');
is_deeply(bless($chart5->cmyk([], {'context' => 'Target'}), 'ARRAY'), obj_slice($chart5, 1, [1 .. $#{$chart5->[1]}], $chart5->cmyk()), 'CMYK-Lab_CxF3 test get CMYK data w/context');
is_deeply(bless($chart5->lab([], {'context' => 'M0_Measurement'}), 'ARRAY'), obj_slice($chart5, 1, [1 .. $#{$chart5->[1]}], $chart5->lab()), 'CMYK-Lab_CxF3 test get L*a*b* data w/context');
is_deeply(bless($chart6->rgb([], {'context' => 'Target'}), 'ARRAY'), obj_slice($chart6, 1, [1 .. $#{$chart6->[1]}], $chart6->rgb()), 'RGB-Spectral_CxF3 test get RGB data w/context');
is_deeply(bless($chart6->spectral([], {'context' => 'M0_Measurement'}), 'ARRAY'), obj_slice($chart6, 1, [1 .. $#{$chart6->[1]}], $chart6->spectral()), 'RGB-Spectral_CxF3 test get spectral data w/context');
is_deeply(bless($chart7->cmyk([], {'context' => 'Target'}), 'ARRAY'), obj_slice($chart7, 1, [1 .. $#{$chart7->[1]}], $chart7->cmyk()), 'CMYK-Spectral_CxF3 test get CMYK data w/context');
is_deeply(bless($chart7->spectral([], {'context' => 'M0_Measurement'}), 'ARRAY'), obj_slice($chart7, 1, [1 .. $#{$chart7->[1]}], $chart7->spectral()), 'CMYK-Spectral_CxF3 test get spectral data w/context');
is_deeply(bless($chart8->hex([], {'context' => 'Target'}), 'ARRAY'), obj_slice($chart8, 1, [1 .. $#{$chart8->[1]}], $chart8->hex()), 'Hex-Spectral_CxF3 test get Hex data w/context');
is_deeply(bless($chart8->spectral([], {'context' => 'M0_Measurement'}), 'ARRAY'), obj_slice($chart8, 1, [1 .. $#{$chart8->[1]}], $chart8->spectral()), 'Hex-Spectral_CxF3 test get spectral data w/context');

# test shortcut methods (get device data with context)
ok(! defined($chart->device([], {'context' => 'Target'})), 'CMYK-Lab_ASCII_LF test get device data w/context undefined');
is_deeply(bless($chart5->device([], {'context' => 'Target'}), 'ARRAY'), div_slice(obj_slice($chart5, 1, [1 .. $#{$chart5->[1]}], $chart5->cmyk()), [(100) x 4]), 'CMYK-Lab_CxF3 test get device data w/context');
is_deeply(bless($chart6->device([], {'context' => 'Target'}), 'ARRAY'), div_slice(obj_slice($chart6, 1, [1 .. $#{$chart6->[1]}], $chart6->rgb()), [(255) x 3]), 'RGB-Spectral_CxF3 test get device data w/context');
is_deeply(bless($chart8->device([], {'context' => 'Target'}), 'ARRAY'), div_slice(obj_slice($chart8, 1, [1 .. $#{$chart8->[1]}], $chart8->hex()), [(100) x 6]), 'Hex-Spectral_CxF3 test get device data w/context');

# test shortcut methods (replace data)
$chart->id([1 .. 3], obj_slice($chart, 1, [7 .. 9], [0]));
is_deeply(bless($chart->id([1 .. 3]), 'ARRAY'), obj_slice($chart, 1, [7 .. 9], [0]), 'replace id data slice');
$chart->name([1 .. 3], obj_slice($chart, 1, [7 .. 9], [1]));
is_deeply(bless($chart->name([1 .. 3]), 'ARRAY'), obj_slice($chart, 1, [7 .. 9], [1]), 'replace name data slice');
$chart->cmyk([1 .. 3], obj_slice($chart, 1, [7 .. 9], [2 .. 5]));
is_deeply(bless($chart->cmyk([1 .. 3]), 'ARRAY'), obj_slice($chart, 1, [7 .. 9], [2 .. 5]), 'replace cmyk data slice');
$chart->xyz([1 .. 3], obj_slice($chart, 1, [7 .. 9], [6 .. 8]));
is_deeply(bless($chart->xyz([1 .. 3]), 'ARRAY'), obj_slice($chart, 1, [7 .. 9], [6 .. 8]), 'replace xyz data slice');
$chart->lab([1 .. 3], obj_slice($chart, 1, [7 .. 9], [9 .. 11]));
is_deeply(bless($chart->lab([1 .. 3]), 'ARRAY'), obj_slice($chart, 1, [7 .. 9], [9 .. 11]), 'replace lab data slice');
$chart2->rgb([1 .. 3], obj_slice($chart2, 1, [7 .. 9], [2 .. 4]));
is_deeply(bless($chart2->rgb([1 .. 3]), 'ARRAY'), obj_slice($chart2, 1, [7 .. 9], [2 .. 4]), 'replace rgb data slice');
$chart2->spectral([1 .. 3], obj_slice($chart2, 1, [7 .. 9], [5 .. 40]));
is_deeply(bless($chart2->spectral([1 .. 3]), 'ARRAY'), obj_slice($chart2, 1, [7 .. 9], [5 .. 40]), 'replace spectral data slice');
$chart4->hex([1 .. 3], obj_slice($chart4, 1, [7 .. 9], [2 .. 7]));
is_deeply(bless($chart4->hex([1 .. 3]), 'ARRAY'), obj_slice($chart4, 1, [7 .. 9], [2 .. 7]), 'replace hex data slice');
$chart4->nCLR([2 .. 4], obj_slice($chart4, 1, [7 .. 9], [2 .. 7]));
is_deeply(bless($chart4->nCLR([2 .. 4]), 'ARRAY'), obj_slice($chart4, 1, [7 .. 9], [2 .. 7]), 'replace nCLR data slice');

# test shortcut methods (replace device data)
$chart->device([4 .. 6], div_slice(obj_slice($chart, 1, [7 .. 9], [2 .. 5]), [(100) x 4]));
is_deeply(bless($chart->device([4 .. 6]), 'ARRAY'), div_slice(obj_slice($chart, 1, [7 .. 9], [2 .. 5]), [(100) x 4]), 'replace device data slice');
$chart2->device([4 .. 6], div_slice(obj_slice($chart2, 1, [7 .. 9], [2 .. 4]), [(255) x 3]));
is_deeply(bless($chart2->device([4 .. 6]), 'ARRAY'), div_slice(obj_slice($chart2, 1, [7 .. 9], [2 .. 4]), [(255) x 3]), 'replace device data slice');
$chart4->device([4 .. 6], div_slice(obj_slice($chart4, 1, [7 .. 9], [2 .. 7]), [(100) x 6]));
is_deeply(bless($chart4->device([4 .. 6]), 'ARRAY'), div_slice(obj_slice($chart4, 1, [7 .. 9], [2 .. 7]), [(100) x 6]), 'replace device data slice');

# test shortcut methods (replace data with context)
$chart5->cmyk([1 .. 3], obj_slice($chart5, 1, [7 .. 9], [1 .. 4]), {'context' => 'Target'});
is_deeply(bless($chart5->cmyk([1 .. 3], {'context' => 'Target'}), 'ARRAY'), obj_slice($chart5, 1, [7 .. 9], [1 .. 4]), 'CMYK-Lab_CxF3 test replace CMYK data w/context');
$chart5->lab([1 .. 3], obj_slice($chart5, 1, [7 .. 9], [5 .. 7]), {'context' => 'M0_Measurement'});
is_deeply(bless($chart5->lab([1 .. 3], {'context' => 'M0_Measurement'}), 'ARRAY'), obj_slice($chart5, 1, [7 .. 9], [5 .. 7]), 'CMYK-Lab_CxF3 test replace L*a*b* data w/context');
$chart6->rgb([1 .. 3], obj_slice($chart6, 1, [7 .. 9], [1 .. 3]), {'context' => 'Target'});
is_deeply(bless($chart6->rgb([1 .. 3], {'context' => 'Target'}), 'ARRAY'), obj_slice($chart6, 1, [7 .. 9], [1 .. 3]), 'RGB-Spectral_CxF3 test replace RGB data w/context');
$chart6->spectral([1 .. 3], obj_slice($chart6, 1, [7 .. 9], [4 .. 39]), {'context' => 'M0_Measurement'});
is_deeply(bless($chart6->spectral([1 .. 3], {'context' => 'M0_Measurement'}), 'ARRAY'), obj_slice($chart6, 1, [7 .. 9], [4 .. 39]), 'RGB-Spectral_CxF3 test replace spectral data w/context');
$chart7->cmyk([1 .. 3], obj_slice($chart7, 1, [7 .. 9], [1 .. 4]), {'context' => 'Target'});
is_deeply(bless($chart7->cmyk([1 .. 3], {'context' => 'Target'}), 'ARRAY'), obj_slice($chart7, 1, [7 .. 9], [1 .. 4]), 'CMYK-Spectral_CxF3 test replace CMYK data w/context');
$chart7->spectral([1 .. 3], obj_slice($chart7, 1, [7 .. 9], [5 .. 40]), {'context' => 'M0_Measurement'});
is_deeply(bless($chart7->spectral([1 .. 3], {'context' => 'M0_Measurement'}), 'ARRAY'), obj_slice($chart7, 1, [7 .. 9], [5 .. 40]), 'CMYK-Spectral_CxF3 test replace spectral data w/context');
$chart8->hex([1 .. 3], obj_slice($chart8, 1, [7 .. 9], [1 .. 6]), {'context' => 'Target'});
is_deeply(bless($chart8->hex([1 .. 3], {'context' => 'Target'}), 'ARRAY'), obj_slice($chart8, 1, [7 .. 9], [1 .. 6]), 'Hex-Spectral_CxF3 test replace Hex data w/context');
$chart8->spectral([1 .. 3], obj_slice($chart8, 1, [7 .. 9], [7 .. 42]), {'context' => 'M0_Measurement'});
is_deeply(bless($chart8->spectral([1 .. 3], {'context' => 'M0_Measurement'}), 'ARRAY'), obj_slice($chart8, 1, [7 .. 9], [7 .. 42]), 'Hex-Spectral_CxF3 test replace spectral data w/context');
$chart8->nCLR([1 .. 3], obj_slice($chart8, 1, [7 .. 9], [1 .. 6]), {'context' => 'Target'});
is_deeply(bless($chart8->nCLR([1 .. 3], {'context' => 'Target'}), 'ARRAY'), obj_slice($chart8, 1, [7 .. 9], [1 .. 6]), 'Hex-Spectral_CxF3 test replace nCLR data w/context');

# test shortcut methods (replace device data with context)
$chart5->device([4 .. 6], div_slice(obj_slice($chart5, 1, [7 .. 9], [1 .. 4]), [(100) x 4]), {'context' => 'Target'});
is_deeply(bless($chart5->device([4 .. 6], {'context' => 'Target'}), 'ARRAY'), div_slice(obj_slice($chart5, 1, [7 .. 9], [1 .. 4]), [(100) x 4]), 'CMYK-Lab_CxF3 test replace device data w/context');
$chart6->device([4 .. 6], div_slice(obj_slice($chart6, 1, [7 .. 9], [1 .. 3]), [(255) x 3]), {'context' => 'Target'});
is_deeply(bless($chart6->device([4 .. 6], {'context' => 'Target'}), 'ARRAY'), div_slice(obj_slice($chart6, 1, [7 .. 9], [1 .. 3]), [(255) x 3]), 'RGB-Spectral_CxF3 test replace device data w/context');
$chart8->device([4 .. 6], div_slice(obj_slice($chart8, 1, [7 .. 9], [1 .. 6]), [(100) x 6]), {'context' => 'Target'});
is_deeply(bless($chart8->device([4 .. 6], {'context' => 'Target'}), 'ARRAY'), div_slice(obj_slice($chart8, 1, [7 .. 9], [1 .. 6]), [(100) x 6]), 'Hex-Spectral_CxF3 test replace device data w/context');

# re-load charts
$chart = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'CMYK-Lab_ASCII_LF.txt'));
$chart2 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'RGB-Spectral_ASCII.txt'));
$chart3 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'CMYK-Spectral_ASCII.txt'));
$chart4 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'Hex-Spectral_ASCII.txt'));
$chart5 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'CMYK-Lab_CxF3.mxf'));
$chart6 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'RGB-Spectral_CxF3.mxf'));
$chart7 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'CMYK-Spectral_CxF3.mxf'));
$chart8 = ICC::Support::Chart->new(File::Spec->catfile('t', 'data', 'Hex-Spectral_CxF3.mxf'));


exit;

# divide slice
sub div_slice {

	# get parameters
	my ($slice, $mult) = @_;

	# for each row
	for my $i (0 .. $#{$slice}) {
	
		# for each column
		for my $j (0 .. $#{$slice->[0]}) {
		
			# multiply slice
			$slice->[$i][$j] /= $mult->[$j];
		
		}
	
	}

	# return
	return($slice);

}

# multiply slice
sub mult_slice {

	# get parameters
	my ($slice, $mult) = @_;

	# for each row
	for my $i (0 .. $#{$slice}) {
	
		# for each column
		for my $j (0 .. $#{$slice->[0]}) {
		
			# multiply slice
			$slice->[$i][$j] *= $mult->[$j];
		
		}
	
	}

	# return
	return($slice);

}

# get object slice
sub obj_slice {

	# get parameters
	my ($self, $i, $rows, $cols) = @_;

	# local variables
	my ($s, $x, $y);

	# set index
	$x = 0;

	# for each row
	for my $j (@{$rows}) {
	
		# set index
		$y = 0;
	
		# for each column
		for my $k (@{$cols}) {
		
			# copy array element
			$s->[$x][$y++] = $self->[$i][$j][$k];
		
		}
	
		#increment index
		$x++;
	
	}

	# return slice
	return($s);

}

# test classes
sub test_classes {

	# get object reference
	my $self = shift();

	# make class list
	my @class = qw(RGB CMYK XYZ XYY LAB LCH NCLR SPECTRAL SPOT DENSITY STDEVXYZ STDEVLAB MEAN_DE ID NAME);

	# return array
	return([map {scalar($self->test($_, @_))} @class]);

}

# test shortcuts
sub test_shortcuts {

	# get object reference
	my $self = shift();

	# make method list
	my @shortcut = qw(id name rgb cmyk hex nCLR device ctv lab xyz density spectral);

	# return array ('undef' changed to '[]' to avoid warnings)
	return([map {my $s = $self->$_(@_); defined($s) ? $s : []} @shortcut]);

}

# compare matrices
# numeric elements compared with tolerance
# non-numeric elements compared as strings
# parameters: (matrix_1, matrix_2)
# returns: (flag)
sub cmp_matrix {

	# get parameters
	my ($mat1, $mat2) = @_;

	# local variables
	my(@fp1, @fp2, @dif);

	# return failed if different number rows
	return(0) if ($#{$mat1} != $#{$mat2});

	# for each row
	for my $i (0 .. $#{$mat1}) {
		
		# return failed if different number columns
		return(0) if ($#{$mat1->[$i]} != $#{$mat2->[$i]});
		
		# for each column
		for my $j (0 .. $#{$mat1->[$i]}) {
			
			# if matrix element is a number
			if (Scalar::Util::looks_like_number($mat1->[$i][$j])) {
				
				# if elements not equal
				if ($mat1->[$i][$j] != $mat2->[$i][$j]) {
					
					# compute binary mantissa and exponent
					@fp1 = POSIX::frexp($mat1->[$i][$j]);
					@fp2 = POSIX::frexp($mat2->[$i][$j]);
					@dif = POSIX::frexp($mat1->[$i][$j] - $mat2->[$i][$j]);
					
					# return failed if maximum exponent difference < 40 (about 12 decimal digits)
					return(0) if (($fp1[1] > $fp2[1] ? $fp1[1] : $fp2[1]) - $dif[1] < 40);
					
				}
				
			} else {
				
				# return failed if elements not equal (as strings)
				return(0) if ($mat1->[$i][$j] ne $mat2->[$i][$j]);
				
			}
			
		}
		
	}

	# return success
	return(1);

}


