use Test::More tests => 55;
BEGIN { require 't/test_setup.pl'; }

my $tphoto = 't/test_photo.jpg';
my $shop   = 'PHOTOSHOP';
my ($image, $seg1, $seg2, $rec, $val, $hash, $num, $segs, $fh, $desc1, $desc2);

#=======================================
diag "Testing APP13 IPTC basic routines";
#=======================================

BEGIN { use_ok ($::tabname, qw(:TagsAPP13)) or exit; }
BEGIN { use_ok ($::pkgname) or exit; } # this must be loaded second!

#########################
{open $fh, $0; is( (grep { /set_app13_data/ } <$fh>), 1, "No setters here" );}

#########################
$image = newimage($tphoto);
is( $image->get_segments('APP13'), 1, "Number of APP13 segments" );

#########################
is( $image->retrieve_app13_segment(-1, $shop), 1, "... of Photoshop APP13" );

#########################
is( $image->retrieve_app13_segment(-1, 'IPTC'), 1, "... of IPTC_2 APP13" );

#########################
is( $image->retrieve_app13_segment(-1, 'IPTC_1'), 0, "... of IPTC_1 APP13" );

#########################
is( $image->retrieve_app13_segment(1, $shop), undef, "Out-of-bound index" );

#########################
is( $image->retrieve_app13_segment(-2, 'IPTC_1'), undef, "Negative index" );

#########################
$seg1 = $image->retrieve_app13_segment(0, $shop);
$rec  = $seg1->search_record('Identifier');
$val  = $rec->get_value(); 
$rec->set_value('Paperino');# trick to mask segment
$seg2 = $image->provide_app13_segment($shop);
$rec->set_value($val); # we have two APP13 segs now
is( $image->retrieve_app13_segment(-1, $shop), 2, "2 Photoshop segments now" );

#########################
is( $image->retrieve_app13_segment(-1,'IPTC'), 1, "... but only one is IPTC" );

#########################
is( $image->retrieve_app13_segment(1, $shop), $seg2,
    "You can ask for the 2nd Photoshop segment" );

#########################
$seg2->provide_app13_subdir('IPTC_1');
ok( $seg2->is_app13_ok('IPTC_1'), "... and make it IPTC_1 complaiant");

#########################
ok( ! $seg2->is_app13_ok('IPTC'), "... without making it IPTC complaiant");

#########################
ok( ! $seg2->is_app13_ok('IPTC_2'), "... asking for IPTC_2 is the same");

#########################
is( $image->retrieve_app13_segment(1, 'IPTC'), undef,
    "You cannot ask for the 2nd IPTC segment" );

#########################
is( $image->provide_app13_segment('IPTC_1'), $seg2,
    "Provide segment finds IPTC_1, does not create it" );

#########################
$image->remove_app13_info(0, $shop);
is( $image->retrieve_app13_segment(-1, $shop), 1, "First Photoshop deleted" );

#########################
$seg1 = $image->retrieve_app13_segment(0, $shop);
$seg2 = $image->retrieve_app13_segment(0, 'IPTC');
isnt( $seg1, $seg2, "Now \$index = 0 depends on \$what" );

#########################
$image->remove_app13_info(0, $shop);
$seg1 = $image->retrieve_app13_segment(0, $shop);
is( $seg1, undef, "We can erase Photoshop info from index = 0" );

#########################
$seg1 = $image->retrieve_app13_segment(0, 'IPTC');
is( $seg1, $seg2, "... without touching the other segment" );

#########################
$image->remove_app13_info(0, $shop);
$seg1 = $image->retrieve_app13_segment(0, 'IPTC');
is( $seg1, $seg2, "... even if we repeat remove_app13_info" );

#########################
$image->remove_app13_info(0, 'IPTC');
$seg1 = $image->retrieve_app13_segment(0, 'IPTC');
is( $seg1, undef, "Now also the IPTC segment is gone");

#########################
$image->remove_app13_info(0, 'IPTC_1');
is( $image->retrieve_app13_segment(-1), 0, "No APP13 segments currently" );

#########################
$seg1 = $image->provide_app13_segment($shop);
isnt( $seg1, undef, "provide_app13_segment creates a segment" );

#########################
$seg1 = $image->retrieve_app13_segment(0, 'IPTC');
is( $seg1, undef, "... but it does not insert too much information" );

#########################
eval { $image->retrieve_app13_segment(0, "iPtC") };
isnt( $@, '', "A wrong \$what hurts in retrieve_app13_segment" );

#########################
eval { $image->retrieve_app13_segment(0, "IPTC_3") };
isnt( $@, '', "... also a futuristic \$what hurts" );

#########################
eval { $image->provide_app13_segment("Fotoshop") };
isnt( $@, '', "It hurts also in provide_app13_segment" );

