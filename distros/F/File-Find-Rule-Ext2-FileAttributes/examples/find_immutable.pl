#!/usr/bin/perl -w
use strict;
use warnings;
use File::Find::Rule::Ext2::FileAttributes;

my $basedir = shift;
die "Please supply a basedir\n" unless $basedir;

my @immutable = File::Find::Rule->immutable->in( $basedir );

print "@immutable\n";
