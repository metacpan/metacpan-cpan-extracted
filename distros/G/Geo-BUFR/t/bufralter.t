use warnings;
use strict;

use Test::More tests => 2;
use Config;

my $perl = $Config{perlpath};

my $cmnd = "$perl ./bufralter.pl t/1xBUFRSYNOP-ed4.bufr"
    . " --data 4005=10 --data 010004=missing --bufr_edition 3 --centre=88"
    . " --subcentre 9 --update_number -1 --category 9 --subcategory 8"
    . " --master_table_version=11 --local_table_version 0 --year 9"
    . " --month 8 --day 7 --hour 6 --minute 5"
    . " --outfile t/outalt1 -t t/bt";

`$cmnd`;
my $output = read_binary_file('t/outalt1');
unlink 't/outalt1';
my $expected = read_binary_file('t/1xBUFRSYNOP-ed4.bufr_altered');
is($output, $expected, 'testing bufralter.pl on BUFR SYNOP edition 4');

$cmnd = "$perl ./bufralter.pl t/3xBUFRSYNOP-com.bufr"
    . " --data 4005=10 --data 010004=missing --bufr_edition 4 --centre=88"
    . " --subcentre 9 --update_number 99 --category 9 --subcategory 8"
    . " --master_table_version=11 --local_table_version 0 --year 9"
    . " --month 8 --day 7 --hour 6 --minute 5 --observed 0 --compress 0"
    . " --outfile t/outalt2 -t t/bt";
`$cmnd`;
$output = read_binary_file('t/outalt2');
unlink 't/outalt2';
$expected = read_binary_file('t/3xBUFRSYNOP-com.bufr_altered');
is($output, $expected, 'testing bufralter.pl on BUFR SYNOP edition 3');


# Read in binary file
sub read_binary_file {
    my $infile = shift;
    local $/; # Enable slurp mode
    open my $fh, '<', $infile or die "Can't open $infile: $!";
    binmode($fh);
    return <$fh>;
};
