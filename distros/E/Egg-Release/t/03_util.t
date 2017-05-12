use Test::More tests=> 73;
use strict;
use warnings;
use lib qw( ../lib ./lib );
use Egg::Helper;

my $e= Egg::Helper->run('Vtest', {
  project_name=> 'UTIL_TEST',
  plugin_dispatch=> {},
  start_code=> join('', <DATA>),
  vtest_plugins=> [qw/ -flag_test /],
  create_methods=> {
    dispatch=> sub { $_[0]->{dispatch} ||= EggTest::Dispatch->new },
    },
  });

isa_ok $e, 'Egg::Util';

can_ok $e, 'dispatch_map';
  ok $e->dispatch_map({}), q{$e->dispatch_map({})};
  isa_ok $e->dispatch_map, 'HASH';

can_ok $e, 'page_title';
  ok $e->page_title('test'), q{$e->page_title('test')};
  is $e->page_title, 'test', q{$e->page_title, 'test'};

can_ok $e, 'debug';
  $e->flag->{-debug}= 1;
  is $e->debug, 1, q{$e->debug, 1};
  $e->flag->{-debug}= 0;
  is $e->debug, 0, q{$e->debug, 0};

can_ok $e, 'flag';
  isa_ok $e->flag, 'HASH';
  ok $e->flag('flag_test'), q{$e->flag('flag_test')};

can_ok $e, 'snip';
  isa_ok $e->snip, 'ARRAY';

can_ok $e, 'action';
  isa_ok $e->action, 'ARRAY';

can_ok $e, 'stash';
  isa_ok $e->stash, 'HASH';
  ok $e->stash( EggTest=> 'OK' ), q{$e->stash( EggTest=> 'OK' )};
  is $e->stash('EggTest'), 'OK', q{$e->stash('EggTest')};
  ok my $stash= $e->stash, q{my $stash= $e->stash};
  isa_ok $stash, 'HASH';
  is $stash->{EggTest}, 'OK', q{$stash->{EggTest}};
  ok $e->template('EggTest.tt'), q{$e->template('EggTest.tt')};
  is $e->stash('template'), 'EggTest.tt', q{$e->stash('template')};
  is $stash->{template}, 'EggTest.tt', q{$stash->{template}};

can_ok $e, 'path_to';
  is $e->path_to, $e->config->{root}, 'path_to, $e->config->{root}';
  is $e->path_to('foo/baaa'), $e->config->{root}."/foo/baaa", q{$e->path_to('foo/baaa')};
  is $e->path_to(qw/ lib EggTest /),
     $e->config->{dir}{lib}."/EggTest", q{$e->path_to(qw/ lib EggTest /)};

can_ok $e, 'uri_to';
  is $e->uri_to('http://mydomain/boo', { foo=> 1 }),
     'http://mydomain/boo?foo=1', q{$e->uri_to('http://mydomain/boo', { foo=> 1 })};

can_ok $e, 'snip2template';
  $e->helper_create_files([
    { filename=> 'root/t1/t2.tt', value=> 'test', },
    { filename=> 'root/t1/t2/t3.tt', value=> 'test', },
    ]);
  ok $e->snip([qw/ t1 t2 t3 /]), q{$e->snip([qw/ t1 t2 t3 /])};
  ok my $tmpl= $e->snip2template(1), q{$e->snip2template(1)};

  is $tmpl, 't1/t2.tt', q{$tmpl, 't1/t2.tt'};
  ok $tmpl= $e->snip2template(2), q{$e->snip2template(2)};
  is $tmpl, 't1/t2/t3.tt', q{$tmpl, 't1/t2/t3.tt'};
  ok ! $e->snip2template(3), q{$e->snip2template(3)};
  $e->helper_remove_file("root/t1/t2.tt");
  ok ! $e->snip2template(1), q{! $e->snip2template(1)};
  $e->helper_remove_file("root/t1/t2/t3.tt");
  ok ! $e->snip2template(2), q{! $e->snip2template(2)};

can_ok $e, 'setup_error_header';
  ok $e->setup_error_header, q{$e->setup_error_header};
  ok $e->res->no_cache, q{$e->res->no_cache};
  ok $e->res->headers->{"X-Egg-$e->{namespace}-ERROR"},
     q{$e->res->headers->{"X-Egg-$e->{namespace}-ERROR"}};

can_ok $e, 'get_config';
  ok $e->get_config, q{$e->get_config};
  isa_ok $e->get_config, 'HASH';
  is $e->get_config->{root}, $e->config->{root}, q{$e->get_config->{root}};
  ok my $conf= $e->get_config('Egg::Plugin::Dispatch'),
     q{$conf= $e->get_config('Egg::Plugin::Dispatch')};
  isa_ok $conf, 'HASH';
  isa_ok $e->get_config('Egg::Plugin::Dispatch::Any'), 'HASH';
  is $conf, $e->get_config('Egg::Plugin::Dispatch::Any'),
     q{$conf, $e->get_config('Egg::Plugin::Dispatch::Any')};

can_ok $e, 'log';
  isa_ok $e->log, 'Egg::Log::STDERR';

my %param= (
  foo => 'test',
  hoo => { a => '< e.foo >', b => '< $e.foo >' },
  boo => ['<e.hoo.a>', '<e.hoo.b>', { ok => '<$e.foo>' }],
  zoo => { z1=> '< e.hoo >', z2 => { ok => '< $e.hoo.a >' } },
  bad => '\< e.foo >',
  );
can_ok $e, 'egg_var_deep';
  can_ok $e, 'egg_var';
  can_ok $e, '_replace';
  ok $e->egg_var_deep(\%param, $param{hoo}), q{$e->egg_var_deep(\%param, $param{hoo})};
  ok $e->egg_var_deep(\%param, $param{boo}), q{$e->egg_var_deep(\%param, $param{boo})};
  ok $e->egg_var_deep(\%param, \%param),     q{$e->egg_var_deep(\%param, \%param)};
  is $param{hoo}{a}, 'test', q{$param{hoo}{a}, 'test'};
  is $param{hoo}{b}, 'test', q{$param{hoo}{b}, 'test'};
  is $param{boo}[0], 'test', q{$param{boo}[0], 'test'};
  is $param{boo}[1], 'test', q{$param{boo}[1], 'test'};
  isa_ok $param{boo}[2], 'HASH', q{$param{boo}[2], 'HASH'};
  is $param{boo}[2]{ok}, 'test', q{$param{boo}[2]{ok}, 'test'};
  isnt ref($param{zoo}{z1}), 'HASH', q{! ref($param{zoo}{z1}), 'HASH'};
  like $param{zoo}{z1}, qr{^HASH\(0x[a-f0-9]+\)}, q{qr{^HASH\(0x[a-f0-9]+\)}};
  isa_ok $param{zoo}{z2}, 'HASH', q{$param{zoo}{z2}, 'HASH'};
  is   $param{zoo}{z2}{ok}, 'test', q{$param{zoo}{z2}{ok}, 'test'};
  like $param{bad}, qr{^<\$?e\.foo>$}, q{qr{^<\$?e\.foo>$}};


__DATA__
package EggTest::Dispatch;
sub new { bless { e=> $_[1] } }
sub page_title { shift->e->page_title(@_) }
