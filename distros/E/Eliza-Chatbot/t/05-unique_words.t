#!perl -T

use strict;
use warnings;
use Test::More;
use feature 'say';

BEGIN {
	use_ok( 'Eliza::Chatbot::ScriptParser' ) || print "Bail out!\n";
}

subtest 'unique_words' => sub {
	my $parser = Eliza::Chatbot::ScriptParser->new();
	unique_words({
		instance => $parser,
        words => 'blah foo hello world',
		unique_count => 4
	});
    unique_words({
        instance => $parser,
        words => 'hello hello world order',
        unique_count => 5
    });
    unique_words({
        instance => $parser,
        words => 'one two three three three',
        unique_count => 8
    });
};

done_testing();

sub unique_words {
    my $args = shift;
    my $parser = $args->{instance};
	$parser->_unique_words($args->{words});
    is(scalar keys %{$parser->unique_words}, $args->{unique_count}, "expected count $args->{unique_count}"); 
}
