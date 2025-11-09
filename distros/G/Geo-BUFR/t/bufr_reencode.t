use warnings;
use strict;

use Test::More tests => 17;
use Config;

my $perl = $Config{perlpath};

`$perl ./bufr_reencode.pl t/1xBUFRSYNOP-ed4.txt --tablepath t/bt --outfile t/outree1`;
my $output = read_binary_file('t/outree1');
unlink 't/outree1';
my $expected = read_binary_file('t/1xBUFRSYNOP-ed4.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on BUFR SYNOP edition 4');

$output = `$perl ./bufr_reencode.pl t/3xBUFRSYNOP-com.txt --tablepath t/bt`;
$expected = read_binary_file('t/3xBUFRSYNOP-com.bufr');
is($output, $expected, 'testing bufr_reencode.pl on 3 compressed BUFR SYNOP edition 4');

$output = `$perl ./bufr_reencode.pl t/substituted.txt --tablepath t/bt`;
$expected = read_binary_file('t/substituted.bufr');
is($output, $expected, 'testing bufr_reencode.pl on BUFR file with substituted values');

$output = `$perl ./bufr_reencode.pl t/change_refval.txt --tablepath t/bt`;
$expected = read_binary_file('t/change_refval.bufr');
is($output, $expected, 'testing bufr_reencode.pl on BUFR file with 203 change reference values operator');

$output = `$perl ./bufr_reencode.pl t/change_refval_compressed.txt --tablepath t/bt`;
$expected = read_binary_file('t/change_refval_compressed.bufr');
is($output, $expected, 'testing bufr_reencode.pl on BUFR file with 203 operator (compressed)');

$output = `$perl ./bufr_reencode.pl t/207003.txt --tablepath t/bt`;
$expected = read_binary_file('t/207003.bufr');
is($output, $expected, 'testing bufr_reencode.pl on BUFR file with 207 increase scale, reference value and data width operator');

$output = `$perl ./bufr_reencode.pl t/207003_compressed.txt --tablepath t/bt`;
$expected = read_binary_file('t/207003_compressed.bufr');
is($output, $expected, 'testing bufr_reencode.pl on BUFR file with 207 operator (compressed)');

$output = `$perl ./bufr_reencode.pl t/208035.txt -w 35 --tablepath t/bt`;
$expected = read_binary_file('t/208035.bufr');
is($output, $expected, 'testing bufr_reencode.pl on BUFR file with 208 change width of ccitt ia5 field operator');

$output = `$perl ./bufr_reencode.pl t/delayed_repetition.txt --tablepath t/bt`;
$expected = read_binary_file('t/delayed_repetition.bufr');
is($output, $expected, 'testing bufr_reencode.pl on BUFR file with 030011');

$output = `$perl ./bufr_reencode.pl t/delayed_repetition_compressed.txt --tablepath t/bt`;
$expected = read_binary_file('t/delayed_repetition_compressed.bufr');
is($output, $expected, 'testing bufr_reencode.pl on BUFR file with 030011 (compressed)');

$output = `$perl ./bufr_reencode.pl t/multiple_qc.txt --tablepath t/bt`;
$expected = read_binary_file('t/multiple_qc.bufr');
is($output, $expected, 'testing bufr_reencode.pl on BUFR file with triple 222000');

$output = `$perl ./bufr_reencode.pl t/multiple_qc_compressed.txt --tablepath t/bt`;
$expected = read_binary_file('t/multiple_qc_compressed.bufr');
is($output, $expected, 'testing bufr_reencode.pl on BUFR file with triple 222000 (compressed)');

$output = `$perl ./bufr_reencode.pl t/multiple_qc_vary.txt --tablepath t/bt`;
$expected = read_binary_file('t/multiple_qc_vary.bufr');
is($output, $expected, 'testing bufr_reencode.pl on BUFR file with triple 222000 and varying bitmaps');

$output = `$perl ./bufr_reencode.pl t/firstorderstat.txt --tablepath t/bt`;
$expected = read_binary_file('t/firstorderstat.bufr');
is($output, $expected, 'testing bufr_reencode.pl on compressed BUFR file with first order statistics (224000)');

$output = `$perl ./bufr_reencode.pl t/retained.txt --tablepath t/bt`;
$expected = read_binary_file('t/retained.bufr');
is($output, $expected, 'testing bufr_reencode.pl on BUFR file with resolved/retained values');

$output = `$perl ./bufr_reencode.pl t/signify_datawidth.txt --tablepath t/bt`;
$expected = read_binary_file('t/signify_datawidth.bufr');
is($output, $expected, 'testing bufr_reencode.pl on BUFR file with 206 signify data width operator');

$output = `$perl ./bufr_reencode.pl t/38bitswidth.txt --tablepath t/bt`;
$expected = read_binary_file('t/38bitswidth.bufr');
is($output, $expected, 'testing bufr_reencode.pl on BUFR file with data width 38 bits caused by 201 change data width operator');


# Read in binary file
sub read_binary_file {
    my $infile = shift;
    local $/; # Enable slurp mode
    open my $fh, '<', $infile or die "Can't open $infile: $!";
    binmode($fh);
    return <$fh>;
};
    