#########################
$seg1 = $image->provide_app13_segment('IPTC_2');
$hash = $seg1->get_app13_data(undef, $shop);
is( scalar keys %$hash, 0, "No non-IPTC record created by provide_..." );

#########################
$hash = $seg1->get_app13_data('NUMERIC', 'IPTC');
is( scalar keys %$hash, 1, "But one IPTC/IPTC_2 record is there" );

#########################
ok( exists $$hash{0}, "... and it is the version dataset" );

#########################
$image->provide_app13_segment('IPTC_1');
$hash = $image->get_app13_data('NUMERIC', 'IPTC_1');
is( scalar keys %$hash, 1, "One mandatory dataset inserted for IPTC_1" );

#########################
ok( exists $$hash{0}, "... and it is the version dataset" );

#########################
$image = newimage($tphoto); # reset
$seg1 = $image->retrieve_app13_segment(0, $shop);
$seg2 = $image->provide_app13_segment($shop);
is_deeply( $seg1, $seg2, "Get IPTC segment in two ways [Photoshop]" );

#########################
$seg1 = $image->retrieve_app13_segment(0, 'IPTC');
$seg2 = $image->provide_app13_segment('IPTC');
is_deeply( $seg1, $seg2, "Get IPTC segment in two ways [IPTC]" );

#########################
$num = scalar @{$seg1->search_record_value($APP13_PHOTOSHOP_DIRNAME.'_8BIM')};
$hash = $seg1->get_app13_data('NUMERIC', $shop);
is( scalar keys %$hash, $num, "Num elements from numeric get [Photoshop]" );

#########################
is( (grep {/^[0-9]*$/} keys %$hash), $num, "... all tags are numeric" );

#########################
$hash = $seg1->get_app13_data('TEXTUAL', $shop);
is( scalar keys %$hash, $num, "... num elements from textual get" );

#########################
is( (grep {!/^[0-9]*$/} keys %$hash), $num, "... all tags are textual" );

#########################
$num = scalar @{$seg1->search_record_value($APP13_IPTC_DIRNAME.'_2')};
$hash = $seg1->get_app13_data('NUMERIC', 'IPTC');
is( keys %$hash, $num, "Num elements from numeric get [IPTC]" );

#########################
is( exists $$hash{0} ? 1 : undef, 1, "Record Version exists" );

#########################
is( (grep {/^[0-9]*$/} keys %$hash), $num, "... all tags are numeric" );

#########################
$hash = $seg1->get_app13_data('TEXTUAL', 'IPTC');
is( scalar keys %$hash, $num, "... num elements from textual get" );

#########################
is( (grep {!/^[0-9]*$/} keys %$hash), $num, "... all tags are textual" );

#########################
$image->remove_app13_info(-1, 'IPTC');
$num = $image->retrieve_app13_segment(-1, 'IPTC');
is( $num, 0, "Removing IPTC information" );

#########################
$num = $image->get_segments('APP13');
is( $num, 1, "... but not the APP13 segment" );

#########################
$image->remove_app13_info(0, $shop);
$num = $image->retrieve_app13_segment(-1, $shop);
is( $num, 0, "Removing Photoshop info with index" );

#########################
$num = $image->get_segments('APP13');
is( $num, 0, "... this time, a real segment removal" );

#########################
$seg1 = $image->retrieve_app13_segment(0, 'IPTC');
is( $seg1, undef, "Retrieve not forcing a segment" );

#########################
$seg1 = $image->provide_app13_segment('IPTC');
isnt( $seg1, undef, "Provide forcing a segment" );

#########################
eval { $hash = $image->get_app13_data('NUMERICAL', 'IPTC') };
isnt( $@, undef, "get_app13_data fails with wrong label" );

#########################
eval { $hash = $image->get_app13_data('ILLEGAL', 'IPTC'); };
isnt( $@, undef, "get_app13_data fails with illegal type" );

#########################
$image = newimage($tphoto);
$seg1  = $image->retrieve_app13_segment(0, 'IPTC');
$desc1 = $seg1->get_description();
$hash  = $seg1->get_app13_data('NUMERIC', 'IPTC');
$_ = 17 for values %$hash;
$desc2 = $seg1->get_description();
is( $desc1, $desc2, "get_app13_data [IPTC] returns a copy of actual data" );

#########################
$seg1  = $image->retrieve_app13_segment(0, $shop);
$desc1 = $seg1->get_description();
$hash  = $seg1->get_app13_data('NUMERIC', $shop);
$_ = 27 for values %$hash;
$desc2 = $seg1->get_description();
is( $desc1, $desc2, "get_app13_data [PHOTOSHOP] behaves the same way" );

### Local Variables: ***
### mode:perl ***
### End: ***
