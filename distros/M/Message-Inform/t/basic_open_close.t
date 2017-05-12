#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;

BEGIN {
    use_ok( 'Message::Inform' ) || print "Bail out!\n";
}
our $action_global = {};
our $action_global_count = 0;
sub a1 {
    my %args = @_;
    #$args{message}
    #$args{action}
    #$args{inform_instance}
    #$args{inform_instance_name}
    #$args{interval_time}
    $action_global = \%args;
    $action_global_count++;
}

ok my $inform = Message::Inform->new, 'constructor worked';
ok $inform->config({
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
            }
        }
    ],
    action_map => {
        a1 => 'main::a1',
    },
}), 'basic config';
ok scalar keys %$action_global == 0, 'sanity check';
ok $action_global_count == 0, 'another sanity check';
ok $inform->message({no => 'match'}), 'message that matches no config';
ok ((not $action_global->{message}), 'verify no config was run');
ok $action_global_count == 0, 'really sure message matched no config';
ok $inform->message({x => 'y', a => 'b'}), 'message that matches config';
ok $action_global->{message}, 'verify config was run';
ok $action_global_count == 1, 'verify only one action';
ok $action_global->{message}->{a} eq 'b', 'message was saved correctly';
ok $action_global->{inform_instance_name} eq 'i1:b', 'instance set correctly';
ok $action_global->{interval_time} == 0, 'interval_time set correctly';
ok $action_global->{action}, 'action sent in correctly';
ok $action_global->{action}, 'action sent in correctly';
ok $action_global->{action}->{action_type} eq 'open', 'action_type set correctly';

#now close it out
ok $inform->message({x => 'y', a => 'b', level => 'OK'}), 'close message sent';
ok $action_global_count == 2, 'verify only one open, one close';
ok $action_global->{action}->{action_type} eq 'close', 'action_type set correctly to close';

#and make sure it is actually closed.
#we do this by sending another message in; this should fire an 'intermediate'.
#if it fires an 'open', the 'close' didn't properly deallocate the instance
ok $inform->message({x => 'y', a => 'b'}), 'message should be an open, not an intermediate';
ok $action_global->{action}->{action_type} eq 'open', 'action_type set correctly to open';

done_testing();

