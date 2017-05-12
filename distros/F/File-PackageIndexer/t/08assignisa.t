use strict;
use warnings;

use Test::More tests => 12;
BEGIN { use_ok('File::PackageIndexer') };
use Data::Dumper;

my $indexer = File::PackageIndexer->new();
isa_ok($indexer, 'File::PackageIndexer');

my @tests = (
  {
    name => 'simple assign',
    code => <<'HERE',
package Foo;
our @ISA;
@ISA = ("Bar", "Baz");
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Bar', 'Baz'], },
    },
  },
  {
    name => 'simple assign twice',
    code => <<'HERE',
package Foo;
our @ISA;
@ISA = ("Bar", "Baz");
@ISA = ("Bur", "Buz");
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Bur', 'Buz'], },
    },
  },
  {
    name => 'simple assign BEGIN',
    code => <<'HERE',
package Foo;
our @ISA;
BEGIN {@ISA = ("Bar", "Baz");}
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Bar', 'Baz'], },
    },
  },
  {
    name => 'simple assign twice BEGIN',
    code => <<'HERE',
package Foo;
our @ISA;
BEGIN {@ISA = ("Bar", "Baz");}
@ISA = ("Bur", "Buz");
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Bur', 'Buz'], },
    },
  },
  {
    name => 'push, assign',
    code => <<'HERE',
package Foo;
our @ISA;
push @ISA, 'Baz';
@ISA = ("Bur", "Buz");
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Bur', 'Buz'], },
    },
  },
  {
    name => 'push, assign, unshift',
    code => <<'HERE',
package Foo;
our @ISA;
push @ISA, 'Baz';
@ISA = ("Bur", "Buz");
unshift @ISA, 'Frob';
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Frob', 'Bur', 'Buz'], },
    },
  },
  {
    name => 'push, BEGIN assign, unshift',
    code => <<'HERE',
package Foo;
our @ISA;
push @ISA, 'Baz';
BEGIN {@ISA = ("Bur", "Buz");}
unshift @ISA, 'Frob';
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Frob', 'Bur', 'Buz', 'Baz'], },
    },
  },
  {
    name => 'push, END assign, unshift',
    code => <<'HERE',
package Foo;
our @ISA;
push @ISA, 'Baz';
END {@ISA = ("Bur", "Buz");}
unshift @ISA, 'Frob';
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Frob', 'Baz'], },
    },
  },
  {
    name => 'base, push, BEGIN assign, unshift',
    code => <<'HERE',
package Foo;
our @ISA;
use base 'Frab';
push @ISA, 'Baz';
BEGIN {@ISA = ("Bur", "Buz");}
unshift @ISA, 'Frob';
push @ISA, 'Frub';
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Frob', 'Bur', 'Buz', 'Baz', 'Frub'], },
    },
  },
  {
    name => 'declare assign',
    code => <<'HERE',
package Foo;
our @ISA = qw(Frob);
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Frob'], },
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

