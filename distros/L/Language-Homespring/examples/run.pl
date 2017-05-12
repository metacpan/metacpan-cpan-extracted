#!/usr/bin/perl -w

use strict;

use Language::Homespring;
use Data::Dumper;

my $filename = $ARGV[0];
die "please specify a file to read!\n" unless $filename;

open(F, $filename) or die "couldn't read file $filename: $!";
my $code = join '', <F>;
close(F);

my $hs = new Language::Homespring();
$hs->parse($code);

$hs->run(15, "---\n");

#print Dumper($hs->{root_node}, $hs->{salmon}, $hs->{new_salmon});
