#!perl

use strict;
use warnings;
use Test::More;
use MMapDB qw/:error/;

sub note; *note=sub {
  print '# '.join('', @_)."\n";
} unless defined &note;

my $ntests=7;

unlink 'tmpdb';			# make sure
unlink 'tmpdb.lock';		# make sure
die "Please move tmpdb out of the way!\n" if -e 'tmpdb';

my $d=MMapDB->new(filename=>"tmpdb");
$d->stringmap_prealloc=4096;

$d->start;
$d->begin();
is length(${$d->_stringmap}), 4096, 'stringmap length == 4096';
my $sort="AAAA";
for( my $i=0; $i<256; $i++ ) {
  $d->insert([[''], $sort++, chr($i)x7]);
}
is length(${$d->_stringmap}), 8192, 'stringmap length == 8192';
$d->insert([[''], $sort++, "X"x4097]);
$d->insert([[''], $sort++, "Y"x4097]);
is length(${$d->_stringmap}), 16384, 'stringmap length == 16384';
$d->commit;
is length(${$d->_data}), 23716, 'data length after commit == 23716';

$d->index_prealloc=4096;
$d->begin;
is length(${$d->_tmpmap}), 8192, 'tmpmap length == 8192';
$d->clear;
$d->commit;
$d->begin;
is length(${$d->_tmpmap}), 4096, 'tmpmap length == 4096';
my %k;
$sort="AAAA";
srand 42;
for( my $i=0; $i<1000; $i++ ) {
  my @k;
  push @k, pack("C*", map {65+int rand 5} 1..2) for (1..2);
  push @{$k{join '', @k}}, $i;
  $d->insert([\@k, $sort++, $i]);
}
cmp_ok length(${$d->_tmpmap}), '>', 4096, 'tmpmap length > 4096';
$d->commit;

for my $k (sort keys %k) {
  is_deeply [$d->index_lookup_values(0, $k=~/^(..)(..)/)], $k{$k},
    "lookup: $k";
  $ntests++;
  # warn("$k => [@{$k{$k}}] / ".
  #      "[@{[$d->index_lookup_values(0, $k=~/^(..)(..)/)]}]\n");
}

$d->stop;

done_testing $ntests;
