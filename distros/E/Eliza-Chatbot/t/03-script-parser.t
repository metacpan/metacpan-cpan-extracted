#!perl -T

use strict;
use warnings;
use Test::More;
use feature 'say';
use Ref::Util qw(is_hashref is_arrayref);

BEGIN {
	use_ok( 'Eliza::Chatbot::ScriptParser' ) || print "Bail out!\n";
}

subtest 'test the base script' => sub {
	test_script({
        quit => 5,
        initial => 4,
        decomp => 48,
	    pre => 18,
        post => 10,
        synon => 8,
        key => 48,
        unique_words => 405,
        final => 4,
    });
};

done_testing();

sub test_script {
    my $args = shift;
	my $parser = Eliza::Chatbot::ScriptParser->new();
	my $data = $parser->parse_script_data;

    foreach my $field ( keys %{ $args }) {
        if ( is_hashref($parser->$field) ) {
            is($args->{$field}, scalar (keys %{ $parser->$field }), "Correct count for $field");
        }
        elsif ( is_arrayref($parser->$field) ) {
            is($args->{$field}, scalar (@{ $parser->$field }), "Correct count for $field");
        }
        else {
            fail('test the base script');
        }
    }
}
