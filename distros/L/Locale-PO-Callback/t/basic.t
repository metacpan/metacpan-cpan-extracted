#!/usr/bin/perl

# Maintainer:
# Run this with PREPARE=1 in the environment
# to produce the file t/evolution.en@shaw.po.pl
# which will be the results that subsequent runs
# are checked against.
# This file SHOULD be shipped.

use strict;
use warnings;
use Locale::PO::Callback;
use Test::More;

my $filename = 't/demo.po';

my $results = [];

sub callback {
    my ($arg) = @_;
    push @$results, $arg;
}

sub prepare {
    use Data::Dumper;
    open PREPARE, ">$filename.pl" or die "Couldn't open prepare file: $!";
    print PREPARE Dumper($results);
    close PREPARE or die "Couldn't close prepare file: $!";
}

sub test {
    die "Please run with PREPARE=1 to create prepare file first.\n" unless -e "$filename.pl";
    my $prepared = do "$filename.pl";

    plan tests => scalar(@$prepared);

    my $count = 0;
    for (@$prepared) {
	$count++;
	is_deeply (shift @$results, $_, "PO stanza $count");
    }
}

my $po = Locale::PO::Callback->new(\&callback);
$po->read($filename);

if (defined $ENV{'PREPARE'}) {
    prepare();
} else {
    test();
}
