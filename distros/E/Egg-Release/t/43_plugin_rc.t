use Test::More tests=> 5;
use lib qw( ./lib ../lib );
use Egg::Helper;

$ENV{EGG_RC_NAME}= 'egg_releaserc';

ok my $e= Egg::Helper->run
   ( Vtest=> { vtest_plugins=> [qw/ rc /] } ), q{ load plugin. };

$e->helper_create_file
($e->helper_yaml_load(join'', <DATA>), { rc_name=> $ENV{EGG_RC_NAME} });

can_ok $e, 'load_rc';
  ok my $rc= $e->load_rc($e->config->{root}), q{my $rc= $e->load_rc($e->config->{root})};
  isa_ok $rc, 'HASH';
  is $rc->{test}, 1, q{$rc->{test}, 1};


__DATA__
filename: .<e.rc_name>
value: |
  test: 1
