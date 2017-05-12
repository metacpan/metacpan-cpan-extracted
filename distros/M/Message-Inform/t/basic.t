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
                '2' => [   #2 seconds
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

#some static should not change anything until 2 seconds have gone by
ok $inform->message({no => 'match'}), 'another no match message';
ok $action_global_count == 1, 'still only one action';
sleep 1;
ok $inform->message({no => 'match'}), 'yet another no match message';
ok $action_global_count == 1, 'still only one action';
sleep 2;

#now we'll fire for the 2 second interval
ok $inform->message({no => 'match'}), 'non-matching message, trigger second interval';
ok $action_global_count == 2, 'second interval triggered';
ok $action_global->{inform_instance_name} eq 'i1:b', 'instance still set correctly';
ok $action_global->{interval_time} == 2, 'interval_time set correctly';
ok $action_global->{action}->{action_type} eq 'open', 'action_type set correctly';

#let's put some more static in and make sure nothing changes
ok $inform->message({no => 'match'}), 'non-matching message';
ok $action_global_count == 2, 'verify no actions triggered';
sleep 1;
ok $inform->message({no => 'match'}), 'non-matching message';
ok $action_global_count == 2, 'verify no actions triggered';

#send an intermediate through
ok $inform->message({x => 'y', a => 'b'}), 'message to trigger 2 second interval intermediate';
#need to implement trigger intermediate, line 306
#search for comment comment: this is an 'intermediate' in Inform.pm
ok $action_global_count == 3, 'verify action triggered';
ok $action_global->{interval_time} == 2, 'interval_time correctly at 2 seconds';
ok $action_global->{action}->{action_type} eq 'intermediate', 'action_type correctly set to intermediate';

#one more verifiction nothing else will change
ok $inform->message({no => 'match'}), 'non-matching message';
ok $action_global_count == 3, 'verify no actions triggered';

#and now a close
ok $inform->message({x => 'y', a => 'b', level => 'OK'}), 'trigger a close';
#only the inform at 0 seconds had a close, so we should only fire one action
ok $action_global_count == 4, 'close action fired';
ok $action_global->{action}->{action_type} eq 'close', 'verify close action fired';

done_testing();

