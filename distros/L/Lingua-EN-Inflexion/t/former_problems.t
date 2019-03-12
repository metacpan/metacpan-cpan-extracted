use warnings;
use strict;

use Test::More;

plan tests => 2;

use Lingua::EN::Inflexion;

is noun('expenses')->singular, 'expense' => 'expenses';

is verb('backcast')->past, 'backcast' => 'backcast';

done_testing();

