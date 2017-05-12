use strict;
use warnings;
use Test::More tests => 6 * 2;

use HTML::Template::Parser::ExprParser;

use t::lib::Util;

expr_eq('0', [ 'number', 0, ]);
expr_eq('-0', [ 'number', 0, ]);
expr_eq('+0', [ 'number', 0, ]);

expr_eq('1', [ 'number', 1, ]);
expr_eq('-1', [ 'number', -1, ]);
expr_eq('+1', [ 'number', +1, ]);

