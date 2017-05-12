use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
plan 'no_plan';

require_ok 'FusqlFS::Cache::Limited';
our $_tcls = 'FusqlFS::Cache::Limited';

#=begin testing
{
my $_tname = '';
my $_tcount = undef;

#!noinst

ok FusqlFS::Cache::Limited->is_needed(10), 'Limited cache is needed';
ok !FusqlFS::Cache::Limited->is_needed(0), 'Limited cache isn\'t needed';
}


#=begin testing
{
my $_tname = '';
my $_tcount = undef;

my %cache;
isa_ok tie(%cache, 'FusqlFS::Cache::Limited', 10), 'FusqlFS::Cache::Limited', 'Limited cache tied';

ok !scalar(%cache), 'Cache is empty';

foreach my $n (1..10)
{
    $cache{'test'.$n} = 'value'.$n;
}

ok scalar(%cache), 'Cache is not empty';

foreach my $n (1..10)
{
    ok exists($cache{'test'.$n}), 'Entry '.$n.' exists';
    is $cache{'test'.$n}, 'value'.$n, 'Entry '.$n.' is intact';
}

ok exists($cache{'test10'}), 'Element exists before deletion';
delete $cache{'test10'};
ok !exists($cache{'test10'}), 'Deleted element doesn\'t exist';
is $cache{'test10'}, undef, 'Deleted element is undefined';

%cache = ();

ok !scalar(%cache), 'Cache is empty after cleanup';

foreach my $n (1..1000)
{
    $cache{'test'.$n} = 'value'.$n;
    foreach my $m (1..1000-$n)
    {
        my $x = $cache{'test'.$n};
    }
}

ok exists($cache{'test1'}), 'Most used element exists';
is $cache{'test1'}, 'value1', 'Most used element is intact';
ok !exists($cache{'test999'}), 'Least used element doesn\'t exist';
is $cache{'test999'}, undef, 'Least used element undefined';
cmp_ok length(keys %cache), '<=', 10, 'Number of items in cache doesn\'t exceed given threshold';

while (my ($key, $val) = each %cache)
{
    like $key, qr/^test[0-9]+$/, 'Iterate: key is '.$key.' intact';
    like $val, qr/^value[0-9]+$/, 'Iterate: value is '.$val.' intact';
    is substr($key, 4), substr($val, 5), 'Iterate: key matches value';
}
}

1;