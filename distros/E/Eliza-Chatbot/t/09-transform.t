#!perl

use strict;
use warnings;
use Eliza::Chatbot;
use Test::More 0.88;
use feature 'say';

BEGIN {
	use_ok( 'Eliza::Chatbot::Option' ) || print "Bail out!\n";
    use_ok( 'Eliza::Chatbot::Brain' ) || print "Bail out!\n";
}
# doesn't store memory so it's actually pretty useless

subtest 'test_quit' => sub {
	test_quit({
		text => 'I feel happy',
        expected => 'Do you often feel happy?'
	});
	test_quit({
		text => 'I like blueberries',
        expected => 'I like blueberries too!',
	});
	test_quit({
		text => 'xyzzy',
        expected => 'Huh?'
	});
};

done_testing();

sub test_quit {
	my $args = shift;

    my $options = Eliza::Chatbot::Option->new(script_file => 't/test-script.txt');
    my $eliza = Eliza::Chatbot::Brain->new(options => $options);
    ok(my $reply = $eliza->transform($args->{text}, ''));
	# reply will always have a value
	is($reply, $args->{expected}, "transform some text expecting $args->{expected}");
};

1;
