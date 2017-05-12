#! /usr/bin/perl -w
#

use ExtUtils::testlib;	# so that we find Digest::FP56x1xor here without installing it.
use Digest::FP56x1xor qw(gen_l cat_l gen cat x2l l2x);
use Data::Dumper;

my $t1 = shift || "@";
my $h1 = gen($t1);
my $t2 = shift || '1';
my $h2 = gen($t2);

print Dumper $t1, $h1, length($t1),
           $t2, $h2, length($t2),
	   cat($h1,$h2), gen($t1.$t2);
