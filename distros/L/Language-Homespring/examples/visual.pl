#!/usr/bin/perl -w

use strict;

use Language::Homespring;
use Language::Homespring::Visualise;

my $filename = $ARGV[0];
die "please specify a file to read!\n" unless $filename;

open(F, $filename) or die "couldn't read file $filename: $!";
my $code = join '', <F>;
close(F);

my $hs = new Language::Homespring();
$hs->parse($code);

my $vs = new Language::Homespring::Visualise({'interp' => $hs});
print $vs->do();
