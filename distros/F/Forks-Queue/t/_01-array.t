use Test::More;
use Carp 'verbose';
use Net::Objwrap qw(:test wrap unwrap);
use 5.012;
use Scalar::Util 'reftype';

my $wrap_cfg = 't/01.cfg';
unlink $wrap_cfg;

my $r0 = [ 1, 2, 3, 4 ];

ok($r0 && ref($r0) eq 'ARRAY', 'created remote var');
ok(! -f $wrap_cfg, 'config file does not exist yet');

ok(wrap($wrap_cfg,$r0), 'wrap successful');
ok(-f $wrap_cfg, 'config file created');

my ($r1) = unwrap($wrap_cfg);
ok($r1, 'client as boolean');
is(ref($r1), 'Net::Objwrap::Proxy', 'client ref');

ok(Net::Objwrap::ref($r1) eq 'ARRAY', 'remote ref');
ok(Net::Objwrap::reftype($r1) eq 'ARRAY', 'remote reftype');

is($r1->[3], 4, 'array access');

push @$r1, [15,16,17], 18;
is($r1->[-3], 4, 'push to remote array');

$r1->[2] = 19;
is($r1->[2], 19, 'set remote array');

is(shift @$r1, 1, 'shift from remote array');

unshift @$r1, (25 .. 31);
is($r1->[6], 31, 'unshift to remote array');
is($r1->[7], 2, 'unshift to remote array');

is(pop @$r1, 18, 'pop from remote array');

my $r6 = $r1->[10];
is(ref($r6), 'Net::Objwrap::Proxy', 'proxy handle for nested remote obj');

done_testing;
