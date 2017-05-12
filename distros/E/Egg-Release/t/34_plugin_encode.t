use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval{ require Jcode };
if ($@) { plan skip_all=> "Jcode is not installed." } else {

plan tests=> 16;

my $s= 'ＭＶＣフレームワーク';

my $e= Egg::Helper->run( Vtest=> {
  vtest_plugins=> [qw/ Encode /],
  character_in=> 'utf8',
  } );

can_ok $e, 'encode';
  can_ok $e, 'create_encode';
  isa_ok $e->encode, 'Jcode';

can_ok $e, 'utf8_conv';
can_ok $e, 'sjis_conv';
can_ok $e, 'euc_conv';

can_ok $e->request, 'parameters';
  isa_ok $e->request->parameters, 'HASH';
  isa_ok tied(%{$e->request->parameters}), 'Egg::Plugin::Encode::TieHash';
  is $e->request->parameters, $e->request->params,
     q{$e->request->parameters, $e->request->params};

tie my %param, 'Egg::Plugin::Encode::TieHash', $e, 'utf8', { test=> $s };
  ok $param{test}, q{$param{test}};
  is Jcode::getcode($param{test}), 'utf8',
     q{Jcode::getcode($param{test}), 'utf8'};

%param= ();
tie %param, 'Egg::Plugin::Encode::TieHash', $e, 'sjis', { test=> $s };
  ok $param{test}, q{$param{test}};
  is Jcode::getcode($param{test}), 'sjis',
     q{Jcode::getcode($param{test}), 'sjis'};

%param= ();
tie %param, 'Egg::Plugin::Encode::TieHash', $e, 'euc', { test=> $s };
  ok $param{test}, q{$param{test}};
  is Jcode::getcode($param{test}), 'euc',
     q{Jcode::getcode($param{test}), 'euc'};

}
