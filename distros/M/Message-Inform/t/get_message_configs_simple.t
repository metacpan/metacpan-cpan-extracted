#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;

BEGIN {
    plan tests => 8;
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
}), 'basic config';
{   my $ret = $inform->get_message_configs({no => 'match'});
    is_deeply($ret, { match => {}, close_match => {} }, 'unrelated message correctly returned nothing');

}
{   my $ret = $inform->get_message_configs({x => 'y', a => 'b', level => 'OK'});
    ok(scalar keys %{$ret->{match}->{'i1:b'}->{intervals}} == 3, 'match intervals config correctly merged to three');
    ok($ret->{match}->{'i1:b'}->{inform_name} eq 'i2', 'verified that we merged second inform config');

    ok(scalar keys %{$ret->{close_match}->{'i1:b'}->{intervals}} == 2, 'close_match intervals config did not merge');
    ok($ret->{close_match}->{'i1:b'}->{inform_name} eq 'i1', 'verified that we stuck to only the first inform');
}

