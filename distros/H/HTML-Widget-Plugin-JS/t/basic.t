use strict;
use warnings;
use Test::More tests => 2;

use HTML::Widget::Factory;
use HTML::Widget::Plugin::JS;

my $factory = HTML::Widget::Factory->new({
  extra_plugins => [ 'HTML::Widget::Plugin::JS' ],
});

ok(1);

$TODO = "5.18.0 hash ordering can break this test"
  if $] >= 5.017;

is(
  $factory->js_var({ a => [ 1, 2, 3 ], b => { x => 10 } }),
  $factory->js_vars({ a => [ 1, 2, 3 ], b => { x => 10 } }),
  "js_vars and js_var are equiv",
);
