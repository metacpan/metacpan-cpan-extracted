use warnings;
use strict;

use Test::More tests => 7;
use Config;

my $perl = $Config{perlpath};

# Test using ecCodes tables

my $table_fp = '--tableformat ECCODES --tablepath t/et';

my $output = `$perl ./bufrread.pl t/local.bufr $table_fp -c`;
my $expected = read_file('t/local.txt_eccodes_c');
is($output, $expected, 'testing bufrread.pl -c --tableformat ECCODES');

$output = `$perl ./bufrresolve.pl -c 8198 $table_fp --bufrtable 0/local/8/78/236`;
$expected = read_file('t/local_table_8198.txt_eccodes');
is($output, $expected, 'testing bufrresolve.pl on local ECCODES code table');

$output = `$perl ./bufrresolve.pl 301193 $table_fp --bufrtable "0/wmo/13,0/local/8/78/236"`;
$expected = read_file('t/local_desc_301193.txt_eccodes');
is($output, $expected, 'testing bufrresolve.pl on local ECCODES sequence descriptor');

$output = `$perl ./bufrresolve.pl 2201 $table_fp --bufrtable 0/local/1/98/0/6`;
$expected = read_file('t/local_desc_2201.txt_eccodes');
is($output, $expected, 'testing bufrresolve.pl on local ECCODES element with no sequence.def');

$output = `$perl ./bufrencode.pl --data t/307080.data --metadata t/metadata.txt_ed4 $table_fp`;
$expected = read_binary_file('t/encoded_ed4') ;
is($output, $expected, 'testing bufrencode.pl --tableformat ECCODES');

$output = `$perl ./bufr_reencode.pl t/local.txt_eccodes $table_fp`;
$expected = read_binary_file('t/local.bufr');
is($output, $expected, 'testing bufr_reencode.pl --tableformat ECCODES');

# Differ from test in bufralter.t in that one line of changes is commented out
# (then don't need those extra eccodes tables)
my $cmnd = "$perl ./bufralter.pl t/1xBUFRSYNOP-ed4.bufr"
    . " --data 4005=10 --data 010004=missing --bufr_edition 3 --centre=88"
    . " --subcentre 9 --update_number -1 --category 9 --subcategory 8"
#    . " --master_table_version=11 --local_table_version 0 --year 9"
    . " --month 8 --day 7 --hour 6 --minute 5"
    . " --outfile t/outalt_eccodes $table_fp";

`$cmnd`;
$output = read_binary_file('t/outalt_eccodes');
unlink 't/outalt_eccodes';
$expected = read_binary_file('t/1xBUFRSYNOP-ed4.bufr_altered_eccodes');
is($output, $expected, 'testing bufralter.pl --tableformat ECCODES');




# Read in text file
sub read_file {
    my $infile = shift;
    local $/; # Enable slurp mode
    open my $fh, '<', $infile or die "Can't open $infile: $!";
    return <$fh>;
};

# Read in binary file
sub read_binary_file {
    my $infile = shift;
    local $/; # Enable slurp mode
    open my $fh, '<', $infile or die "Can't open $infile: $!";
    binmode($fh);
    return <$fh>;
};
