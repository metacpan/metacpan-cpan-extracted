use strict; use warnings;

use Marpa::R2;
use MarpaX::Repa::Lexer;
use MarpaX::Repa::Actions;

my $grammar = Marpa::R2::Grammar->new( {
    action_object => 'MarpaX::Repa::Actions',
    start         => 'query',
    rules         => [
        [ query => [qw(something)] ],
    ],
});
$grammar->precompute;

my $recognizer = Marpa::R2::Recognizer->new( { grammar => $grammar } );
my $lexer = MarpaX::Repa::Lexer->new(
    tokens => {},
    debug => 1,
);

use Data::Dumper;
print Dumper( $lexer->recognize( $recognizer => \*DATA)->value );

__DATA__
hello !world "he hehe hee" ( foo OR boo )

