use 5.20.0;

use Test::More tests => 1;

use List::Lazy qw/ lazy_fixed_list /;

my $list = lazy_fixed_list( 1..100 )->until(sub{ $_ > 10 });
is_deeply [ $list->all ] => [ 1..10 ];

