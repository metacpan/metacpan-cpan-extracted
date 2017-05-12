package Conf1;
use lib './lib';
use LEOCHARRE::Class2;
use strict;
__PACKAGE__->make_constructor;
__PACKAGE__->make_conf;

1;

package Conf2;
use lib './lib';
use LEOCHARRE::Class2;
use strict;
__PACKAGE__->make_constructor;
__PACKAGE__->make_conf('/etc/conf2.conf');

1;








use Test::Simple 'no_plan';
use strict;
use lib './t';
use lib './lib';
use Smart::Comments '###';
ok(1);


### object 1
my $a = Conf1->new;
ok($a, 'object instanced');

my $r = $a->abs_conf;
ok !$r, "abs conf is not";


### object 2
my $b = Conf2->new;
ok $b, 'obj2';

my $r = $b->abs_conf;
ok $r, "abs conf is $r";

my @k = $b->conf_keys;
ok !@k;


### c
unlink './t/tmp.conf';
my $c = Conf1->new({ abs_conf => './t/tmp.conf' });
ok($c, 'object instanced');

$r = $c->abs_conf;
ok $r, "have abs conf";

ok( ! $c->conf_keys );

$c->conf({});
ok $c->conf->{abra} = 'cadabra';

ok $c->conf_save;

$r = $c->abs_conf;
### abs conf : $r

### d
my $d = new Conf2;
ok $d->abs_conf('./t/tmp.conf');

my @kk;
ok( @kk = $d->conf_keys ,'got back conf keys');
warn " conf key:$_\n" for @kk;



unlink './t/tmp.conf';
