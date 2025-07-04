use 5.20.0;

use Test2::V0;

use List::Lazy qw/ lazy_fixed_list /;

subtest basic => sub {
    my $list = lazy_fixed_list( 1 )->append( lazy_fixed_list( 4 ) );
    is [ $list->all ] => [ 1,4 ];
};

my $list = lazy_fixed_list( 1..3 )
    ->append( lazy_fixed_list( 4..6 ), lazy_fixed_list(7..9) )
    ->prepend( lazy_fixed_list -1..0 );


is [ $list->all ], [ -1..9 ];

subtest twice => sub {
    my $list = lazy_fixed_list 1..5;
    $list = $list->append($list);
    is [ $list->all ], [ ( 1..5 ) x 2 ];
};

subtest 'non-lazy list arguments' => sub {
	my $list = lazy_fixed_list( 1..3 );
	$list = $list->append( 4, lazy_fixed_list(5..6), 7);

	is [ $list->all ], [ 1..7 ], 'append';

	$list = lazy_fixed_list( 1..3 );
	$list = $list->prepend( 4, lazy_fixed_list(5..6), 7);

	is [ $list->all ], [ 4..7,1..3 ], 'prepend';
};

done_testing;
