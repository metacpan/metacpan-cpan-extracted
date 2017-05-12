use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('File::PackageIndexer') };
use Data::Dumper;

my $indexer = File::PackageIndexer->new();
isa_ok($indexer, 'File::PackageIndexer');

my @tests = (
  {
    name => 'simple',
    code => <<'HERE',
package Foo;
use parent 'Bar';
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Bar'], },
    },
  },
  {
    name => 'two classes',
    code => <<'HERE',
package Foo;
use parent 'Bar', "Baz", '-norequire';
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Bar', 'Baz'], },
    },
  },
  {
    name => 'qw',
    code => <<'HERE',
package Foo;
use parent qw[Bar -foo Baz];
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Bar', 'Baz'], },
    },
  },
  {
    name => 'literal',
    code => <<'HERE',
package Foo;
use parent q{Baz};
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Baz'], },
    },
  },
  {
    name => 'multiple',
    code => <<'HERE',
package Foo;
use parent "Bar";
use parent -norequire => q{Baz};
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Bar', 'Baz'], },
    },
  },
  {
    name => 'multiple, mixed',
    code => <<'HERE',
package Foo;
use parent "Bar", qq{Buz};
use parent q{Baz};
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Bar', 'Buz', 'Baz'], },
    },
  },
  {
    name => 'multiple, mixed',
    code => <<'HERE',
package Foo;
use parent "Bar", qq{Buz};
package Arg;
use parent q{Baz};
use parent qw(Foo), "-FrobNication;
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Bar', 'Buz'], },
      Arg => { name => 'Arg', subs => {}, isa => ['Baz', 'Foo'], },
    },
  },
  {
    name => 'multiple, mixed, funny parenthesis',
    code => <<'HERE',
package Foo;
use parent ((qw(-uahaha), (("Bar")), qq{Buz}),);
package Arg;
use parent ((q{Baz},),);
use parent qw(Foo);
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Bar', 'Buz'], },
      Arg => { name => 'Arg', subs => {}, isa => ['Baz', 'Foo'], },
    },
  },
);

foreach my $test (@tests) {
  my $name = $test->{name};
  my $code = $test->{code};
  my $ref = $test->{"cmp"};
  my $index = $indexer->parse($code);
  is_deeply($index, $ref, "equivalence test: $name") or warn Dumper $index;
}

