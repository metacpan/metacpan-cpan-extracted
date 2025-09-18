use warnings;
use strict;

use Test::More tests => 13;
use Config;

my $perl = $Config{perlpath};

# bufrresolve.pl uses [BD]0000000000000023000 as default, but this is not included in bt/
my $bt = 'B0000000000098013001';

my $output = `$perl ./bufrresolve.pl 307080 --tablepath t/bt --bufrtable $bt`;
my $expected = read_file( 't/307080.table' ) ;
is($output, $expected, 'testing bufrresolve.pl on D descriptor');

$output = `$perl ./bufrresolve.pl --partial 307080 --tablepath t/bt -b $bt`;
$expected = read_file( 't/307080.partial' ) ;
is($output, $expected, 'testing bufrresolve.pl -p on D descriptor');

$output = `$perl ./bufrresolve.pl --simple 307080 --tablepath t/bt -b $bt`;
$expected = read_file( 't/307080.simple' ) ;
is($output, $expected, 'testing bufrresolve.pl -s on D descriptor');

$output = `$perl ./bufrresolve.pl --noexpand 301001 301011 301012 301022 002003 106000 031001 007007 011001 011002 033002 011006 033002 --tablepath t/bt -b $bt`;
$expected = read_file( 't/noexpand.txt' ) ;
is($output, $expected, 'testing bufrresolve.pl -n on descriptor sequence');

$output = `$perl ./bufrresolve.pl --code 020022 --tablepath t/bt -b $bt`;
$expected = read_file( 't/codetable.txt' ) ;
is($output, $expected, 'testing bufrresolve.pl -c on code table');

$output = `$perl ./bufrresolve.pl --code 020021 --flag 573440 --tablepath t/bt -b $bt`;
$expected = read_file( 't/flag.txt' ) ;
is($output, $expected, 'testing bufrresolve.pl -c -f on flag table');

$output = `$perl ./bufrresolve.pl --code 008042 --flag 3 --tablepath t/bt -b $bt`;
$expected = read_file( 't/illegal_flag.txt' ) ;
is($output, $expected, 'testing bufrresolve.pl -c -f on illegal flag');




# Testing of extracting table information for methods not included
# in bufrresolve.pl

use Geo::BUFR;
Geo::BUFR->set_tablepath('t/bt');
my $bufr = Geo::BUFR->new();
$bufr->load_BDtables('B0000000000098013001');

my ($name, $unit, $scale, $refval, $width) =
    $bufr->element_descriptor('12101');
is($width, '16', 'testing element_descriptor for width');

my $string = $bufr->sequence_descriptor('301013');
is($string, '004004 004005 004006', 'testing sequence_descriptor in scalar context');

my @desc = $bufr->sequence_descriptor('301013');
is($desc[2],'004006','testing sequence_descriptor in array context');

my $res = $bufr->element_descriptor('11111') ? 1 : 0;
is($res,0,'testing for non_existent element descriptor');

$res = $bufr->sequence_descriptor('333333') ? 1 : 0;
is($res,0,'testing for non_existent sequence descriptor');

$res = $bufr->dump_codetable(12101,'C0000000000098013001') ? 1 : 0;
is($res,0,'testing dump_codetable for non_existent code table');


# Read in text file
sub read_file {
    my $infile = shift;
    local $/; # Enable slurp mode
    open my $fh, '<', $infile or die "Can't open $infile: $!";
    return <$fh>;
};
