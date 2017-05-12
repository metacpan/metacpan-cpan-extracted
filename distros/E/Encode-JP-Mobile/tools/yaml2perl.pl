#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use YAML;
use FindBin;
use File::Spec::Functions;

$Data::Dumper::Terse++;

die "Usage: $0 hoge.yaml hoge.pl" unless @ARGV==2;
my ($src, $dst) = @ARGV;

open my $fh, '>', $dst or die $!;
print $fh Dumper(YAML::LoadFile($src));
close $fh;

