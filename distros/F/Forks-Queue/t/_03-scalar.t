use Test::More;
use Carp 'verbose';
use Net::Objwrap ':all-test';
use strict;
use warnings;
use Scalar::Util 'reftype';

ok(1, '# skip - Net::Objwrap does not work with SCALAR references yet');

#done_testing;
#exit;
#
#$Net::Objwrap::Server::DEFAULT{idle_timeout} = 1;
#$Net::Objwrap::Server::DEFAULT{keep_alive} = 1;
#$Net::Objwrap::Server::DEFAULT{alarm_freq} = 2;

my $wrap_cfg = 't/03.cfg';
unlink $wrap_cfg;

my $foo = "42";
my $r0 = \$foo;

ok($r0 && ref($r0) eq 'SCALAR', 'created remote var');
ok(! -f $wrap_cfg, 'config file does not exist yet');

ok(wrap($wrap_cfg,\$foo), 'wrap successful');
ok(-f $wrap_cfg, 'config file created');

my $r1 = unwrap($wrap_cfg);
ok($r1, 'client as boolean');
ok(ref($r1) eq 'Net::Objwrap::ProxyS', 'proxy ref');

ok(Net::Objwrap::ref($r1) eq 'SCALAR', 'remote ref');
ok(Net::Objwrap::reftype($r1) eq 'SCALAR', 'remote reftype');

is($$r1, 42, 'scalar access');

${$r1} = 456;
is($$r1, 456, 'update scalar');

$$r1 += 15;
is($$r1, 471, 'update scalar with assignment operator');

done_testing;
