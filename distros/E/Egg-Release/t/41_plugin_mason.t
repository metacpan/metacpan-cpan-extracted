use Test::More tests=> 30;
use lib qw( ./lib ../lib );
use Egg::Helper;

require_ok 'Egg::Plugin::Mason';

ok $e= Egg::Helper->run
   ( Vtest=> { vtest_plugins=> [qw/ Mason /] }), q{load plugin.};

can_ok $e, 'mason';
  ok my $ms= $e->mason, q{my $ms= $e->mason};
  isa_ok $ms, 'Egg::Plugin::Mason::handler';

can_ok $ms, 'prepare';
  isa_ok $ms->prepare, 'HASH';

can_ok $ms, 'attr';
  isa_ok $ms->attr, 'HASH';

can_ok $ms, 'code_first';
  isa_ok $ms->code_first, 'CODE';

can_ok $ms, 'code_action';
  isa_ok $ms->code_action, 'CODE';

can_ok $ms, 'code_final';
  isa_ok $ms->code_final, 'CODE';

can_ok $ms, 'exec';

can_ok $ms, 'complete';
  ok $ms->complete('Test OK', 'Test info'),
     q{$ms->complete('Test OK', 'Test info')};

can_ok $ms, 'is_complete';
  ok $ms->is_complete, q{$ms->is_complete};

can_ok $ms, 'complete_topic';
  is $ms->complete_topic, 'Test OK', q{$ms->complete_topic, 'Test OK'};

can_ok $ms, 'complete_info';
  is $ms->complete_info, 'Test info', q{$ms->complete_info, 'Test info'};

$ms->is_complete(0);
$ms->complete_topic(undef);
$ms->complete_info(undef);

can_ok $ms, 'error_complete';
  ok ! $ms->error_complete('Error OK', 'Error info'),
     q{! $ms->error_complete('Error OK', 'Error info')};

can_ok $ms, 'is_error';
  ok $ms->is_error, q{$ms->is_error};

is $ms->complete_topic, 'Error OK', q{$ms->complete_topic, 'Error OK'};
is $ms->complete_info, 'Error info', q{$ms->complete_info, 'Error info'};

