use strict;
use warnings;
use Test::More tests => 4 * 2;

use HTML::Template::Parser::ExprParser;

use t::lib::Util;

expr_eq(q!''!, [ 'string', '', ]);
expr_eq(q!""!, [ 'string', '', ]);
expr_eq(q!'abc'!, [ 'string', 'abc', ]);
expr_eq(q!"def"!, [ 'string', 'def', ]);
