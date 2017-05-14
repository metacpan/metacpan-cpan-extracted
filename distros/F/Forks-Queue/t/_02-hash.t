use Test::More;
use Carp 'verbose';
use Net::Objwrap qw(:all-test);
use 5.012;
use Scalar::Util 'reftype';

my $wrap_cfg = 't/02.cfg';
unlink $wrap_cfg;

my $r0 = { abc => "xyz", def => "foo",
	   ghi => { jkl => ['m','n','o','p',['qrs','tuv']],
		    wxy => 123 } };

ok($r0 && ref($r0) eq 'HASH', 'created remote var');
ok(! -f $wrap_cfg, 'config file does not exist yet');

ok(wrap($wrap_cfg,$r0), 'wrap successful');
ok(-f $wrap_cfg, 'config file created');

my ($r1) = unwrap($wrap_cfg);
ok($r1, 'client as boolean');
ok(ref($r1) eq 'Net::Objwrap::Proxy', 'proxy ref');

ok(tied(%$r1), 'proxy var is tied when dereferenced as hash');
$r1->{tart} = 64;

ok(Net::Objwrap::ref($r1) eq 'HASH', 'remote ref');
ok(Net::Objwrap::reftype($r1) eq 'HASH', 'remote reftype');

is($r1->{def}, 'foo', 'hash access');

$r1->{bar} = 456;
is($r1->{bar}, 456, 'add to remote hash');

$r1->{ghi}{wxy} = 789;

# SIGSEGV failure point on perl v5.10.1
is($r1->{ghi}{wxy}, 789, 'deep update remote hash');

my $s = $r1->{ghi};
is($s->{wxy}, 789, 'deep update remote hash');

is($r1->{ghi}{jkl}[2], 'o', 'deep update did not update other elements');

ok(exists $r1->{ghi}, '1st level key exists');
ok(exists $r1->{ghi}{jkl}, '2nd level key exists');

ok(Net::Objwrap::ref($r1->{ghi}{jkl}) eq 'ARRAY', '2nd level value is ARRAY ref');
is(eval{$r1->{ghi}{jkl}[4][1]}, 'tuv', 'deep update did not update other elements');

is(delete $r1->{abc}, 'xyz', 'delete from remote hash');
is($r1->{abc}, undef, 'delete from remote hash clears');
ok(!exists $r1->{abc}, 'delete from remote hash clears');

done_testing;
