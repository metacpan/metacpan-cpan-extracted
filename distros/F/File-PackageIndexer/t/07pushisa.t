use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('File::PackageIndexer') };
use Data::Dumper;

my $indexer = File::PackageIndexer->new();
isa_ok($indexer, 'File::PackageIndexer');

my @tests = (
  {
    name => 'simple push',
    code => <<'HERE',
package Foo;
our @ISA;
push @ISA, qw(Bar Baz);
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Bar', 'Baz'], },
    },
  },
  {
    name => 'simple push, parens',
    code => <<'HERE',
package Foo;
our @ISA;
push(@ISA, qw(Bar Baz));
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => ['Bar', 'Baz'], },
    },
  },
  {
    name => 'multiple push, parens',
    code => <<'HERE',
package Foo;
our @ISA;
push(@ISA, qw(Bar Baz));
push @ISA, (qw(Bur Buz));
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => [qw(Bar Baz Bur Buz)], },
    },
  },
  {
    name => 'simple unshift, parens',
    code => <<'HERE',
package Foo;
our @ISA;
unshift(@ISA, qw(Bar Baz));
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => [qw(Bar Baz)], },
    },
  },
  {
    name => 'multiple unshift, parens',
    code => <<'HERE',
package Foo;
our @ISA;
unshift(@ISA, qw(Bar Baz));
unshift @ISA, "Bur", qw!Buz!;
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => [qw(Bur Buz Bar Baz)], },
    },
  },
  {
    name => 'mixed unshift and push, parens',
    code => <<'HERE',
package Foo;
our @ISA;
push (@ISA, qw(Bar Baz));
unshift @ISA, "Bur", qw!Buz!;
push @ISA, qw(Fuz);
unshift @ISA, 'Faz';
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => [qw(Faz Bur Buz Bar Baz Fuz)], },
    },
  },
  {
    name => 'BEGIN, mixed unshift and push, parens',
    code => <<'HERE',
package Foo;
our @ISA;
push (@ISA, qw(Bar Baz));
unshift @ISA, "Bur", qw!Buz!;
BEGIN {push @ISA, qw(Fuz);}
unshift @ISA, 'Faz';
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => [qw(Faz Bur Buz Fuz Bar Baz)], },
    },
  },
  {
    name => 'BEGIN, mixed unshift and push, parens, ignored END',
    code => <<'HERE',
package Foo;
our @ISA;
END { push @ISA, 'Frob'; }
push (@ISA, qw(Bar Baz));
unshift @ISA, "Bur", qw!Buz!;
BEGIN {push @ISA, qw(Fuz);}
unshift @ISA, 'Faz';
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => [qw(Faz Bur Buz Fuz Bar Baz)], },
    },
  },
  {
    name => 'BEGIN, mixed unshift and push, parens, ignored END, CHECK as run-time',
    code => <<'HERE',
package Foo;
our @ISA;
END { push @ISA, 'Frob'; }
CHECK {push (@ISA, qw(Bar Baz)); }
unshift @ISA, "Bur", qw!Buz!;
BEGIN {push @ISA, qw(Fuz);}
unshift @ISA, 'Faz';
HERE
    'cmp' => {
      Foo => { name => 'Foo', subs => {}, isa => [qw(Faz Bur Buz Fuz Bar Baz)], },
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

