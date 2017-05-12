use Test::More tests=> 7;
use strict;
use warnings;
use lib qw( ../lib ./lib );
use Egg::Helper;

my $e= Egg::Helper->run('vtest');

can_ok $e, 'log';
  ok my $log= $e->log, q{my $log= $e->log};
  isa_ok $log, 'Egg::Log::STDERR';

can_ok $log, 'error';
can_ok $log, 'debug';
can_ok $log, 'info';
can_ok $log, 'notice';
