use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval { require Cache::FileCache };
if ($@) { plan skip_all => "Cache::FileCache is not installed." } else {
	&test;
}

sub test {

plan tests=> 6;

my $tool = Egg::Helper->helper_tools;
my $root = $tool->helper_tempdir. '/Vtest';

$tool->helper_create_file
  ($tool->helper_yaml_load(join '', <DATA>), { root=> $root });

my $e= Egg::Helper->run( Vtest => {
  vtest_root=> $root,
  vtest_config=> { MODEL=> ['Session'] },
  });

$ENV{UNIQUE_ID}= 'aBc123DeF456gHi789j';

ok my $ss= $e->model('session::test'), q{my $ss= $e->model('session::test')};
  isa_ok $ss->context, 'Egg::Model::Session::ID::UniqueID';

ok my $id= $ss->context->make_session_id,
   q{my $id= $ss->context->make_session_id};
is $id, $ENV{UNIQUE_ID}, q{$id, $ENV{UNIQUE_ID}};
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
    ID::UniqueID
    Bind::Cookie
    Base::FileCache
    /;
  
  package Vtest::Model::Session::Test::TieHash;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::TieHash /;
  
  1;
