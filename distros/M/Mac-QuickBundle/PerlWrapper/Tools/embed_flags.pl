#!/usr/bin/perl -w

# outputs the embedding flags stripping -arch options, to allow
# compiling for a different set of architectures

use strict;
use ExtUtils::Embed;

my $ccopts = ccopts;
my $ldopts = ldopts;

$ccopts =~ s/(?:^|\s)-arch\s+\S+/ /g;
$ldopts =~ s/(?:^|\s)-arch\s+\S+/ /g;
$ldopts =~ s/(?:^|\s)-lutil(?=\s|$)/ /g;

print "$ccopts $ldopts";
