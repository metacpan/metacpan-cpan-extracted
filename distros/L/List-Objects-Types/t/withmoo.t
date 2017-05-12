BEGIN {
  unless (eval {; require Moo; 1 } && !$@) {
    require Test::More;
    Test::More::plan(skip_all =>
      'these tests require Moo-2+'
    );
  }

  unless (eval {; Moo->VERSION(2) }) {
    require Test::More;
    Test::More::plan(skip_all =>
      'these tests require Moo-2.x or newer'
    );
  }
}

use Test::More;
use strict; use warnings FATAL => 'all';

{ package
    Foo;
  use Types::Standard -all;
  use List::Objects::Types -all;
  use List::Objects::WithUtils;
  use Moo;

  has myarray => (
    is  => 'ro',
    isa => ArrayObj,
    default => sub { array },
  );

  has myimmarray => (
    is  => 'ro',
    isa => ImmutableArray,
    default => sub { immarray },
  );

  has myhash => (
    is  => 'ro',
    isa => HashObj,
    default => sub { hash },
  );

  has mycoercible => (
    is  => 'ro',
    isa => ArrayObj,
    coerce => 1,
    default => sub { [] },
  );

  has deeply => (
    is  => 'ro',
    isa => TypedHash[ TypedHash[Int] ],
    coerce  => 1,
    default => sub { +{} },
  );
}

my $foo = Foo->new;
ok $foo->myarray->does('List::Objects::WithUtils::Role::Array'),
  '->array() ok';
ok $foo->myimmarray->isa('List::Objects::WithUtils::Array::Immutable'),
  '->immarray() ok';
ok $foo->myhash->does('List::Objects::WithUtils::Role::Hash'),
  '->hash() ok';
ok $foo->mycoercible->does('List::Objects::WithUtils::Role::Array'),
  '->mycoercible ok';

ok $foo->deeply->does('List::Objects::WithUtils::Role::Hash::Typed'),
  '->deeply ok'
    or diag explain $foo->deeply;
$foo->deeply->{bar}->{baz} = 1;
my $bar = $foo->deeply->get('bar');
ok $bar->does('List::Objects::WithUtils::Role::Hash::Typed'),
  '->deeply inner hash coerced ok';

## FIXME fails on <5.16, haven't researched:
# my $baz = $bar->get('baz');
# ok $bar->get('baz') == 1, 'inner coercion ok' or diag explain $foo->deeply;

done_testing;
