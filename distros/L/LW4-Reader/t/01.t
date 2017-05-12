# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More 'no_plan';
use Test::More tests => 48;
BEGIN { use_ok('LW4::Reader') };

use LW4::Reader qw( read_header read_item_info build_category_phrases );

#########################

my $lw4_file_name = 't/test.lw4';

open my $lw4_file_fh, "$lw4_file_name"
    or die "Couldn't open $lw4_file_name:   $!\n";

##################################################
# Test out ability to read "header" information. #
##################################################

my $lw4_header = read_header($lw4_file_fh);

is( $lw4_header->{save_date},        '3/2/08',        'test.lw4 has correct save date' );
is( $lw4_header->{save_time},        '3:43 PM',      'test.lw4 has correct save time' );
is( $lw4_header->{show_name},        'Test LW4',      'test.lw4 has correct show name' );
is( $lw4_header->{sub_head_1},       'Sub Heading 1', 'test.lw4 has correct 1st sub heading' );
is( $lw4_header->{sub_head_2},       'Sub Heading 2', 'test.lw4 has correct 2nd sub heading' );
is( $lw4_header->{sub_head_3},       'Sub Heading 3', 'test.lw4 has correct 3rd sub heading' );
is( $lw4_header->{sub_head_4},       'Sub Heading 4', 'test.lw4 has correct 4th sub heading' );
is( $lw4_header->{sub_head_5},       'Sub Heading 5', 'test.lw4 has correct 5th sub heading' );
is( $lw4_header->{sub_head_6},       'Sub Heading 6', 'test.lw4 has correct 6th sub heading' );
is( $lw4_header->{num_fixtures},     '23',            'test.lw4 has 23 fixtures' );
is( $lw4_header->{max_num_fixtures}, '25',            'test.lw4 has had 25 fixtures' );
is( $lw4_header->{file_ident},       'ST:1344153201', 'test.lw4 has correct file ID' );

################################################
# Test our ability to assemble a phrase table. #
################################################ 

my $lw4_phrase_AoA = build_category_phrases($lw4_file_fh);

# Test the first and last of each group.

is( $lw4_phrase_AoA->[1]->[1], 'Area 1 Warm',
    'First purpose phrase is correct' );
is( $lw4_phrase_AoA->[1]->[27], 'Test 3',
    'Last purpose phrase is correct' );
is( $lw4_phrase_AoA->[2]->[1], 'FOH Cove',
    'First position phrase is correct' );
is( $lw4_phrase_AoA->[2]->[4], '3E',
    'Last position phrase is correct' );
is( $lw4_phrase_AoA->[3]->[1], 'S4 26',
    'First fixture phrase is correct' );
is( $lw4_phrase_AoA->[3]->[6], 'S4 PARNel, WFL',
    'Last fixture phrase is correct' );
is( $lw4_phrase_AoA->[4]->[1], 'Top Hat',
    'First fixture phrase is correct');
is( $lw4_phrase_AoA->[4]->[3], 'Beam Bender',
    'Last fixture phrase is correct');
is( $lw4_phrase_AoA->[5]->[1], 'R 02',
    'First color phrase is correct');
is( $lw4_phrase_AoA->[5]->[6], 'N/C',
    'Last color phrase is correct');
is( $lw4_phrase_AoA->[6]->[1], 'APAR 1000',
    'First template phrase is correct');
is( $lw4_phrase_AoA->[6]->[3], 'GPB 328',
    'Last template phrase is correct');

############################################
# Test to verify that our data is accruate #
############################################

seek ($lw4_file_fh, 0, 0);

my $lw4_item_info_AoH_ref = read_item_info($lw4_file_fh);

ok( defined $lw4_item_info_AoH_ref, 'Able to read data from test.lw4' );

is( $lw4_item_info_AoH_ref->[0]->{channel}, '9',
    'Channel of first read item is correct');
is( $lw4_item_info_AoH_ref->[0]->{dimmer}, '8',
    'Dimmer of first read item is correct');
is( $lw4_item_info_AoH_ref->[0]->{unit}, '2',
    'Unit Number of first read item is correct');
is( $lw4_item_info_AoH_ref->[0]->{watts}, '750',
    'Wattage of first read item is correct');
is( $lw4_item_info_AoH_ref->[0]->{circuit}, '7',
    'Circuit Number of first read item is correct');
is( $lw4_item_info_AoH_ref->[0]->{purpose}, 'Area 1 Warm',
    'Purpose of first read item is correct');
is( $lw4_item_info_AoH_ref->[0]->{position}, 'FOH Cove',
    'Position of first read item is correct');
is( $lw4_item_info_AoH_ref->[0]->{color}, 'R 02',
    'Color of first read item is correct');
is( $lw4_item_info_AoH_ref->[0]->{type}, 'S4 26',
    'Instrument type of first read item is correct');
is( $lw4_item_info_AoH_ref->[0]->{pattern}, 'APAR 1000',
    'Template of first read item is correct');
is( $lw4_item_info_AoH_ref->[0]->{item_key}, '1382023169',
    'Item key of first read item is correct');

is( $lw4_item_info_AoH_ref->[22]->{channel}, '50',
    'Channel of last read item is correct');
is( $lw4_item_info_AoH_ref->[22]->{dimmer}, '50',
    'Dimmer of last read item is correct');
is( $lw4_item_info_AoH_ref->[22]->{unit}, '75',
    'Unit Number of last read item is correct');
is( $lw4_item_info_AoH_ref->[22]->{watts}, '750',
    'Wattage of last read item is correct');
is( $lw4_item_info_AoH_ref->[22]->{circuit}, '50',
    'Circuit Number of last read item is correct');
is( $lw4_item_info_AoH_ref->[22]->{purpose}, 'Test 2',
    'Purpose of last read item is correct');
is( $lw4_item_info_AoH_ref->[22]->{position}, '3E',
    'Position of last read item is correct');
is( $lw4_item_info_AoH_ref->[22]->{color}, 'R 02',
    'Color of last read item is correct');
is( $lw4_item_info_AoH_ref->[22]->{type}, 'S4 PARNel, WFL',
    'Instrument type of last read item is correct');
is( $lw4_item_info_AoH_ref->[22]->{pattern}, '',
    'Template of last read item is correct');
is( $lw4_item_info_AoH_ref->[22]->{item_key}, '1382023192',
    'Item key of last read item is correct');


