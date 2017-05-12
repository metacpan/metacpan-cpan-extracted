use Test::More tests => 44;
BEGIN { require 't/test_setup.pl'; }

my $tphoto = 't/test_photo.jpg';
my $tdata  = 't/test_photo.desc';
my ($image, $thumbimage, $seg1, $seg2, $hash, $hash2, $records,
    %realcounts, %counts, $count, $data, $data2, @lines, $desc1, $desc2);

#=======================================
diag "Testing APP1 Exif data routines";
#=======================================

BEGIN { use_ok ($::tabname, qw(:RecordTypes)) or exit; }
BEGIN { use_ok ($::pkgname) or exit; } # this must be loaded second!

#########################
$image = newimage($tphoto);
is( $image->get_segments('APP1$'), 1, "Number of APP1 segments" );

#########################
is( $image->retrieve_app1_Exif_segment(-1), 1, "Number, alternatively" );

#########################
is( $image->retrieve_app1_Exif_segment(1), undef, "Out-of-bound index" );

#########################
$seg1 = $image->retrieve_app1_Exif_segment(0);
$seg2 = $image->provide_app1_Exif_segment();
is_deeply( $seg1, $seg2, "Get segment in two ways" );

#########################
$hash = $seg1->get_Exif_data('All', 'TEXTUAL');
is( $hash, undef, "get_Exif_data with wrong \$what returns undef" );

#########################
$hash = $seg1->get_Exif_data('ALL', 'TExTUAL');
is( $hash, undef, "get_Exif_data with wrong \$type returns undef" );

#########################
$desc1 = $seg1->get_description();
$hash  = $seg1->get_Exif_data('ALL', 'TEXTUAL');
for my $k1 (keys %$hash) {
    next unless ref $$hash{$k1} eq 'HASH';
    for my $k2 (keys %{$$hash{$k1}}) {
	next unless ref $$hash{$k1}{$k2} eq 'ARRAY';
	unshift @{$$hash{$k1}{$k2}}, 17; } } # try to modify data
$desc2 = $seg1->get_description();
is( $desc1, $desc2, "get_Exif_data('ALL') returns a copy of actual data" );

#########################
$desc1 = $seg1->get_description();
$hash  = $seg1->get_Exif_data('IMAGE_DATA', 'TEXTUAL');
for my $k1 (keys %$hash) {
    next unless ref $$hash{$k1} eq 'HASH';
    for my $k2 (keys %{$$hash{$k1}}) {
	next unless ref $$hash{$k1}{$k2} eq 'ARRAY';
	unshift @{$$hash{$k1}{$k2}}, 27; } }
$desc2 = $seg1->get_description();
is( $desc1, $desc2, "get_Exif_data('IMAGE_DATA') behaves the same way" );

#########################
$hash = $seg1->get_Exif_data('ALL', 'TEXTUAL');
is( scalar keys %$hash, 7, "there are seven subdirs" );

#########################
$hash2 = $image->get_Exif_data('ALL', 'TEXTUAL');
is_deeply( $hash, $hash2, "the two forms of get_Exif_data agree" );

#########################
$records = $seg1->search_record_value($$_[1]),
    $realcounts{$$_[0]} = grep { $_->{type} != $REFERENCE } @$records,
    for (['ROOT_DATA', ''], ['IFD1_DATA', 'IFD1'], ['IFD0_DATA', 'IFD0'],
	 ['GPS_DATA', 'IFD0@GPS'], ['SUBIFD_DATA', 'IFD0@SubIFD'],
	 ['INTEROP_DATA', 'IFD0@SubIFD@Interop']);
$records = $seg1->search_record_value('IFD0@SubIFD');
$records = (map { $_->get_value() }
	    grep { $_->{key} =~ /^MakerNoteData/ } @$records)[0];
$realcounts{'MAKERNOTE_DATA'} = grep{ $_->{type} != $REFERENCE } @$records;
%counts = map { $_ => (scalar keys %{$$hash{$_}}) } keys %$hash;
is_deeply( \ %counts , \ %realcounts, "(sub)IFD's record counts OK ..." );

#########################
$hash = $seg1->get_Exif_data('ALL', 'NUMERIC');
%counts = map { $_ => (scalar keys %{$$hash{$_}}) } keys %$hash;
is_deeply( \ %counts , \ %realcounts, "... also without textual translation" );

#########################
$hash2 = $image->get_Exif_data('ALL', 'NUMERIC');
is_deeply( $hash, $hash2, "... Structure and Segment method coincide" );

#########################
$hash = $seg1->get_Exif_data($_, 'TEXTUAL'),
    is( scalar keys %$hash, $realcounts{$_}, "count OK for $_" ),
    for ('ROOT_DATA', 'IFD0_DATA', 'IFD1_DATA', 'SUBIFD_DATA',
	 'GPS_DATA', 'INTEROP_DATA', 'MAKERNOTE_DATA');

