#!perl

use strict;
use warnings;
use Eliza::Chatbot;
use Test::More 0.88;
use feature 'say';
use Array::Utils qw(array_diff);

BEGIN {
	use_ok( 'Eliza::Chatbot::Option' ) || print "Bail out!\n";
    use_ok( 'Eliza::Chatbot::Brain' ) || print "Bail out!\n";
}
# doesn't store memory so it's actually pretty useless

subtest 'say goodbye in multiple ways' => sub {
	test_preprocess({
		text => 'hello world!',			
	    expected => ['hello world'],			
    });
	test_preprocess({
		text => 'hello recollect?',			
	    expected => ['hello recollect'],			
    });
	test_preprocess({
		text => 'eliza but goodbye',			
	    expected => ['eliza ', ' goodbye'],			
    });
	test_preprocess({
		text => 'done certainly,',			
	    expected => ['done certainly'],			
    });
	test_preprocess({
		text => 'sometext ? which ! is , everything',			
	    expected => ['sometext ', ' which ', ' is ', ' everything'],			
    });
};

done_testing();

sub test_preprocess {
	my $args = shift;

    my $options = Eliza::Chatbot::Option->new();
    my $eliza = Eliza::Chatbot::Brain->new(options => $options);
	my @reply = $eliza->preprocess($args->{text});
	# reply will always have a value
	ok(@reply);
    if ( !array_diff(@reply, @{ $args->{expected} }) ) {
        pass("We went through preprocess $args->{expected}");
    } else {
        fail("Our arrays do not match $args->{expected}");
    }
};

1;
