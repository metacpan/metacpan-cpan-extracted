BEGIN {
  unless (eval {; require Types::Standard; 1 } && !$@) {
    require Test::More;
    Test::More::plan(skip_all =>
      'these tests require Types::Standard'
    );
  }
}

use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils;
use Types::Standard -all;

my $immh = immhash_of Int() => ( foo => 1, bar => 2 );

ok $immh->type == Int, 'type ok';

ok $immh->get('foo') == 1 && $immh->get('bar') == 2, 'get ok';

eval {; immhash_of Int() => ( foo => 'baz' ) };
ok $@ =~ /constraint/, 'immhash_of invalid type died';

for my $method
  (@List::Objects::WithUtils::Role::Hash::Immutable::ImmutableMethods) {
  local $@;
  eval {; $immh->$method };
  ok $@ =~ /implemented/, "$method dies"
}

eval {; $immh->{foo} = 3 };
ok $@ =~ /read-only/, 'hash item set dies';

eval {; delete $immh->{foo} };
ok $@ =~ /read-only/, 'hash item delete dies';

eval {; $immh->{quux} = 4 };
ok $@ =~ /read-only/, 'hash item insert dies';

{ my $warned; local $SIG{__WARN__} = sub { $warned = shift };
  $immh->kv_sort(sub { $a cmp $b });
  ok !$warned, 'immhash_of imported $a/$b vars ok';
}



done_testing;
