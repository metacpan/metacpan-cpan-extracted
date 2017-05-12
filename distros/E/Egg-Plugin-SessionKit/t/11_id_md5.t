use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval { require Cache::FileCache };
if ($@) { plan skip_all => "Cache::FileCache is not installed." } else {
	eval { require Digest::MD5 };
	if ($@) { plan skip_all => "Digest::MD5 is not installed." } else {
		&test;
	}
}

sub test {

plan tests=> 5;

my $tool = Egg::Helper->helper_tools;
my $root = $tool->helper_tempdir. '/Vtest';

$tool->helper_create_file
  ($tool->helper_yaml_load(join '', <DATA>), { root=> $root });

my $e= Egg::Helper->run( Vtest => {
  vtest_root=> $root,
  vtest_config=> { MODEL=> ['Session'] },
  });

ok my $ss= $e->model('session::test'), q{my $ss= $e->model('session::test')};
  isa_ok $ss->context, 'Egg::Model::Session::ID::MD5';

ok my $id= $ss->context->make_session_id,
   q{my $id= $ss->context->make_session_id};
ok $ss->context->valid_session_id($id),
   q{$ss->context->valid_session_id($id)};
ok ! $ss->context->valid_session_id('bad_session_id'),
   q{! $ss->context->valid_session_id('bad_session_id')};

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
    ID::MD5
    Bind::Cookie
    Base::FileCache
    /;
  
  package Vtest::Model::Session::Test::TieHash;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::TieHash /;
  
  1;
