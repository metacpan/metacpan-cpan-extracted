#!/usr/bin/perl
# vim: set ft=perl:

use strict;
use Test::More;

use FindBin qw($Bin);
use File::Find::Rule::TTMETA;
use File::Spec::Functions qw(catfile);

plan tests => 5;

my @files;
my $dir = -d catfile($Bin, 't') ? catfile($Bin, 't', 'data')
                                : catfile($Bin, 'data');

@files = find(ttmeta => { } => in => $dir);
is(scalar @files, 0, "Empty query");

@files = find(ttmeta => { author => "darren chamberlain" }, in => $dir);
is(scalar @files, 2, "author => 'darren chamberlain'");

@files = find(ttmeta => { shoe_size => "10 1/2" } => in => $dir);
is(scalar @files, 1, "shoe_size => '10 1/2'");

@files = find(ttmeta => { description => "craptastic" } => in => $dir);
is(scalar @files, 0, "Non-existant query");

@files = find(ttmeta => { author => qr/(?i)DARREN CHAMBERLAIN/ },
              name => qr/\.tt$/,
              in => $dir);
is(scalar @files, 2, "Multiple query types");
