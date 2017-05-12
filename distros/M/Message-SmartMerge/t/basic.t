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
*test = *Message::SmartMerge::Test::get_global_message;

ok my $merge = Message::SmartMerge->new(), 'constructor worked';

ok $merge->config({
    merge_instance => 'a',
});


#first validate pass-through
ok $merge->message({x => 'y', a => 'b'});
ok test()->{x} eq 'y';
#ok Message::SmartMerge::Test::get_global_message()->{x} eq 'y';
#ok $global_message->{x} eq 'y';
#undef $global_message;

#add a simple merge
ok $merge->add_merge({
    match => {x => 'y'},
    transform => {this => 'that'},
    merge_id => 'm1',
});
#in english, this will match any messages with x => 'y', will never
#expire (no expire field), will run the transform this => 'that',
#and the instance of the message is defined by whatever is in the 'a'
#field.
{   my $ret = test();
    ok $ret->{x} eq 'y';
    ok $ret->{a} eq 'b';
    ok $ret->{this} eq 'that';
}

#Now let's do another pass-through, that misses this merge
ok $merge->message({no => 'match', a => 'bb'});
#ok $global_message->{no} eq 'match';
ok test()->{no} eq 'match';
#ok not defined $global_message->{this};
#undef $global_message;


#Now hit the merge
ok $merge->message({x => 'y', a => 'b', this => 'those', something => 'else'});
{   my $ret = test();
    ok $ret->{x} eq 'y', 'match passed through';
    ok $ret->{this} eq 'that', 'transformed correctly';
    ok $ret->{something} eq 'else', 'innocent bystandard unmolested';
}

#Hit it again!
ok $merge->message({x => 'y', a => 'b', this => 'nope', something => 'else', foo => 'bar'});
{   my $ret = test();
    ok $ret->{x} eq 'y', 'match passed through again';
    ok $ret->{this} eq 'that', 'transformed correctly again';
    ok $ret->{something} eq 'else', 'innocent bystandard unmolested again';
}

#remove it and make sure we fire
ok $merge->remove_merge('m1');
{   my $ret = test();
    ok $ret->{x} eq 'y', 'match fired after merge deallocation';
    ok $ret->{this} eq 'nope', 'the most recently received message value was sent';
    ok $ret->{something} eq 'else', 'innocent bystandard still unmolested';
    ok $ret->{foo} eq 'bar', 'foo was only sent with the last message, and it was correctly sent after merge removal';
}

#and double-check we're back on pass-through
ok $merge->message({x => 'y', a => 'b', something => 'else'});
{   my $ret = test();
    ok $ret->{x} eq 'y', 'match passed after merge deallocation';
    ok $ret->{something} eq 'else', 'innocent bystandard STILL unmolested';
    ok ((not defined $ret->{this}), 'the transform correctly did not run');
}

done_testing();
