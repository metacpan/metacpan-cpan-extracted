#!/usr/bin/env perl

use strict;
use warnings;

use Scalar::Util qw(refaddr);
use Test::More;
use Test::Exception;
use Search::GIN::Query::Set;
use Search::GIN::Query::Manual;
use Search::GIN::Extract::Callback;
use KiokuDB;

use constant TESTDB => 't/set_query.db';
sub cleanup { unlink TESTDB }

use Test::Requires 'DBD::SQLite';
use DBIx::Class::Optional::Dependencies;
my $deploy_deps;
BEGIN {
    $deploy_deps = DBIx::Class::Optional::Dependencies->req_list_for('deploy');
}
use Test::Requires $deploy_deps;

END {
    cleanup;
}

{  package TestClass;
   use Moose;
   has a => (is => 'rw');
   has b => (is => 'rw');
   has c => (is => 'rw');
   has d => (is => 'rw');
}

cleanup;
my $kiokudb = KiokuDB->connect
  ( 'dbi:SQLite:'.TESTDB,
    create => 1,
    extract =>
    Search::GIN::Extract::Callback->new
    ( extract => sub {
          my ($obj) = @_;
          return
            { a => $obj->a,
              b => $obj->b,
              c => $obj->c,
              d => $obj->d };
      })
  );

{  my @a = 'a'..'e';
   my @b = 'f'..'j';
   my @c = 'k'..'o';
   my @d = 'p'..'t';
   my $s = $kiokudb->new_scope;
   $kiokudb->store(map { TestClass->new( a => $a[$_],
                                         b => $b[$_],
                                         c => $c[$_],
                                         d => $d[$_] )
                     } 0..4);
};

# now we can, finally, do some searches...
# we're going to ask for:

lives_ok {
    # 1: (a:a or a:b or a:e) INTERSECT (c:k and d:p)
    # should return just the object with a=a
    my $results = $kiokudb->search
      ( Search::GIN::Query::Set->new
        ( operation => 'INTERSECT',
          subqueries =>
          [ Search::GIN::Query::Manual->new
            ( values =>
              { a => [qw(a b e)] }
            ),
            Search::GIN::Query::Manual->new
            ( values =>
              { c => 'k', d => 'p' },
              method => 'all',
            )
          ]));
    my $item = $results->next;
    my @objects = @$item;
    is(scalar @objects, 1, 'one object in the bulk');
    is($objects[0]->a, 'a', 'Found the correct object');
    ok(!$results->next, 'no more posts');
};

done_testing();
