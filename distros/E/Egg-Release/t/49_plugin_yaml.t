use Test::More tests=> 5;
use lib qw( ./lib ../lib );
use Egg::Helper;

ok $e= Egg::Helper->run
   ( Vtest=> { vtest_plugins=> [qw/ YAML /] }), q{ load plugin. };

can_ok $e, 'yaml_load';
  ok my $ym= $e->yaml_load(join '', <DATA>),
     q{my $ym= $e->yaml_load(join '', <DATA>)};
  is $ym->{test1}, 'OK1', q{$ym->{test1}, 'OK1'};
  is $ym->{test2}, 'OK2', q{$ym->{test2}, 'OK2'};

__DATA__
test1: OK1
test2: OK2
