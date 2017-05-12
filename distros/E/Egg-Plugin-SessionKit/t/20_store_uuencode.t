use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval { require Cache::FileCache };
if ($@) { plan skip_all => "Cache::FileCache is not installed." } else {
	eval { require Convert::UU };
	if ($@) { plan skip_all => "Convert::UU is not installed." } else {
		&test;
	}
}

sub test {

plan tests=> 7;

my $tool = Egg::Helper->helper_tools;
my $root = $tool->helper_tempdir. '/Vtest';

$tool->helper_create_file
  ($tool->helper_yaml_load(join '', <DATA>), { root=> $root });

my $e= Egg::Helper->run( Vtest => {
  vtest_root=> $root,
  vtest_config=> { MODEL=> ['Session'] },
  });

ok my $ss= $e->model('session::test'), q{my $ss= $e->model('session::test')};
  isa_ok $ss->context, 'Egg::Model::Session::Store::UUencode';

ok my $store= $ss->context->store_encode( $ss->context->data ),
  q{my $store= $ss->context->store_encode( $ss->context->data )};
  isa_ok $store, 'SCALAR';
  like $$store, qr{begin\s+\d+\s+uuencode\.},
       q{$$store, qr{begin\s+\d+\s+uuencode\.}};

ok my $hash= $ss->context->store_decode($store),
   q{my $hash= $ss->context->store_decode($store)};

ok keys %$hash, q{keys %$hash};

}

__DATA__
filename: <e.root>/lib/Vtest/Model/Session/Test.pm
value: |
  package Vtest::Model::Session::Test;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::Base /;
  
  __PACKAGE__->config(
    param_name=> 'ss',
    );
  
  __PACKAGE__->startup qw/
    ID::IPaddr
    Store::UUencode
    Base::FileCache
    /;
  
  package Vtest::Model::Session::Test::TieHash;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::TieHash /;
  
  1;

