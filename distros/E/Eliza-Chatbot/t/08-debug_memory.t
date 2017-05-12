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
my $options = Eliza::Chatbot::Option->new(); 
my $eliza = Eliza::Chatbot::Brain->new(options => $options);
	
subtest 'debug_memory' => sub {
	debug_memory({
		memory => 'goodbye',			
	});
	debug_memory({
		memory => 'bye eliza',			
	});
	debug_memory({
		memory => 'eliza goodbye',			
	});
	debug_memory({
		memory => 'done',			
	});
	debug_memory({
		memory => 'exit',			
	});
	debug_memory({
		memory => 'quit',			
	});
};

done_testing();

sub debug_memory {
	my $args = shift;

    push @{ $eliza->options->memory }, $args->{memory};
    ok(my $reply = $eliza->_debug_memory);
    say $reply;
};

1;
