#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/mixed.tar";

my $w = File::Raw::Archive->create($tar);
for my $i (1 .. 20) {
    $w->add(name => "file$i.csv", content => "csv,$i\n");
    $w->add(name => "file$i.bin", content => pack('N*', 0xdeadbeef, $i));
}
$w->close;

# entry_filter only matching .csv
my @hits;
File::Raw::Archive->each($tar,
    entry_filter => sub { my $e = shift; $e->name =~ /\.csv$/ },
    sub { push @hits, $_[0]->name });

is(scalar @hits, 20, 'filter saw 20 .csv entries');
is(scalar(grep { /\.csv$/ } @hits), 20, 'all hits are .csv');
is(scalar(grep { /\.bin$/ } @hits), 0, 'no .bin entries leaked through');

# list works alongside filter (list ignores filter though, by design)
my $rows = File::Raw::Archive->list($tar);
is(scalar @$rows, 40, 'list returned all 40 entries (filter is each-only)');

done_testing;
