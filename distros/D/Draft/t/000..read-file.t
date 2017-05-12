#!/usr/bin/perl

use lib qw (. lib);

use Test;
BEGIN { plan tests => 3 };

use Draft::Protozoa::Eml;
print "ok 1\n";

my $filename = 't/data/e6f2adac9d4662b67505e78b4fae4022aaaa.eml';

my $line = Draft::Protozoa::Eml->new ($filename);
print "ok 2\n" if $line->{_path} eq $filename;

$line->Read;
print "ok 3\n" if $line->{1}->[1] eq "300";

