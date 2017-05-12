#!/usr/bin/env perl

use strict;
use warnings;
use lib 'lib';
use File::Spec::Functions;
#use Test::More tests => 1000000;
print "1..1000000\n";
use Math::Primality qw/ next_prime /;
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
my $previous = 0;
while(<$fh>) {
    chomp;
    if ($_ =~ m/[a-zA-Z]/ || $_ =~ m/^\s*$/ ) {
      next;
    }
    my @line = split(' ', $_);
    for (my $i = 0; $i < scalar(@line); $i++) {
      if ($i != scalar(@line)) {
        print next_prime( $previous ) == $line[$i]  ? "ok $t - next prime after $previous is $line[$i]\n" : "not ok $t - next prime after $previous is $line[$i]\n";
      }
      $previous = $line[$i];
      $t++;
    }
}



close $fh;
