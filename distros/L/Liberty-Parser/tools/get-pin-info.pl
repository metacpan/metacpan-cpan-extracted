#!/usr/bin/perl -w
use strict;
use Liberty::Parser;

my $i;
my $p = new Liberty::Parser;

my $file = shift;
my $cell = shift;
my $pin = shift;

my $g = $p->read_file($file);
my $gc = $p->locate_group($g,$cell);
my $gp = $p->locate_group($gc,$pin);
print $p->extract_group($gp,"");
