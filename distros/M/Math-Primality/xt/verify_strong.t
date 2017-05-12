#!/usr/bin/env perl

use strict;
use warnings;
use lib 'lib';
use File::Spec::Functions;
#use Test::More tests => 419489;
print "1..419489\n";
use Math::Primality qw/ is_strong_pseudoprime /;
$|++;

my $bail = <<BAIL;

You must download and unzip the file spsp_base2_1e15.txt.gz from
http://leto.net/data/primality and put it in the xt/ directory to run these
tests. The file contains just under 420,000 integers and is 2.7MB, 6MB
uncompressed.

Example commands to get this data:

cd xt/
wget http://leto.net/data/primality/spsp_base2_1e15.txt.gz
gunzip spsp_base2_1e15.txt.gz

BAIL

my $filename = catfile(qw/xt spsp_base2_1e15.txt/);

open my $fh, '<', $filename or bail();

sub bail
{
    diag $bail;
    exit(1);
}

my $t = 1;
while(<$fh>) {
    chomp;
    print is_strong_pseudoprime( $_ ) ? "ok $t - $_ is a spsp(2)\n" : "not ok $t - $_ is a spsp(2)\n";
    $t++;
}

close $fh;
