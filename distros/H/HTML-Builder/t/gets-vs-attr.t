use strict;
use warnings;

use Test::More 0.88;
use HTML::Builder qw{ div p attr };

is
    eval "div { }",
    q{<div></div>},
    'no attributes';

is
    eval "div { id gets 'xx' }",
    q{<div id="xx"></div>},
    'one attribute, gets';

is
    eval "div { attr { id => 'xx'}; }",
    q{<div id="xx"></div>},
    'one attribute, attr';

is
    eval "div { attr { id => 'xx', foo => 'bar' }; }",
    q{<div foo="bar" id="xx"></div>},
    'two attributes, attr';

is
    eval "div { attr { id => 'xx' }; foo gets 'bar' }",
    q{<div foo="bar" id="xx"></div>},
    'two attributes, attr and gets';

done_testing;
