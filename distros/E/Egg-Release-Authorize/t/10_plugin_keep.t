use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval{ require Cache::FileCache };

if ($@) {
	plan skip_all=> "Cache::FileCache is not installed."
} else {
	unless ( Crypt::CBC->require ) {
		plan skip_all=> "Crypt::CBC is not installed."
	} else {
		test();
	}
}

sub test {

my $ciper= Crypt::Blowfish->require ? 'Blowfish'
         : Crypt::DES->require      ? 'DES'
         : Crypt::Camellia->require ? 'Camellia'
         : Crypt::Rabbit->require   ? 'Rabbit'
         : Crypt::Twofish2->require ? 'Twofish2'
         : return do {
	plan skip_all=> "The Ciper module is not installed.";
  };

plan tests=> 23;

my $tool= Egg::Helper->helper_tools;

my $project= 'Vtest';
my $path   = $tool->helper_tempdir. "/$project";
my $key    = '12345678';

$tool->helper_create_files(
  [ $tool->helper_yaml_load( join('', <DATA>)) ],
  { path => $path, cipher=> $ciper, key=> $key },
  );

my $e= Egg::Helper->run( Vtest => {
#  vtest_plugins=> [qw/ -Debug /],
  vtest_root   => $path,
  vtest_config => { MODEL=> ['Auth'] },
  });

ok $e->is_model('auth'), q{$e->is_model('auth')};
ok $e->is_model('a_test'), q{$e->is_model('a_test')};

ok my $s= $e->model('a_test'), q{$s= $e->model('a_test')};
is $s, $e->model('auth'), q{$s, $e->model('auth')};

isa_ok $s, 'Vtest::Model::Auth::Test';
isa_ok $s, 'Egg::Model::Auth::Plugin::Keep';
isa_ok $s, 'Egg::Model::Auth::Session::FileCache';
isa_ok $s, 'Egg::Model::Auth::Bind::Cookie';
isa_ok $s, 'Egg::Model::Auth::Base';
isa_ok $s, 'Egg::Base';
isa_ok $s, 'Egg::Component';
isa_ok $s, 'Egg::Component::Base';

$e->helper_create_dir($e->path_to('cache'));

##
can_ok $s, '__keep_cbc';
  isa_ok $s->__keep_cbc, 'Crypt::CBC';
##

my $param= $e->request->params;
$param->{__uid}= 'tester1';
$param->{__psw}= '%test%';
$param->{__auto_login}= 1;

can_ok $s, 'login_check';
  ok my $data= $s->login_check, q{my $data= $s->login_check};
  isa_ok $data, 'HASH';

ok $e->response->cookies->{keep}, q{$e->response->cookies->{keep}};
ok my $value= $e->response->cookies->{keep}->value, q{$value= $e->response->cookies->{keep}->value};
ok $s->logout, q{$s->logout};

$ENV{HTTP_COOKIE}= "keep=$value";
$e->request->{cookies}= undef;
ok $s->is_login, q{$s->is_login};
ok $s->logout, q{$s->logout};

ok ! $s->is_login, q{! $s->is_login};

}

__DATA__
---
filename: <e.path>/lib/Vtest/Model/Auth/Test.pm
value: |
  package Vtest::Model::Auth::Test;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Auth::Base /;
  
  __PACKAGE__->config(
    label_name   => 'a_test',
    login_get_ok => 1,
    file=> {
      path   => Vtest->path_to(qw/ etc members /),
      fields => [qw/ uid psw active a_group age /],
      id_field       => 'uid',
      password_field => 'psw',
      active_field   => 'active',
      group_field    => 'a_group',
      delimiter      => qr{ *\t *},
      },
    plugin_keep => {
      crypt=> {
        cipher => '<e.cipher>',
        key    => '<e.key>',
        },
      },
    );
  
  __PACKAGE__->setup_plugin('Keep');
  
  __PACKAGE__->setup_session( FileCache => 'Bind::Cookie' );
  
  __PACKAGE__->setup_api('File');
  
  1;
---
filename: <e.path>/etc/members
value: |
  tester1	%test%	1	admin	20
  tester2		1	users	21
  tester3	%test%	0	users	22
  tester4	%test%	1	users	23
