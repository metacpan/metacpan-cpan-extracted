use Test::More;

#
# Basically the same as watch.t but with 'use strict;'
#  (follow a bug spotted by Yann KEHERVE)
#
use strict;

use vars qw($TESTS);

BEGIN {
	$TESTS = 12;
	plan tests => $TESTS;
}

#use Devel::StealthDebug (SOURCE=>"./strict.rst2", emit_type=>'print');
use Devel::StealthDebug;
use File::Temp "tempfile";

close STDERR;
my ($fh,$fn)= tempfile() or die $!;
open (STDERR, "> $fn") or die $!;

my %testhash;
#!watch(%testhash)!
my @testarray;#!watch(@testarray)!
my $testscalar;#!watch($testscalar)!
my $dummy;

$testhash{test1} = 1;
$testhash{test1}++;
$dummy = $testhash{test1} ;

$testarray[1] = 1;
$testarray[1]++;
$dummy = $testarray[1];

$testscalar = 1;
$testscalar++;
$dummy = $testscalar;

close STDERR;

open (STDIN,"< $fn");
my ($out,$check);
for (1..$TESTS) {
	$out=<STDIN>;
	$check=<DATA>;
	chomp $check;
	$check=quotemeta($check);
	like($out, qr/$check/);
}
__DATA__
STORE (%testhash{test1} <- 1)
FETCH (%testhash{test1} -> 1)
STORE (%testhash{test1} <- 2)
FETCH (%testhash{test1} -> 2)
STORE (@testarray[1] <- 1)
FETCH (@testarray[1] -> 1)
STORE (@testarray[1] <- 2)
FETCH (@testarray[1] -> 2)
STORE ($testscalar <- 1)
FETCH ($testscalar -> 1)
STORE ($testscalar <- 2)
FETCH ($testscalar -> 2)
