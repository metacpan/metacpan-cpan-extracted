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

my %FINAL = (
	q{Goodbye.  It was nice talking to you.} => 1, 
	q{Goodbye.  I hope you found this session helpful.} => 1, 
	q{I think you should talk to a REAL analyst.  Ciao!} => 1, 
	q{Life is tough.  Hang in there!} => 1,
);

my $eliza = Eliza::Chatbot->new();
subtest 'test_quit' => sub {
	test_quit({
		text => 'bye',
	});
	test_quit({
		text => 'goodbye eliza',
	});
	test_quit({
		text => 'quit',
	});
	test_quit({
		text => 'exit eliza',
	});
	test_quit({
		text => 'quit i am done',
	});
};

done_testing();

sub test_quit {
	my $args = shift;

    ok(my $reply = $eliza->instance($args->{text}));
    # reply will always have a value
    
    is($FINAL{$reply}, 1, "Eliza said goodbye - $reply");
};

1;
