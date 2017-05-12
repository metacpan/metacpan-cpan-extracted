use strict;
use warnings;
use Test::More tests => 5 * 2;

use HTML::Template::Parser::ExprParser;

use t::lib::Util;

expr_eq('not 0',   [ 'op', 'not', [ 'number', '0', ]]);
expr_eq('not (0)', [ 'op', 'not', [ 'number', '0', ]]);
expr_eq('not(0)',  [ 'op', 'not', [ 'number', '0', ]]);

expr_eq('a || ! 0',   [ 'op', '||', [ 'variable', 'a', ], [ 'op', '!', [ 'number', '0', ]]]);
expr_eq('a || not 0', [ 'op', '||', [ 'variable', 'a', ], [ 'op', 'not', [ 'number', '0', ]]]);
