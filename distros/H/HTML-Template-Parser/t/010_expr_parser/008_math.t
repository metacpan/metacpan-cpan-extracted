use strict;
use warnings;
use Test::More tests => 7 * 2;

use HTML::Template::Parser::ExprParser;

use t::lib::Util;

expr_eq('not 1', [ 'op', 'not', [ 'number', '1', ]]);
expr_eq('! 1', [ 'op', '!', [ 'number', '1', ]]);

expr_eq(q! 1 + 2 !,
     [ 'op', '+',
      [ 'number', 1 ],
      [ 'number', 2 ],
  ]);
expr_eq(q! 1 - 2 !,
     [ 'op', '-',
      [ 'number', 1 ],
      [ 'number', 2 ],
  ]);
expr_eq(q! 1 * 2 !,
     [ 'op', '*',
      [ 'number', 1 ],
      [ 'number', 2 ],
  ]);
expr_eq(q! 1 / 2 !,
     [ 'op', '/',
      [ 'number', 1 ],
      [ 'number', 2 ],
  ]);
expr_eq(q! 1 % 2 !,
     [ 'op', '%',
      [ 'number', 1 ],
      [ 'number', 2 ],
  ]);
