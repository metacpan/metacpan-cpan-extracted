#!/usr/bin/perl
# vim: set ft=perl:

use strict;
use Test::More;

use FindBin qw($Bin);
use File::Find::Rule::TTMETA;
use File::Spec::Functions qw(catfile);

plan tests => 3;

my @files;
my $dir = -d catfile($Bin, 't') ? catfile($Bin, 't', 'data')
                                : catfile($Bin, 'data');

@files = find(ttmeta => { author => qr/d[ae]r*[ae]n/ }, in => $dir);
is(scalar @files, 2, "author => qr/d[ae]r*[ae]n/");

@files = find(ttmeta => { shoe_size => qr'[\d /]+' } => in => $dir);
is(scalar @files, 1, "shoe_size => qr'[\d /]+'");

@files = find(ttmeta => { shoe_size => qr(a-z+) } => in => $dir);
is(scalar @files, 0, "shoe_size => qr(a-z+) }");

