
BEGIN {
  unless (eval {; require Types::Standard; 1 }   && !$@) {
    require Test::More;
    Test::More::plan(skip_all =>
      'these tests require Types::Standard'
    );
  }
}


{ package AlwaysTrue; sub new { bless [], shift } sub check { 1 } }
{ package AlwaysFalse;
  sub new { bless [], shift }
  sub check { 0 }
  sub get_message { "failed type constraint" }
}

use Test::More;
use strict; use warnings FATAL => 'all';

use Types::Standard -all;


# hash_of
{
  use List::Objects::WithUtils 'hash', 'hash_of';
  my $h = hash_of Int() => (foo => 1, bar => 2);
  ok $h->type == Int, 'type returned Int ok';
  ok !hash->type, 'plain HashObj has no type ok';

  my $customtype = hash_of( AlwaysTrue->new, foo => 1, bar => 2 );
  ok $customtype->keys->count == 2, 'non-TT type ok (true)';
  eval {; $customtype = hash_of( AlwaysFalse->new, foo => 1 ) };
  ok $@ =~ /constraint/, 'non-TT type ok (false)'
    or diag explain $@;

  eval {; my $bad = hash_of( Int() => qw/foo 1 bar baz/) };
  ok $@ =~ /constraint/, 'array_of invalid type died ok' or diag explain $@;

  eval {; $h->set(baz => 3.14159) };
  ok $@ =~ /type/, 'invalid type set died ok';
  ok $h->set(baz => 3), 'valid type set ok';
  ok $h->keys->count == 3, 'count ok after set';

  my $copy = $h->copy;
  isa_ok $copy, 'List::Objects::WithUtils::Hash::Typed';
  ok $copy->type == $h->type, 'copy has same type ok';
  is_deeply +{ $copy->export }, +{ $h->export },
    'copy ok';

  my $untyped = $h->untyped;
  isa_ok $untyped, 'List::Objects::WithUtils::Hash';
  ok !$untyped->type, 'untyped has no type ok';
  ok $untyped->set(baz => 'quux'), 'untyped dropped type ok';
}

# tied hash
{
  use List::Objects::WithUtils 'hash_of';
  my $h = hash_of Int() => (foo => 1, bar => 2);

  eval {; $h->{foo} = 'bar' };
  ok $@ =~ /type/, 'invalid type set died ok';
}

{ my $warned; local $SIG{__WARN__} = sub { $warned = shift };
  my $h = hash_of Int() => (a => 1, b => 2, c => 3);
  $h->kv_sort(sub { $a cmp $b });
  ok !$warned, 'hash_of imported $a/$b vars ok';
}

done_testing;
