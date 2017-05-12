use strict; $^W = 1;
use Test::More qw[no_plan];
BEGIN {
  use_ok 'Function::Register';
  can_ok __PACKAGE__, 'set_register';

  ok set_register('One'), 'added registry';
  ok set_register('Two'), 'added registry';
}

is scalar(@One), 2, 'two in one';
is scalar(@Two), 1, 'one in two';
is scalar(@REGISTER), 3, 'three in default';

package main::reg;
  use strict; $^W = 1;
  use Test::More;
BEGIN {
  use_ok 'Function::Register', 'main';
}
BEGIN {
  can_ok __PACKAGE__, 'register';

  ok register(One => sub { "foo" }), 'registered one';
  ok register(One => sub { "foo" }), 'registered one again';
  
  ok register(Two => sub { "foo" }), 'registered two';

  ok register(sub { "foo" }), 'registered default';
  ok register(sub { "foo" }), 'registered default again';
  ok register(sub { "foo" }), 'registered default again again';
  
  is register(Foo => sub { "foo" }), undef, 'did not work';
  is register(One => "foo"), undef, 'did not work again';
}