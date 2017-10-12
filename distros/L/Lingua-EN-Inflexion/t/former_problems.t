use warnings;
use strict;

use Test::More;

plan tests => 1;

use Lingua::EN::Inflexion;

is noun('expenses')->singular, 'expense' => 'expenses';


done_testing();

