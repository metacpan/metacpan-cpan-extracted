use Test::More;

plan tests => 1;

use List::Lazy qw/ lazy_range /;

my $list = lazy_range( 1, 3 )->map(sub{ lazy_range( 1, $_ ) });

is_deeply [ $list->all ], [ 1, 1, 2, 1, 2, 3 ], 'list of lists';
