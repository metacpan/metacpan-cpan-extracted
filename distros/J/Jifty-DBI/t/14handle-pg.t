# Test methods in Jifty::DBI::Handle::Pg

use strict;
use warnings;

use Test::More tests => 2;

my $package;
BEGIN {
    $package = 'Jifty::DBI::Handle::Pg';
    use_ok($package);
}
use Jifty::DBI::Collection;

package Foo::Bar::Collection;
our @ISA = 'Jifty::DBI::Collection';

sub query_columns { "blah" }
sub table { "bars" }

package main;

{
    # Test sub distinct_query
    my $collection = bless {
        order_by => [
          {
            alias  => 'main',
            column => 'id',
            order  => 'asc',
          },
          {
            alias  => 'main',
            column => 'name',
            order  => 'desc',
          },
          {
            alias  => 'foo',
            column => 'id',
            order  => 'desc',
          },
          {
            alias  => 'foo',
            column => 'name',
            order  => 'desc',
          },
          {
            alias  => '',
            column => 'id',
            order  => 'ASC',
          },
          {
            alias  => undef,
            column => 'blood',
            order  => 'ASC'
          },
          {
            column => 'session_offset',
            order  => 'asc'
          },
        ],
    }, 'Foo::Bar::Collection';
    my $stmt = 'select * from users';
    $package->distinct_query(\$stmt, $collection);
    is $stmt,
       'SELECT blah FROM ( SELECT main.id FROM select * from users  GROUP BY main.id'
       . '   ORDER BY main.id ASC, MAX(main.name) DESC, MAX(foo.id) DESC, '
       . 'MAX(foo.name) DESC, id ASC, MIN(blood) ASC, MIN(session_offset) ASC  ) '
       . 'distinctquery, bars main WHERE (main.id = distinctquery.id)',
       'distinct_query works';
}
