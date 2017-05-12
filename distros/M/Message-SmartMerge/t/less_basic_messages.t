#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Message::Match;
use Message::Transform;
use Data::Dumper;

BEGIN {
    use_ok('Message::SmartMerge') || print "Bail out!\n";
    use_ok('Message::SmartMerge::Test') || print "Bail out!\n";
}

ok my $merge = Message::SmartMerge->new(), 'constructor worked';

ok $merge->config({
    merge_instance => 'a',
});

#first validate pass-through
Message::SmartMerge::Test::mergetest(
    run => sub { $merge->message({x => 'y', a => 'b', this => 'notthat'}) },
    match_messages => [
        {   x => 'y', a => 'b' }
    ],
);


#add a simple merge
Message::SmartMerge::Test::mergetest(
    match_messages => [
        {   x => 'y', this => 'that', a => 'b' }
    ],
    run => sub {    $merge->add_merge({
                        match => {x => 'y'},
                        transform => {this => 'that'},
                        merge_id => 'm1',
                    })
    }
);
#add a less simple merge
Message::SmartMerge::Test::mergetest(
    match_messages => [
    ],
    run => sub {    $merge->add_merge({
                        match => {x => 'y', i => 'j'},
                        transform => {hey => 'there'},
                        merge_id => 'm2',
                        expire => 2,
                    })
    }
);

#this message hits both merges
Message::SmartMerge::Test::mergetest(
    run => sub { $merge->message({x => 'y', a => 'b', i => 'j', this => 'notthat', hey => 'notthere'}) },
    match_messages => [
        {   x => 'y', a => 'b', i => 'j', this => 'that', hey => 'there' }
    ],
);

#this message hits only m1
Message::SmartMerge::Test::mergetest(
    run => sub { $merge->message({x => 'y', a => 'b', i => 'j', this => 'notthat', hey => 'notthere'}) },
    match_messages => [
        {   x => 'y', a => 'b', i => 'j', this => 'that', hey => 'there' }
    ],
);

#wait for m2 to expire
sleep 3;

#this would hit both merges, but m2 should be expired.
#as such, we'll get a message for the m2 expire, as well as this message
#proper
Message::SmartMerge::Test::mergetest(
    run => sub { $merge->message({x => 'y', a => 'b', i => 'j', this => 'notthat', hey => 'notthere'}) },
    match_messages => [
        {   x => 'y', a => 'b', i => 'j', this => 'that', hey => 'notthere' },
        {   x => 'y', a => 'b', i => 'j', this => 'that', hey => 'notthere' },
    ],
);

#add a toggle merge
#I am not passing the toggle_field 'f', so it'll default to 'unknown'
Message::SmartMerge::Test::mergetest(
    match_messages => [
        {   x => 'y', a => 'b', i => 'j', this => 'that', hey => 'notthere' },
    ],
    run => sub {    $merge->add_merge({
                        match => {x => 'y', i => 'j'},
                        transform => {hey => 'there'},
                        merge_id => 'm2',   #intentionally re-use the merge_id
                                            #try to dig up some inappropriately
                                            #lingering data structures
                        toggle_fields => ['f'],
                    })
    }
);

Message::SmartMerge::Test::mergetest(
    run => sub { $merge->message({x => 'y', a => 'b', i => 'j', this => 'notthat', hey => 'notthere', f => 'unknown'}) },
    match_messages => [
        {   x => 'y', a => 'b', i => 'j', this => 'that', hey => 'notthere', f => 'unknown' },
    ],
);

#for a toggle merge, any new message instance that comes in and matches
#will immediately clear the toggle, because the previous and current will
#differ, since there was no previous
#another message instance, hits both merges, but toggle merge does transform
Message::SmartMerge::Test::mergetest(
    run => sub { $merge->message({x => 'y', a => 'bb', i => 'j', this => 'notthat', hey => 'notthere', f => 'initial'}) },
    match_messages => [
        {   x => 'y', a => 'bb', i => 'j', this => 'that', hey => 'notthere', f => 'initial' },
    ],
);

#should act exactly as the previous
Message::SmartMerge::Test::mergetest(
    run => sub { $merge->message({x => 'y', a => 'bb', i => 'j', this => 'notthat', hey => 'notthere', f => 'initial'}) },
    match_messages => [
        {   x => 'y', a => 'bb', i => 'j', this => 'that', hey => 'notthere', f => 'initial' },
    ],
);

#now trip the toggle, though it really should already be tripped
Message::SmartMerge::Test::mergetest(
    run => sub { $merge->message({x => 'y', a => 'bb', i => 'j', this => 'notthat', hey => 'notthere', f => 'trip'}) },
    match_messages => [
        {   x => 'y', a => 'bb', i => 'j', this => 'that', hey => 'notthere', f => 'trip' },
    ],
);

#add another toggle merge
#We have two instances going on, 'b' and 'bb'.  'bb' has the toggle field
#defined as 'trip', and 'b' has it defined as 'unknown'.  So this new merge
#should catch both of them
#m2, the previous toggle merge, should catch neither
Message::SmartMerge::Test::mergetest(
    match_messages => [
        {   x => 'y', a => 'b', i => 'j', this => 'that', hey => 'notthere', another => 'transform', f => 'unknown' },
        {   x => 'y', a => 'bb', i => 'j', this => 'that', hey => 'notthere', another => 'transform', f => 'trip' },
    ],
    run => sub {    $merge->add_merge({
                        match => {x => 'y', i => 'j'},
                        transform => {another => 'transform'},
                        merge_id => 'm3',   #intentionally re-use the merge_id
                                            #try to dig up some inappropriately
                                            #lingering data structures
                        toggle_fields => ['f'],
                    })
    }
);

#just send another one through for fun
Message::SmartMerge::Test::mergetest(
    run => sub { $merge->message({x => 'y', a => 'bb', i => 'j', this => 'notthat', hey => 'notthere', f => 'trip', something => 'else', another => 'nottransform'}) },
    match_messages => [
        {   x => 'y', a => 'bb', i => 'j', this => 'that', hey => 'notthere', f => 'trip', another => 'transform', something => 'else' },
    ],
);

#trip the 'bb' toggle
Message::SmartMerge::Test::mergetest(
    run => sub { $merge->message({x => 'y', a => 'bb', i => 'j', this => 'notthat', hey => 'notthere', f => 'after-trip', something => 'else', another => 'nottransform'}) },
    match_messages => [
        {   x => 'y', a => 'bb', i => 'j', this => 'that', hey => 'notthere', f => 'after-trip', another => 'nottransform', something => 'else' },
    ],
);

#remove m3; this should only fire on instance 'b'
#TODO
#Message::SmartMerge::Test::mergetest(
#    run => sub { $merge->remove_merge('m3') },
#    match_messages => [
#        {   x => 'y', a => 'b', this => 'nope', something => 'else', foo => 'bar' }
#    ],
#);

done_testing();
