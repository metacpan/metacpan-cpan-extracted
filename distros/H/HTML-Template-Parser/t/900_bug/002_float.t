use strict;
use warnings;
use Test::More tests => 5 * 2;

use HTML::Template::Parser::ExprParser;

use t::lib::Util;

expr_eq('0.0',  [ 'number', '0', ]);
expr_eq('+0.0', [ 'number', '0', ]);
expr_eq('-0.0', [ 'number', '0', ]);

expr_eq('12.34', [ 'number', '12.34', ]);
expr_eq('-12.34', [ 'number', '-12.34', ]);

