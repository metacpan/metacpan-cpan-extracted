#!/usr/bin/env perl

use strict;
use warnings;
use lib 'lib';
use File::Spec::Functions;
#use Test::More tests => 1000000;
use Test::More;
print "1..1000000\n";
use Math::Primality qw/ is_prime /;
$|++; #flush the output buffer after every write() or print() function

my $bail = <<BAIL;

You must download and unzip the file primes1.zip from http://primes.utm.edu/lists/small/millions/
and put it in the xt/ directory to run this test.  The file contains the first
one million primes and is 1.7MB, 10 MB uncompressed.

Example commands to get this data:

cd xt/
wget http://primes.utm.edu/lists/small/millions/primes1.zip
unzip primes1.zip

BAIL

my $filename = catfile(qw/xt primes1.txt/);

open my $fh, '<', $filename or bail();

sub bail
{
    diag $bail;
    exit(1);
}

sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

my $t = 1;
while(<$fh>) {
    chomp;
    if ($_ =~ m/[a-zA-Z]/ || $_ =~ m/^\s*$/ ) {
      next;
    }
    my @line = split(' ', $_);
    foreach my $num (@line) {
      print is_prime( $num ) ? "ok $t - $num is a prime\n" : "not ok $t - $num is a prime\n";
      $t++;
    }
}



close $fh;
