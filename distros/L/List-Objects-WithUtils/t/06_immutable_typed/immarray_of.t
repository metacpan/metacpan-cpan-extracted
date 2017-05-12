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

my $immof = immarray_of Int() => 1 .. 5;
is_deeply
  [ $immof->all ],
  [ 1 .. 5 ],
  'immarray_of ok';

ok $immof->type == Int, 'type ok';

eval {; immarray_of Int() => qw/foo 1 2/ };
ok $@ =~ /constraint/, 'immarray_of invalid type died';

for my $method
  (@List::Objects::WithUtils::Role::Array::Immutable::ImmutableMethods) {
  
  local $@;
  eval {; $immof->$method };
  ok $@ =~ /implemented/, "$method dies"
}


eval {; push @$immof, 6 };
ok $@ =~ /read-only/, 'push dies';

eval {; pop @$immof };
ok $@ =~ /read-only/, 'pop dies';

eval {; unshift @$immof, 0 };
ok $@ =~ /read-only/, 'unshift dies';

eval {; shift @$immof };
ok $@ =~ /read-only/, 'shift dies';

eval {; splice @$immof, 0, 1, 10 };
ok $@ =~ /read-only/, 'splice dies';

eval {; $immof->[10] = 'foo' };
ok $@ =~ /read-only/, 'attempted extend dies';

eval {; $immof->[0] = 10 };
ok $@ =~ /read-only/, 'element set dies';

{
  my $warned; local $SIG{__WARN__} = sub { $warned++ };
  $immof->sort(sub { $a <=> $b });
  ok !$warned, 'immarray_of imported $a/$b vars ok';
}

done_testing;
