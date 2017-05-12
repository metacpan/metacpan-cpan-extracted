use 5.010;
use strict;
use warnings;

use Test::More 0.92;
use Test::Routine;
use Test::Routine::Util;
use Test::Deep qw/cmp_deeply/;
use Try::Tiny;
use File::Spec::Functions qw/catfile/;
use re 'regexp_pattern';

use lib "t/lib";

with 'Metabase::Test::Index::SQLite';

has index => (
  is => 'ro',
  does => 'Metabase::Index',
  lazy_build => 1,
);

# copied from t/index.t -- but *dont* initialize
sub _build_index {
  my $self = shift;
  my $index = Metabase::Index::SQLite->new(
    filename => catfile( $self->tempdir, "test" . int(rand(2**31)) ),
  );
#  $index->initialize;
  return $index;
}

my @cases = (
  {
    label => 'single equality',
    input => { -where => [ -eq => 'content.grade' => 'PASS' ] },
    output => [ q{where "content"."grade" = 'PASS'}, undef ],
  },
  {
    label => "'-and' with equality",
    input => {
      -where => [
        -and =>
          [-eq => 'content.grade' => 'PASS' ],
          [-eq => 'content.osname' => 'MSWin32' ],
        ,
      ],
    },
    output => [
      q{where ("content"."grade" = 'PASS') and ("content"."osname" = 'MSWin32')},
      undef,
    ],
  },
  {
    label => 'inequality',
    input => { -where => [ -ne => 'content.grade' => 'PASS' ] },
    output => [ q{where "content"."grade" != 'PASS'}, undef ],
  },
  {
    label => 'greater than',
    input => { -where => [ -gt => 'content.grade' => 'PASS' ] },
    output => [ q{where "content"."grade" > 'PASS'}, undef ],
  },
  {
    label => 'less than',
    input => { -where => [ -lt => 'content.grade' => 'PASS' ] },
    output => [ q{where "content"."grade" < 'PASS'}, undef ],
  },
  {
    label => 'greater than or equal to',
    input => { -where => [ -ge => 'content.grade' => 'PASS' ] },
    output => [ q{where "content"."grade" >= 'PASS'}, undef ],
  },
  {
    label => 'less than or equal to',
    input => { -where => [ -le => 'content.grade' => 'PASS' ] },
    output => [ q{where "content"."grade" <= 'PASS'}, undef ],
  },
  {
    label => 'between',
    input => { -where => [ -between => 'content.size' => 10 => 20 ] },
    output => [ q{where "content"."size" between '10' and '20'}, undef ],
  },
  {
    label => 'like',
    input => { -where => [ -like => 'core.resource' => '%JOHNDOE%'  ] },
    output => [ q{where "core"."resource" like '%JOHNDOE%'}, undef ],
  },
  {
    label => 'and',
    input => { -where => [ -and => [ -gt => 'content.size' => 5 ], [ -lt => 'content.size' => 10 ] ] },
    output => [ q{where ("content"."size" > '5') and ("content"."size" < '10')}, undef ],
  },
  {
    label => 'or',
    input => { -where => [ -or => [ -gt => 'content.size' => 15 ], [ -lt => 'content.size' => 5 ] ] },
    output => [ q{where ("content"."size" > '15') or ("content"."size" < '5')}, undef ],
  },
  {
    label => 'not',
    input => { -where => [ -not => [ -gt => 'content.size' => 5 ] ] },
    output => [q{where NOT ("content"."size" > '5')}, undef],
  },
  {
    label => 'ordering',
    input => {
      -where => [ -eq => 'content.grade' => 'PASS' ],
      -order => [ -desc => 'content.grade' ],
    },
    output => [
      q{where "content"."grade" = 'PASS' order by "content"."grade" DESC},
      undef,
    ],
  },
  {
    label => 'ordering plus limit',
    input => {
      -where => [ -eq => 'content.grade' => 'PASS' ],
      -order => [ -desc => 'content.grade' ],
      -limit => 10
    },
    output => [
      q{where "content"."grade" = 'PASS' order by "content"."grade" DESC limit 10},
      10,
    ],
  },
);

test "query tests" => sub {
  my $self = shift;
  for my $c ( @cases ) {
    my @query = $self->index->get_native_query( $c->{input} );
    cmp_deeply( \@query, $c->{output}, $c->{label} );
  }
};

run_me;

done_testing;
