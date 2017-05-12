use warnings;
use strict;

use Test::More tests => 16;
use Config;

my $perl = $Config{perlpath};

`$perl ./bufr_reencode.pl t/1xBUFRSYNOP-ed4.txt -t t/bt --outfile t/outree1`;
my $output = read_binary_file('t/outree1');
unlink 't/outree1';
my $expected = read_binary_file('t/1xBUFRSYNOP-ed4.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on BUFR SYNOP edition 4');

$output = `$perl ./bufr_reencode.pl t/3xBUFRSYNOP-com.txt -t t/bt`;
$expected = read_binary_file('t/3xBUFRSYNOP-com.bufr');
is($output, $expected, 'testing bufr_reencode.pl on 3 compressed BUFR SYNOP edition 4');

$output = `$perl ./bufr_reencode.pl t/substituted.txt -t t/bt`;
$expected = read_binary_file('t/substituted.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on BUFR file with substituted values');

$output = `$perl ./bufr_reencode.pl t/change_refval.txt -t t/bt`;
$expected = read_binary_file('t/change_refval.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on BUFR file with 203Y');

$output = `$perl ./bufr_reencode.pl t/change_refval_compressed.txt -t t/bt`;
$expected = read_binary_file('t/change_refval_compressed.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on BUFR file with 203Y (compressed)');

$output = `$perl ./bufr_reencode.pl t/207003.txt -t t/bt`;
$expected = read_binary_file('t/207003.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on BUFR file with 207Y');

$output = `$perl ./bufr_reencode.pl t/207003_compressed.txt -t t/bt`;
$expected = read_binary_file('t/207003_compressed.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on BUFR file with 207Y (compressed)');

$output = `$perl ./bufr_reencode.pl t/208035.txt -w 35 -t t/bt`;
$expected = read_binary_file('t/208035.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on BUFR file with 208Y');

$output = `$perl ./bufr_reencode.pl t/delayed_repetition.txt -t t/bt`;
$expected = read_binary_file('t/delayed_repetition.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on BUFR file with 030011');

$output = `$perl ./bufr_reencode.pl t/delayed_repetition_compressed.txt -t t/bt`;
$expected = read_binary_file('t/delayed_repetition_compressed.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on BUFR file with 030011 (compressed)');

$output = `$perl ./bufr_reencode.pl t/multiple_qc.txt -t t/bt`;
$expected = read_binary_file('t/multiple_qc.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on BUFR file with triple 222000');

$output = `$perl ./bufr_reencode.pl t/multiple_qc_compressed.txt -t t/bt`;
$expected = read_binary_file('t/multiple_qc_compressed.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on BUFR file with triple 222000 (compressed)');

$output = `$perl ./bufr_reencode.pl t/multiple_qc_vary.txt -t t/bt`;
$expected = read_binary_file('t/multiple_qc_vary.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on BUFR file with triple 222000 and varying bitmaps');

$output = `$perl ./bufr_reencode.pl t/firstorderstat.txt -t t/bt`;
$expected = read_binary_file('t/firstorderstat.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on compressed BUFR file with first order statistics (224000)');

$output = `$perl ./bufr_reencode.pl t/retained.txt -t t/bt`;
$expected = read_binary_file('t/retained.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on BUFR file with resolved/retained values');

$output = `$perl ./bufr_reencode.pl t/signify_datawidth.txt -t t/bt`;
$expected = read_binary_file('t/signify_datawidth.bufr');
is($output, $expected, 'testing bufr_reencode.pl -o on BUFR file with 206YYY signify data width operator');


# Read in binary file
sub read_binary_file {
    my $infile = shift;
    local $/; # Enable slurp mode
    open my $fh, '<', $infile or die "Can't open $infile: $!";
    binmode($fh);
    return <$fh>;
};
    