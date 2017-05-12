use strict;
use utf8;
use Test::More 0.98;

use JSON5;
use JSON5::Parser;

my $parser = JSON5::Parser->new->allow_nonref->utf8;

is $parser->parse(q!"\\\b\t\n\f\r\"\'\/\u5BFF\u53F8\U0001F363"!), "\x5C\x08\x09\x0A\x0C\x0D\x22\x27\x2F寿司🍣", 'value: '.q!"\\\\\\b\\t\\n\\f\\r\\"\\'\\/\\u5BFF\\u53F8\\U0001F36"!;
is $parser->parse(qq!"a\\\n  b\\\nc"!), "a  bc", 'value: '.q!"a\\\n  b\\\nc"!;

eval { $parser->parse(qq!"a\n  b\nc"!) };
like $@, qr/^Syntax Error: line:1/, 'value: '.q!"a\n  b\nc"!.' should be syntax error';

done_testing;
