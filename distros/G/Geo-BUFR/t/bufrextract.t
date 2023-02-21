use warnings;
use strict;

use Test::More tests => 8;
use Config;

my $perl = $Config{perlpath};

# The bufr file t/set_filter.bufr starts with a GTS bulletin
# containing 3 BUFR messages, where only the first one have AHL and
# the second one is corrupt. Then 3 normal GTS bulletins, then a
# corrrupt GTS bulletin, then lastly one GTS bulletin containing 2
# BUFR messages with different AHls

my $output = `$perl ./bufrextract.pl t/set_filter.bufr --only_ahl`;
my $expected = read_file('t/extract.txt1') ;
is($output, $expected, 'testing bufrextract.pl --only_ahl');

$output = `$perl ./bufrextract.pl t/set_filter.bufr --only_ahl --ahl "^I..... (SVVS|ENMI)"`;
$expected = read_file('t/extract.txt2') ;
is($output, $expected, 'testing bufrextract.pl --only_ahl --ahl');

`$perl ./bufrextract.pl t/set_filter.bufr --outfile t/outext1`;
$output = read_binary_file('t/outext1');
unlink 't/outext1';
$expected = read_binary_file('t/extract.bufr') ;
is($output, $expected, 'testing bufrextract.pl --outfile');

# Note that the last gts bulletin in set_filter.bufr contains 2 BUFR
# messages with separate ahls. This test will write that as 2 separate
# gts bulletins, with the same csn. Not sure what we really want to do
# in a case like this...
`$perl ./bufrextract.pl t/set_filter.bufr --outfile t/outext1_gts --gts`;
$output = read_binary_file('t/outext1_gts');
unlink 't/outext1_gts';
$expected = read_binary_file('t/extract.bufr_gts') ;
is($output, $expected, 'testing bufrextract.pl --gts');

`$perl ./bufrextract.pl t/set_filter.bufr --outfile t/outext2 --ahl "^I..... (SVVS|ENMI)"`;
$output = read_binary_file('t/outext2');
unlink 't/outext2';
$expected = read_binary_file('t/extract.bufr1') ;
is($output, $expected, 'testing bufrextract.pl --ahl');

`$perl ./bufrextract.pl t/set_filter.bufr --outfile t/outext2_gts --gts --ahl "^I..... (SVVS|ENMI)"`;
$output = read_binary_file('t/outext2_gts');
unlink 't/outext2_gts';
$expected = read_binary_file('t/extract.bufr1_gts') ;
is($output, $expected, 'testing bufrextract.pl --ahl --gts');

`$perl ./bufrextract.pl t/set_filter.bufr --outfile t/outext5 --without_ahl`;
$output = read_binary_file('t/outext5');
unlink 't/outext5';
$expected = read_binary_file('t/extract.bufr3') ;
is($output, $expected, 'testing bufrextract.pl --without_ahl');




# Testing of extraction of BUFR messages (with ahls) given as argument
# to new() instead of read from file

use Geo::BUFR;

my $infile = 't/set_filter.bufr';
my $outfile = 't/outext20';
open my $OUT, '>', $outfile || die "Cannot open $outfile: $!";
binmode($OUT);
my $binary = read_binary_file($infile);

# No need to decode section 4 here
Geo::BUFR->set_nodata(1);
my $bufr = Geo::BUFR->new($binary);
READLOOP:
while (not $bufr->eof()) {
    eval {
        $bufr->next_observation();
    };
    if ($@) {
        next READLOOP;
    }
    next READLOOP if $bufr->bad_bufrlength();
    last READLOOP if $bufr->get_current_subset_number() == 0;
    my $msg = $bufr->get_bufr_message();
    my $current_ahl = $bufr->get_current_ahl() || '';
    print $OUT $current_ahl . "\r\r\n" if $current_ahl;
    print $OUT $msg;
}
close($OUT); # necessary, or else make test fails
$output = read_binary_file('t/outext20');
unlink 't/outext20';
$expected = read_binary_file('t/extract.bufr') ;
is($output, $expected, 'testing extraction of BUFR messages given as argument to new()');


# Read in binary file
sub read_binary_file {
    my $infile = shift;
    local $/; # Enable slurp mode
    open my $fh, '<', $infile or die "Can't open $infile: $!";
    binmode($fh);
    return <$fh>;
};

# Read in text file
sub read_file {
    my $infile = shift;
    local $/; # Enable slurp mode
    open my $fh, '<', $infile or die "Can't open $infile: $!";
    return <$fh>;
};
