use 5.20.0;

use Test::More tests => 3;

use List::Lazy qw/ lazy_fixed_list /;

subtest basic => sub {
    my $list = lazy_fixed_list( 1 )->append( lazy_fixed_list( 4 ) );
    is_deeply [ $list->all ] => [ 1,4 ];
};

my $list = lazy_fixed_list( 1..3 )
    ->append( lazy_fixed_list( 4..6 ), lazy_fixed_list(7..9) )
    ->prepend( lazy_fixed_list -1..0 );


is_deeply [ $list->all ], [ -1..9 ];

subtest twice => sub {
    my $list = lazy_fixed_list 1..5;
    $list = $list->append($list);
    is_deeply [ $list->all ], [ ( 1..5 ) x 2 ];
};

