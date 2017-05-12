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
		text => 'goodbye',			
	});
	test_quit({
		text => 'bye eliza',			
	});
	test_quit({
		text => 'eliza goodbye',			
	});
	test_quit({
		text => 'done',			
	});
	test_quit({
		text => 'exit',			
	});
	test_quit({
		text => 'quit',			
	});
};

done_testing();

sub test_quit {
	my $args = shift;

    my $options = Eliza::Chatbot::Option->new();
    my $eliza = Eliza::Chatbot::Brain->new(options => $options);
	my $reply = $eliza->_test_quit($args->{text});
	# reply will always have a value
	is($reply, 1, "test quit success");
};

1;
