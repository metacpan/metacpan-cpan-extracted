#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use FindBin::libs;
use Test::More;
use Test::Output;

BEGIN {
    use_ok('Door');
}

my $door;
stdout_is(sub { $door = Door->new({fsa_state => 'locked'});}, "The door is locked\n", "Initial locked state");

isa_ok($door, 'Door');
is($door->fsa_state, 'locked', "Initial locked state");

my $new_state;
stdout_is(
    sub { $new_state = $door->fsa_check_state('TURN KEY CLOCKWISE');},
    "We are about to unlock the door\nThere is a quiet 'click'\nThe door is closed but unlocked\n",
    "Turn key clockwise"
);

is($new_state, 'closed', "Door is now closed but unlocked");

stdout_is(
    sub { $new_state = $door->fsa_check_state('TURN KEY ANTICLOCKWISE');},
    "There is a quiet 'click'\nThe door is locked\n",
    "Turn key anti-clockwise"
);

is($new_state, 'locked', "Door is locked again");

stdout_is(
    sub { $new_state = $door->fsa_check_state('TURN KEY CLOCKWISE');},
    "We are about to unlock the door\nThere is a quiet 'click'\nThe door is closed but unlocked\n",
    "Turn key clockwise"
);

is($new_state, 'closed', "Door is now closed but unlocked again");

stdout_is(
    sub { $new_state = $door->fsa_check_state('TURN KEY CLOCKWISE');},
    "",
    "Turn key clockwise again"
);

is($new_state, undef, "state unchanged: Door is still closed and unlocked");

stdout_is(
    sub { $new_state = $door->fsa_check_state('PUSH DOOR');},
    "",
    "Push against shut door"
);

is($new_state, undef, "state unchanged: Can't push against a closed door");

stdout_is(
    sub { $new_state = $door->fsa_check_state('PULL DOOR');},
    "There is a rising 'eeerrrRRRKKK' sound\nThe door is open\n",
    "Pull against shut door"
);

is($new_state, 'open', "Door is pulled open");

stdout_is(
    sub { $new_state = $door->fsa_check_state('TURN KEY CLOCKWISE');},
    "",
    "Turn key clockwise when door is open"
);

is($new_state, undef, "state unchanged: Can't lock an open door");

stdout_is(
    sub { $new_state = $door->fsa_check_state('TURN KEY ANTICLOCKWISE');},
    "",
    "Turn key anti-clockwise when door is open"
);

is($new_state, undef, "state unchanged: Can't unlock an open door");

stdout_is(
    sub { $new_state = $door->fsa_check_state('PULL DOOR');},
    "",
    "Pull against an open door"
);

is($new_state, undef, "state unchanged: Can't open an open door");

stdout_is(
    sub { $new_state = $door->fsa_check_state('PuSh DoOr');},
    "We are about to shut the door\nThere is a falling 'EEERRRrrrkkk' sound\nThe door is closed but unlocked\n",
    "PuSh DoOr is recognised"
);

is($new_state, 'closed', "Mixed case state is recognised");

stdout_is(
    sub { $new_state = $door->fsa_check_state('PULL DOOR');},
    "There is a rising 'eeerrrRRRKKK' sound\nThe door is open\n",
    "Pull against shut door"
);

is($new_state, 'open', "Door is pulled open");

stdout_is(
    sub { $new_state = $door->fsa_check_state('SHOVE DOOR');},
    "We are about to shut the door\nThe door slams shut with a BANG\nThe door is closed but unlocked\n",
    "Shoved door"
);

is($new_state, 'closed', "Door is slammed closed");

done_testing();
1;
