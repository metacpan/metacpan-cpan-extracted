#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More;
use Lingua::IdSplitter;

my $splitter = Lingua::IdSplitter->new;

my %ids = (
    'time_sort'   => 'time,sort',
    '_time_sort'  => 'time,sort',
    'time_sort_'  => 'time,sort',
    '_time_sort_' => 'time,sort',
    'time___sort'   => 'time,sort',
    'TimeSort'   => 'time,sort',
    'timeSort'   => 'time,sort',
    'time-sort'   => 'time,sort',
    'time.sort'   => 'time,sort',
    'time::sort'   => 'time,sort',
  );

my $tests = 0;
foreach my $id (keys %ids) {
  my @result = $splitter->hard_split($id);
  @result = map {$_->{s}} @result;

  ok( join(',', @result) eq $ids{$id}, "$id -> $ids{$id}" );
  $tests++;
}

done_testing($tests);
