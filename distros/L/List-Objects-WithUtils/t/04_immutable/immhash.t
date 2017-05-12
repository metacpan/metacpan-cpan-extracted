use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils;

ok hash->is_mutable, 'hash is_mutable';
ok !immhash->is_mutable, 'immhash ! is_mutable';
ok !hash->is_immutable, 'hash ! is_immutable';
ok immhash->is_immutable, 'immhash is_immutable';

my $imm = immhash( foo => 1, bar => 2 );

for my $method
  (@List::Objects::WithUtils::Role::Hash::Immutable::ImmutableMethods) {
  local $@;
  eval {; $imm->$method };
  like $@, qr/implemented/, "$method dies"
}

eval {; $imm->{baz} = 'quux' };
like $@, qr/read-only/,
  'attempt to add key died' or diag explain $@;

eval {; $imm->{foo} = 2 };
like $@, qr/read-only/,
  'attempt to modify existing died';

eval {; delete $imm->{bar} };
like $@, qr/read-only/,
  'attempt to delete key died';

eval {; %$imm = () };
like $@, qr/read-only/,
  'attempt to clear hash died';

ok $imm->get('foo') == 1 && $imm->get('bar') == 2,
  'hash ok after attempted clear';

ok !$imm->get('nonexistant'), 'retrieving nonexistant key ok';

{ my $warned; local $SIG{__WARN__} = sub { $warned = shift };
  $imm->kv_sort(sub { $a cmp $b });
  ok !$warned, 'immhash imported $a/$b vars ok';
}

done_testing;
