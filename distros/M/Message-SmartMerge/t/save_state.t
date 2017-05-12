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

my $state;
{   ok my $merge = Message::SmartMerge->new(), 'constructor worked';

    ok $merge->config({
        merge_instance => 'a',
    });

    #first validate pass-through
    Message::SmartMerge::Test::mergetest(
        run => sub { $merge->message({x => 'y', a => 'b'}) },
        match_messages => [
            {   x => 'y', a => 'b' }
        ],
    );

    #add a simple merge
    Message::SmartMerge::Test::mergetest(
        match_messages => [
            {   x => 'y', this => 'that' }
        ],
        run => sub {    $merge->add_merge({
                            match => {x => 'y'},
                            transform => {this => 'that'},
                            merge_id => 'm1',
                            expire => 2,
                        })
        }
    );
    #in english, this will match any messages with x => 'y', will expire
    #in 2 seconds, will run the transform this => 'that',
    #and the instance of the message is defined by whatever is in the 'a'
    #field.

    #Now let's do another pass-through, that misses this merge
    Message::SmartMerge::Test::mergetest(
        run => sub { $merge->message({no => 'match', a => 'nomatch'}) },
        match_messages => [
            {   no => 'match', a => 'nomatch' }
        ],
    );

    #Now hit the merge
    Message::SmartMerge::Test::mergetest(
        run => sub { $merge->message({x => 'y', a => 'b', this => 'those', something => 'else'}) },
        match_messages => [
            {   x => 'y', this => 'that', something => 'else' }
        ],
    );

    #Hit it again!
    Message::SmartMerge::Test::mergetest(
        run => sub { $merge->message({x => 'y', a => 'b', this => 'nope', something => 'else', foo => 'bar'}) },
        match_messages => [
            {   x => 'y', this => 'that', something => 'else', foo => 'bar' }
        ],
    );

    #Make sure a stray message goes through normally
    Message::SmartMerge::Test::mergetest(
        run => sub { $merge->message({a => 'bb', c => 'd'}) },
        match_messages => [
            {   a => 'bb', c => 'd' }
        ],
    );
    $state = $merge->get_state();
}

ok my $merge = Message::SmartMerge->new(state => $state), 'constructor worked';

#Now wait a few seconds until the merge expires.
sleep 3;
Message::SmartMerge::Test::mergetest(
    run => sub { $merge->message({a => 'bb', c => 'd'}) },
    match_messages => [
        {   x => 'y', this => 'nope', something => 'else', foo => 'bar' },
        {   a => 'bb', c => 'd' },
    ],
);
done_testing();
__END__
#remove it and make sure we fire
Message::SmartMerge::Test::mergetest(
    run => sub { $merge->remove_merge('m1') },
    match_messages => [
        {   x => 'y', this => 'nope', something => 'else', foo => 'bar' }
    ],
);

#and double-check we're back on pass-through
Message::SmartMerge::Test::mergetest(
    run => sub { $merge->message({x => 'y', a => 'b', something => 'else', this => 'notthat', foo => 'notbar'}) },
    match_messages => [
        {   x => 'y', something => 'else', a => 'b', this => 'notthat', foo => 'notbar' }
    ],
);

#add the merge back
#we still have a message instance, so it should fire right off
#something => 'else' comes from the last message we sent in, as above
Message::SmartMerge::Test::mergetest(
    match_messages => [
        {   x => 'y', this => 'that', something => 'else', foo => 'notbar' }
    ],
    run => sub {    $merge->add_merge({
                        match => {x => 'y'},
                        transform => {this => 'that'},
                        merge_id => 'm1',
                    })
    }
);
#add another merge to the mix
#it's exactly the same match, but with divergent transforms
#this should one message, but with the alternate transform as well
Message::SmartMerge::Test::mergetest(
    match_messages => [
        {   x => 'y', this => 'that', foo => 'bar' }
    ],
    run => sub {    $merge->add_merge({
                        match => {x => 'y'},
                        transform => {foo => 'bar'},
                        merge_id => 'm2',
                    })
    }
);

#let's get another instance in play
#should hit both matches and transforms
Message::SmartMerge::Test::mergetest(
    run => sub { $merge->message({x => 'y', a => 'bb', something => 'else', foo => 'notbar', this => 'notthat'}) },
    match_messages => [
        {   x => 'y', something => 'else', a => 'bb', foo => 'bar', this => 'that' }
    ],
);

#remove the second merge
#We should fire twice, once per instance
#the instances are processed in sort order
Message::SmartMerge::Test::mergetest(
    run => sub { $merge->remove_merge('m2') },
    match_messages => [
        {   a => 'b', x => 'y', something => 'else', this => 'that', foo => 'notbar' },
        {   a => 'bb', x => 'y', foo => 'notbar', something => 'else', this => 'that' },
    ],
);

#now remove the first merge
#We should fire twice, once per instance
#the instances are processed in sort order
Message::SmartMerge::Test::mergetest(
    run => sub { $merge->remove_merge('m1') },
    match_messages => [
        {   a => 'b', x => 'y', something => 'else', this => 'notthat', foo => 'notbar' },
        {   a => 'bb', x => 'y', foo => 'notbar', something => 'else', this => 'notthat' },
    ],
);
done_testing();
