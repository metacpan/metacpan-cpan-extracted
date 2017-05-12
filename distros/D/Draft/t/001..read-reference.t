#!/usr/bin/perl

use lib qw (. lib);

use Test;
BEGIN { plan tests => 4 };

use Draft;

use Draft::Protozoa::Eml;
print "ok 1\n";

my $filename2 = 't/data/arrow.eml';
my $ref2 = Draft::Protozoa::Eml->new ($filename2);
$ref2->Read;
print "ok 2\n" if $ref2->{_path} eq $filename2;

my $filename3 = 't/data/arrow.eml';
my $ref3 = Draft::Protozoa::Eml->new ($filename3);
print "ok 3\n" if $ref3->{_path} eq $filename3;

$ref3->Read;
$ref3->Process;
print "ok 4\n" if $ref3->{location}->[0] =~ "t/data/arrow.drawing/|../data/arrow.drawing/";

