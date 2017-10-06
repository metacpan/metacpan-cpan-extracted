#!perl

use strict;
use warnings;
use Test::More;
use IO::AIO;
use IO::AIO::LoadLimited;

plan tests => 11;

my %data;
my @files = map { "t/data/" . $_ . ".txt" } (1..10);

aio_load_limited @files, sub {
    my ($file, $content) = @_;
    $data{$file} = $content ? $content : "coudnt read file: $!";
}, sub {
    pass "tests done";
}, 2;

IO::AIO::flush;

foreach my $file (sort keys %data) {
    if (my ($fileno) = $file =~ m/(\d+)\.txt$/) {
        is $fileno, $data{$file}, "$file matches content";
    } else {
        fail "filename looks odd: $file";
    }
}

done_testing;
