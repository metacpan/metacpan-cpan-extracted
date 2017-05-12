use strict;
use warnings;
use Test::More tests => 6 * 2;

use HTML::Template::Parser::ExprParser;

use t::lib::Util;

expr_eq('a', [ 'variable', 'a', ]);
expr_eq('{b}', [ 'variable', 'b', ]);
expr_eq('${c}', [ 'variable', 'c', ]);
expr_eq('{s p a c e}', [ 'variable', 's p a c e', ]);
expr_eq('${d.o.t}', [ 'variable', 'd.o.t', ]);
expr_eq('${/top level var}', [ 'variable', '/top level var', ]);
