use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('File::PackageIndexer') };

my $indexer = File::PackageIndexer->new();
isa_ok($indexer, 'File::PackageIndexer');

my @tests = (
  {
    name => 'empty',
    code => <<'HERE',
HERE
    'cmp' => undef,
  },
  {
    name => 'simple',
    code => <<'HERE',
sub foo {}
HERE
    'cmp' => {
      main => { name => 'main', subs => {foo => 1}, isa => [], },
    },
  },
  {
    name => 'empty a',
    code => <<'HERE',
sub foo {}
use base 'Class::Accessor';
__PACKAGE__->mk_accessors();
HERE
    'cmp' => {
      main => { name => 'main', subs => {foo => 1}, isa => [qw(Class::Accessor)], },
    },
  },
  {
    name => 'simple a',
    code => <<'HERE',
sub foo {}
use base 'Class::Accessor';
__PACKAGE__->mk_accessors("bar");
HERE
    'cmp' => {
      main => { name => 'main', subs => {foo => 1, bar => 1}, isa => [qw(Class::Accessor)], },
    },
  },
  {
    name => 'simple, explicit a',
    code => <<'HERE',
sub foo {}
use base 'Class::Accessor';
main->mk_accessors("bar");
HERE
    'cmp' => {
      main => { name => 'main', subs => {foo => 1, bar => 1}, isa => [qw(Class::Accessor)], },
    },
  },
  {
    name => 'simple, explicit a2',
    code => <<'HERE',
sub foo {}
use base 'Class::Accessor';
Foo->mk_accessors("bar");
HERE
    'cmp' => {
      main => { name => 'main', subs => {foo => 1}, isa => [qw(Class::Accessor)], },
      Foo  => { name => 'Foo', subs => {bar => 1}, isa => [], },
    },
  },
  {
    name => 'qw, explicit a',
    code => <<'HERE',
sub foo {}
use base 'Class::Accessor';
main->mk_accessors(qw(bar baz), "buz");
HERE
    'cmp' => {
      main => { name => 'main', subs => {foo => 1, bar => 1, baz => 1, buz => 1}, isa => [qw(Class::Accessor)], },
    },
  },
  {
    name => 'qw, explicit a2',
    code => <<'HERE',
sub foo {}
use base 'Class::Accessor';
Foo->mk_accessors("bar", qw   ! baz     buz!);
HERE
    'cmp' => {
      main => { name => 'main', subs => {foo => 1}, isa => [qw(Class::Accessor)], },
      Foo  => { name => 'Foo', subs => {bar => 1, baz => 1, buz => 1}, isa => [], },
    },
  },
  {
    name => 'qw, mixed, multiple a',
    code => <<'HERE',
package Bar;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors("bar");
Bar->mk_ro_accessors("foo");
Foo->mk_wo_accessors("bar", qw   ! baz     buz!);
HERE
    'cmp' => {
      Bar => { name => 'Bar', subs => {bar => 1, foo => 1}, isa => [qw(Class::Accessor)], },
      Foo  => { name => 'Foo', subs => {bar => 1, baz => 1, buz => 1}, isa => [], },
    },
  },
);

foreach my $test (@tests) {
  my $name = $test->{name};
  my $code = $test->{code};
  my $ref = $test->{"cmp"};
  my $index = $indexer->parse($code);
  use Data::Dumper;
  is_deeply($index, $ref, "equivalence test: $name") or warn Dumper $index;
}

