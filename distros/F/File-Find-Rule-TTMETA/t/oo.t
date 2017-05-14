#!/usr/bin/perl
# vim: set ft=perl:

use strict;
use Test::More;

use FindBin qw($Bin);
use File::Find::Rule qw(:TTMETA);
use File::Spec::Functions qw(catfile);

plan tests => 5;

my @files;
my $dir = -d catfile($Bin, 't') ? catfile($Bin, 't', 'data')
                                : catfile($Bin, 'data');

@files = File::Find::Rule->file->ttmeta->in($dir);
is(scalar @files, 0, "Empty query");

@files = File::Find::Rule->file->ttmeta(author => "darren chamberlain")->in($dir);
is(scalar @files, 2, "author => 'darren chamberlain'");

@files = File::Find::Rule->file->ttmeta(shoe_size => "10 1/2")->in($dir);
is(scalar @files, 1, "shoe_size => '10 1/2'");

@files = File::Find::Rule->file->ttmeta(author => "darren chamberlain",
                                         shoe_size => "10 1/2")->in($dir);
is(scalar @files, 1, "author and shoe_size");

@files = File::Find::Rule->file->ttmeta(description => "craptastic")->in($dir);
is(scalar @files, 0, "Non-existant query");

