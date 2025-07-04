use Test2::V0;

use List::Lazy qw/ lazy_range lazy_list lazy_fixed_list /;

my $range = lazy_range( 1, undef )->grep(sub{ $_ % 2})->map( sub { '!' x $_ } );

is( [ $range->next(3) ], [ '!', '!!!', '!!!!!' ] );

my $list  = lazy_list sub { $_++ }, 1;

is( [ $list->next(3) ], [ 1..3 ] );

is( [ ( lazy_list { $_ += 2 } 0 )->next(3) ], [ 2,4,6] );

subtest palinumbers => sub {
    my $palinumbers = lazy_range 99, undef, sub { do { $_++ } until $_ eq reverse $_; $_ };

    is [ $palinumbers->next(3) ], [ 99, 101, 111 ];
};

subtest recount => sub {
    my $recount = ( lazy_range 1, 100 )->map( sub { 1..$_ } );
    is [ $recount->next(6) ], [ 1, 1,2,1..3 ];
};

subtest odd => sub {
    my $odd = ( lazy_range 1, 100 )->grep( sub { $_ % 2 } );
    is( [ $odd->next(5) ], [ 1, 3, 5, 7, 9 ] );
};

subtest infinite => sub {
	my $list = lazy_list { $_++ }, 1;

	like dies { $list->all } => qr/Number of items.*exceeds/;

};

subtest batch => sub {
	my $list = ( lazy_fixed_list 1..5 );

	is [ $list->batch(2)->all ], [ [1,2], [3,4], [5] ];
};

subtest spy => sub {
	my $list = ( lazy_fixed_list 1..5 );

	like warning { $list->spy->next } => qr#1.*at t\/basic\.t#;

	my $x;
	$list->spy( sub { $x .= $_ } )->all;

	is $x => 12345;

};

done_testing;
