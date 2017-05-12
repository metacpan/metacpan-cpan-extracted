
# Basic lexer driver.
# @author Joel Dalley
# @version 2014/Apr/14
# @version 2014/Jun/02 - rewrite to use external Javascript corpus.

use lib '../../../'; # Needed for development.

use JBD::Parser::DSL;
use JBD::Javascript::Lexers;

use File::Slurp 'read_file';
use JBD::Core::List 'pairsof';

my @cfg = (
    'comments.js' => [
        LineTerminator, LineTerminatorSequence, Comment
        ],
    'digits.js' => [
        WhiteSpace, DecimalLiteral, HexIntegerLiteral, 
        DecimalIntegerLiteral, ExponentPart, SignedInteger,
        Infinity
        ],
    'boolean_and_null.js' => [
        WhiteSpace, BooleanLiteral, NullLiteral
        ],
    );

my $iter = pairsof @cfg;
while (my $pair = $iter->()) {
    my ($file, $lexers) = @$pair;
    my $js     = read_file "javascript_corpus/$file";
    my $tokens = tokens $js, $lexers;

    print "\nTokenized file: $file\n";
    puke $tokens;
}
