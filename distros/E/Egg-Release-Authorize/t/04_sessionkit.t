use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval{ require Egg::Model::Session };

if ($@) {
	plan skip_all=> "Egg::Model::Session is not installed."
} else {
	test();
}

sub test {

plan tests=> 38;

my $tool= Egg::Helper->helper_tools;

my $project= 'Vtest';
my $path   = $tool->helper_tempdir. "/$project";

$tool->helper_create_files(
  [ $tool->helper_yaml_load( join('', <DATA>)) ],
  { path => $path },
  );

my $e= Egg::Helper->run( Vtest => {
#  vtest_plugins=> [qw/ -Debug /],
  vtest_root   => $path,
  vtest_config => { MODEL=> [qw/ Session Auth /] },
  });

ok $e->is_model('auth'), q{$e->is_model('auth')};
ok $e->is_model('a_test'), q{$e->is_model('a_test')};
ok $e->is_model('session_test'), q{$e->is_model('session_test')};

ok my $s= $e->model('a_test'), q{$s= $e->model('a_test')};
is $s, $e->model('auth'), q{$s, $e->model('auth')};

isa_ok $s, 'Vtest::Model::Auth::Test';
isa_ok $s, 'Egg::Model::Auth::Session::SessionKit';
isa_ok $s, 'Egg::Model::Auth::Base';
isa_ok $s, 'Egg::Base';
isa_ok $s, 'Egg::Component';
isa_ok $s, 'Egg::Component::Base';

$e->helper_create_dir( $e->path_to('cache') );

can_ok $s, 'e';
  is $s->e, $e, q{$s->e, $e};

##
can_ok $s, 'session';
  isa_ok $s->session, 'Vtest::Model::Session::Test';
can_ok $s, 'model_name';
can_ok $s, 'session_key';
##

my $param= $e->request->params;
$param->{__uid}= 'tester1';
$param->{__psw}= '%test%';

can_ok $s, 'login_check';
  ok my $data= $s->login_check, q{my $data= $s->login_check};
  isa_ok $data, 'HASH';

can_ok $s, 'data';
  is $data, $s->data, q{$data, $s->data};
  is $data->{___user}, 'tester1', q{$data->{___user}, 'tester1'};
  is $data->{___password}, '%test%', q{$data->{___password}, '%test%'};
  is $data->{___active}, 1, q{$data->{___active}, 1};
  is $data->{___group}, 'admin', q{$data->{___group}, 'admin'};
  is $data->{age}, 20, q{$data->{age}, 20};

ok $s->session->is_update, q{$s->session->is_update};
  ok $s->session->{$s->session_key}, q{$s->session->{$s->session_key}};
  is $s->session->{$s->session_key}, $data, q{$s->session->{$s->session_key}, $data};

can_ok $s, 'is_login';
  ok $s->is_login, q{$s->is_login};
  is $data, $s->is_login, q{$data, $s->is_login};

can_ok $s, 'group_check';
  ok $s->group_check('admin'), q{$s->group_check('admin')};

can_ok $s, 'logout';
  ok $s->logout, q{$s->logout};
  ok ! $s->is_login, q{! $s->is_login};

}

__DATA__
---
filename: <e.path>/lib/Vtest/Model/Session/Test.pm
value: |
  package Vtest::Model::Session::Test;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::Base /;
  
  __PACKAGE__->config(
    label_name => 'session_test',
    store => {
    
     },
    );
  
  __PACKAGE__->startup qw/
    ID::SHA1
    Bind::Cookie
    Base::FileCache
    /;
  
  package Vtest::Model::Session::Test::TieHash;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::TieHash /;
  
  1;
---
filename: <e.path>/lib/Vtest/Model/Auth/Test.pm
value: |
  package Vtest::Model::Auth::Test;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Auth::Base /;
  
  __PACKAGE__->config(
    label_name=> 'a_test',
    login_get_ok => 1,
    sessionkit=> {
      model_name => 'session_test',
      },
    file=> {
      path   => Vtest->path_to(qw/ etc members /),
      fields => [qw/ uid psw active a_group age /],
      id_field       => 'uid',
      password_field => 'psw',
      active_field   => 'active',
      group_field    => 'a_group',
      delimiter      => qr{ *\t *},
      },
    );
  
  __PACKAGE__->setup_session('SessionKit');
  
  __PACKAGE__->setup_api('File');
  
  1;
---
filename: <e.path>/etc/members
value: |
  tester1	%test%	1	admin	20
  tester2		1	users	21
  tester3	%test%	0	users	22
  tester4	%test%	1	users	23

