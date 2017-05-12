use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
plan 'no_plan';

require_ok 'FusqlFS::Cache::File';
our $_tcls = 'FusqlFS::Cache::File';

#=begin testing
{
my $_tname = '';
my $_tcount = undef;

#!noinst

ok FusqlFS::Cache::File->is_needed(10), 'File cache is needed';
ok !FusqlFS::Cache::File->is_needed(0), 'File cache isn\'t needed';
}


#=begin testing
{
my $_tname = '';
my $_tcount = undef;

# Tie tests
my %cache;
isa_ok tie(%cache, 'FusqlFS::Cache::File', 10), 'FusqlFS::Cache::File', 'File cache tied';

ok !scalar(%cache), 'Cache is empty';

# Store & fetch tests
$cache{'shorttest'} = [ 'pkg', 'names', 'entry' ];
$cache{'longtest'}  = [ 'pkg', 'names', 'long entry' ];

# Exists tests
is_deeply $cache{'shorttest'}, [ 'pkg', 'names', 'entry' ], 'Fetch short entry';
is_deeply $cache{'longtest'} , [ 'pkg', 'names', 'long entry' ], 'Fetch long entry';
is $cache{'unknown'}, undef, 'Unknown entry is undef';

ok scalar(%cache), 'Cache is not empty';

# Rewrite store tests
$cache{'shorttest'} = [ 'pkg', 'names', 'entri' ];
$cache{'longtest'}  = [ 'pkg', 'names', 'very long entry' ];
is_deeply $cache{'shorttest'}, [ 'pkg', 'names', 'entri' ], 'Fetch short entry after rewrite';
is_deeply $cache{'longtest'} , [ 'pkg', 'names', 'very long entry' ], 'Fetch long entry after rewrite';

# Iterate tests
while (my ($key, $val) = each %cache)
{
    if ($key eq 'shorttest')
    {
        is_deeply $val, [ 'pkg', 'names', 'entri' ], 'Fetch short entry (iterating)';
    }
    elsif ($key eq 'longtest')
    {
        is_deeply $val, [ 'pkg', 'names', 'very long entry' ], 'Fetch long entry (iterating)';
    }
    else
    {
        fail "Key-value pair not stored before: $key => $val";
    }
}

# Delete & clear tests
delete $cache{'shorttest'};
ok !exists($cache{'shorttest'}), 'Short entry deleted';
is $cache{'shorttest'}, undef, 'Short entry undefined';

delete $cache{'longtest'};
ok !exists($cache{'longtest'}), 'Long entry deleted';
is $cache{'longtest'}, undef, 'Long entry undefined';

ok !scalar(%cache), 'Cache is empty after delete';

$cache{'othertest'} = [ 'pkg', 'names', '' ];
%cache = ();
ok !scalar(%cache), 'Cache is empty after cleanup';
}

1;