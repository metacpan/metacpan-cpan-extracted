package Door;

use Moose;
use FSA::Engine::Transition;

with 'FSA::Engine';

sub _build_fsa_transitions {
    my ($self) = @_;

    my $transitions = {
        locked  => {
            unlock_door => FSA::Engine::Transition->new({
                test    => 'TURN KEY CLOCKWISE',
                action  => sub {$self->action_turn_key(@_)},
                state   => 'closed',
            }),
        },
        closed => {
            lock_door   => FSA::Engine::Transition->new({
                test    => 'TURN KEY ANTICLOCKWISE',
                action  => sub {$self->action_turn_key(@_)},
                state   => 'locked',
            }),
            open_door   => FSA::Engine::Transition->new({
                test    => 'PULL DOOR',
                action  => sub {print "There is a rising 'eeerrrRRRKKK' sound\n";},
                state   => 'open',
            }),
        },
        open => {
            slam_door   => FSA::Engine::Transition->new({
                test    => 'SHOVE DOOR',
                action  => sub {print "The door slams shut with a BANG\n";},
                state   => 'closed',
            }),
            close_door  => FSA::Engine::Transition->new({
                test    => sub {$self->test_door_push(@_)},
                action  => sub {print "There is a falling 'EEERRRrrrkkk' sound\n";},
                state   => 'closed',
            }),
        },
    };
    return $transitions;
}

sub _build_fsa_states {
    my ($self) = @_;

    my $states = {
        locked => {
            entry_action    => sub {print "The door is locked\n";},
            exit_action     => sub {print "We are about to unlock the door\n";},
        },
        closed => {
            entry_action    => sub {print "The door is closed but unlocked\n";},
        },
        open => {
            entry_action    => sub {print "The door is open\n";},
            exit_action     => sub {print "We are about to shut the door\n";},
        },
    };
    return $states;
}

sub action_turn_key {
    my ($self, $input) = @_;

    print "There is a quiet 'click'\n";
}

sub test_door_push {
    my ($self, $input) = @_;
    return uc $input eq 'PUSH DOOR'
}

1;