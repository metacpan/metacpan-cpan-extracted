# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Linux-Pdeathsig.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Linux::Pdeathsig') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $rv = set_pdeathsig(10);
ok(defined $rv && $rv == 0,'set_pdeathsig succeeded');
is(get_pdeathsig(), 10,'get_pdeathsig returned 10');

sub invalid_set_pdeathsig {
    eval {
        set_pdeathsig(-20);
    };
    if ($@) {
        return $@;
    } else {
        return;
    }
}

ok(invalid_set_pdeathsig() =~ /^set_pdeathsig failed: Invalid argument/, 'invalid set_pdeathsig died');
