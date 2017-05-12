# Verify state() Function Part 1: The Saving

use strict;
use warnings;

use Test::More 'tests' => 2007;
use Data::Dumper;

use_ok('Math::Random::MT::Auto', qw(irand get_state set_state));
can_ok('main', qw(irand get_state set_state));


# Work the PRNG a bit
my $rn;
for (1 .. 500) {
    eval { $rn = irand(); };
    ok(! $@,                  'irand() died: ' . $@);
    ok(defined($rn),          'Got a random number');
    ok(Scalar::Util::looks_like_number($rn),'Is a number: ' . $rn);
    ok(int($rn) == $rn,       'Integer: ' . $rn);
}


# Get state
my @my_state;
eval { @my_state = get_state(); };
ok(! $@, 'get_state() died: ' . $@);


# Get some numbers to save
my @rn;
for (1 .. 500) {
    push(@rn, irand());
}


our @state = @my_state;
if ($] > 5.006) {
    # Save state to file
    if (open(FH, '>state_data.tmp')) {
        print(FH Data::Dumper->Dump([\@my_state], ['*state']));
        print(FH "1;\n");
        close(FH);
    } else {
        diag('Failure writing state to file');
    }


    # Read state and numbers from file
    my $rc = do('state_data.tmp');
    unlink('state_data.tmp');
}
is_deeply(\@state, \@my_state  => 'state from file');

# Set state
eval { set_state(\@state); };
ok(! $@, 'set_state() died: ' . $@);

# Check state
my @got_state = get_state();
is_deeply(\@got_state, \@state, => 'get_state ok');


# Compare numbers after restoration of state
my @rn2;
for (1 .. 500) {
    push(@rn2, irand());
}
is_deeply(\@rn, \@rn2, 'Same results after state restored');

exit(0);

# EOF
