use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval{ require HTML::Prototype };
if ($@) { plan skip_all=> "HTML::Prototype is not installed." } else {

plan tests=> 4;

ok my $e= Egg::Helper->run
   ( Vtest=> { vtest_plugins=> [qw/ Prototype /] }), q{ load plugin. };

can_ok $e, 'prototype';
  ok my $p= $e->prototype, q{my $p= $e->prototype};
  eval{ require HTML::Prototype::Useful };
  if ($@) {
    isa_ok $p, 'HTML::Prototype';
  } else {
    isa_ok $p, 'HTML::Prototype::Useful';
  }

}
