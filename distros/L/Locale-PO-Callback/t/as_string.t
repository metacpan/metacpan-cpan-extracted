#!/usr/bin/perl

use strict;
use warnings;
use Locale::PO::Callback;
use File::Slurp;
use Test::More;

my $filename = 't/demo.po';

my $results = [];

sub callback {
    my ($arg) = @_;
    push @$results, $arg;
}

my $file = read_file($filename);
my $po = Locale::PO::Callback->new(\&callback);
$po->read_string($file);

my $prepared = do "$filename.pl";

plan tests => scalar(@$prepared);

my $count = 0;
for (@$prepared) {
    $count++;
    is_deeply (shift @$results, $_, "PO stanza $count from string");
}
