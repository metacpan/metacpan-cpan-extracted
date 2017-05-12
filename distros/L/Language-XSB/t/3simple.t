use Test::More tests => 7;

use strict;
use warnings;

use Language::Prolog::Types ':short';
use Language::Prolog::Types::overload;
use Language::Prolog::Sugar functors => [qw( man god mortal)],
                            vars     => [qw( X )];

use Language::XSB qw(:query);

xsb_assert(mortal(X) => man(X));

xsb_facts(man('socrates'),
	  man('bush'),
	  god('zeus'));


xsb_set_query(mortal(X));

ok( xsb_next(), 'xsb_next 1');
is( xsb_var(X), 'socrates', 'xsb_var 1');

ok( xsb_next(), 'xsb_next 2');
is( xsb_var(X), 'bush', 'xsb_var 2');

ok( !xsb_next(), 'xsb_next ends');

is_deeply( [xsb_find_all(man(X),X)], ['socrates', 'bush'], 'xsb_find_all');

is( xsb_find_one(god(X), X), 'zeus', 'xsb_find_one');

