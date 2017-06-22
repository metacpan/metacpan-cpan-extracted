use warnings;
use strict;

use Test::More;

use Keyword::Declare;

keytype Expectation is Str;
keyword lexical (Expectation $expected) {{{ ok «$expected» eq 'Outer', 'Outer'; }}}

lexical 'Outer';

{
    keytype Expectation is /'Inner'/;
    keyword lexical (Expectation $expected) {{{ ok «$expected» eq 'Inner', 'Inner'; }}}

    lexical 'Inner';
}

lexical 'Outer';

keyword lexical (Expectation $expected) {{{ ok «$expected» eq 'Outer again', 'Outer again'; }}}

lexical 'Outer again';

done_testing();