#########################
$hash = $seg1->get_Exif_data($_, 'ROOT_DATA');
$count = scalar grep {/known/} keys %$hash;
is( $count, 0, "All textual keys in ROOT_DATA are known" );

#########################
$hash = $seg1->get_Exif_data('IMAGE_DATA');
is( scalar keys %$hash, $realcounts{'IFD1_DATA'} + $realcounts{'SUBIFD_DATA'},
    "count OK for IMAGE_DATA" );

#########################
$hash = $seg1->get_Exif_data('THUMB_DATA');
is( scalar keys %$hash, $realcounts{'IFD1_DATA'}, "count OK for THUMB_DATA" );

#########################
$hash  = $seg1->get_Exif_data('IFD0_DATA');
$hash2 = $seg1->get_Exif_data('SUBIFD_DATA');
@$hash{keys %$hash2} = values %$hash2;
$hash2 = $seg1->get_Exif_data('IMAGE_DATA');
is_deeply( $hash, $hash2,"IMAGE_DATA is a merge of IFD0_DATA and SUBIFD_DATA");

#########################
$hash  = $seg1->get_Exif_data('THUMB_DATA');
$hash2 = $seg1->get_Exif_data('IFD1_DATA');
is_deeply( $hash, $hash2, "THUMB_DATA and IFD1_DATA return the same struct." );

#########################
is( $$hash{'Compression'}[0], 6, "The test file contains a JPEG thumbnail" );

#########################
cmp_ok( $$hash{'JPEGInterchangeFormatLength'}[0], '>', 0,
	"declared size not null" );

#########################
$data = $seg1->get_Exif_data('THUMBNAIL');
isnt( $data, undef, "thumbnail data is present" );

#########################
$data2 = $image->get_Exif_data('THUMBNAIL');
is_deeply( $data, $data2, "... Structure and Segment method coincide" );

#########################
open(ZZ, $tdata); @lines = grep { /ThumbnailData/ } <ZZ>; close(ZZ);
$lines[0] =~ s/.*\(([\d]*) more chars\).*/$1/;
is( length $$data, 13 + $lines[0], "thumbnail data size from description OK" );

#########################
is( length $$data, $$hash{'JPEGInterchangeFormatLength'}[0],
    "thumbnail data size from IFD1 data OK" );

#########################
$thumbimage = newimage($data);
ok( $thumbimage, "This thumbnail is a valid JPEG file" );

#########################
is( scalar $thumbimage->get_segments(), 7, "number of thumbnail segments OK" );

#########################
$image->remove_app1_Exif_info(-1);
is( $image->get_segments('APP1$'), 0, "Deleting Exif APP1 segments works" );

#########################
$seg1 = $image->provide_app1_Exif_segment();
$data = $seg1->get_Exif_data('THUMBNAIL');
is( length $$data, 0, "Absence of thumbnail correctly detected" );

#########################
$hash = $seg1->get_Exif_data('THUMB_DATA');
is_deeply( $hash, {}, "Absence of thumbnail data is correctly detected" );

#########################
$hash = $seg1->get_Exif_data('IMAGE_DATA');
is_deeply( $hash, {}, "Absence of primary image data is correctly detected" );

#########################
$hash = $seg1->get_Exif_data('GPS_DATA');
is_deeply( $hash, {}, "Absence of GPS data is correctly detected" );

#########################
$hash = $seg1->get_Exif_data('INTEROP_DATA');
is_deeply( $hash, {}, "Absence of interop. data is correctly detected" );

#########################
$hash = $seg1->get_Exif_data('ALL');
isnt( scalar keys %$hash, 0, "'ALL' on a bare Exif segment is not empty" );

#########################
$records = $seg1->search_record_value($$_[1]),
    $realcounts{$$_[0]} = grep { $_->{type} != $REFERENCE } @$records,
    for (['ROOT_DATA', ''], ['IFD1_DATA', 'IFD1'], ['IFD0_DATA', 'IFD0'],
	 ['GPS_DATA', 'IFD0@GPS'], ['SUBIFD_DATA', 'IFD0@SubIFD'],
	 ['INTEROP_DATA', 'IFD0@SubIFD@Interop']);
$records = $seg1->search_record_value('IFD0@SubIFD');
$records = (map { $_->get_value() }
	    grep { $_->{key} =~ /^MakerNoteData/ } @$records)[0];
$realcounts{'MAKERNOTE_DATA'} = grep{ $_->{type} != $REFERENCE } @$records;
%counts = map { $_ => (scalar keys %{$$hash{$_}}) } keys %$hash;
is_deeply( \ %counts , \ %realcounts, "Again, (sub)IFD record counts OK ..." );

#########################
eval { $image->set_Exif_data({}, 'STUPID_DATA', 'REPLACE') };
ok( ! $@, "Set with an undefined action is mortal" ); 

### Local Variables: ***
### mode:perl ***
### End: ***
