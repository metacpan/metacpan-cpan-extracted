#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;

BEGIN {
    plan tests => 12;
    use_ok( 'Message::Inform' ) || print "Bail out!\n";
}
our $action_global = {};
our $action_global_count = 0;
sub a1 {
    my %args = @_;
    #$args{message}
    #$args{action}
    #$args{action_type}
    #$args{inform_instance}
    #$args{interval_time}
    $action_global = \%args;
    $action_global_count++;
    return { what => 'ever' };
}

ok my $inform = Message::Inform->new, 'constructor worked';
my $config = {
    informs => [
        {   inform_name => 'i1',
            match => { x => 'y' },
            close_match => { x => 'y', level => 'OK' },
            instance => ' specials/"i1:$message->{a}"',
            intervals => {
                '0' => [    #right away
                    {   action_type => 'open',
                        action_name => 'a1',
                    },{ action_type => 'close',
                        action_name => 'a1',
                    }
                ],
                '2' => [   #2 seconds
                    {   action_type => 'open',
                        action_name => 'a1',
                    },{ action_type => 'intermediate',
                        action_name => 'a1',
                    }
                ],
            }
        },{ inform_name => 'i2',
            match => { x => 'y' },

            #the next line is unusual and would probably never happen, but it
            #is useful for this test
            close_match => { x => 'y', level => 'OK', no => 'match'},
            instance => ' specials/"i1:$message->{a}"',
            intervals => {
                '0' => [    #right away
                    {   action_type => 'open',
                        action_name => 'a1',
                    },{ action_type => 'close',
                        action_name => 'a1',
                    }
                ],
                '2' => [   #2 seconds
                    {   action_type => 'open',
                        action_name => 'a1',
                    },{ action_type => 'intermediate',
                        action_name => 'a1',
                    }
                ],
                '3' => [   #3 seconds
                    {   action_type => 'open',
                        action_name => 'a1',
                    },{ action_type => 'intermediate',
                        action_name => 'a1',
                    }
                ],
            }
        }
    ],
    action_map => {
        a1 => 'main::a1',
    },
};
ok $inform->config($config), 'basic config';
ok scalar keys %$action_global == 0, 'sanity check';
ok $action_global_count == 0, 'another sanity check';
ok my $ret = $inform->fire_action({some => 'thing', a => 'b'}, $config->{informs}->[0]->{intervals}->{'0'}->[0], something => 'else'), 'action ran successfull';
ok $ret->{what} eq 'ever', 'validated action return value';
ok $action_global->{action}, 'verify config was run';
ok $action_global_count == 1, 'verify only one action';
ok $action_global->{message}, 'message was saved';
ok $action_global->{message}->{a} eq 'b', 'message was saved correctly';
ok $action_global->{something} eq 'else', 'verify additional attribute';


#TODO:  check for errors in fire_action calls

