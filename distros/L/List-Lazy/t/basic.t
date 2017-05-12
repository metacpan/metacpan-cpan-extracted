use Test::More;

use List::Lazy qw/ lazy_range lazy_list /;

my $range = lazy_range( 1, undef )->grep(sub{ $_ % 2})->map( sub { '!' x $_ } );

is_deeply( [ $range->next(3) ], [ '!', '!!!', '!!!!!' ] );

my $list  = lazy_list sub { $_++ }, 1;

is_deeply( [ $list->next(3) ], [ 1..3 ] );

is_deeply( [ ( lazy_list { $_ += 2 } 0 )->next(3) ], [ 2,4,6] );

subtest palinumbers => sub {
    my $palinumbers = lazy_range 99, undef, sub { do { $_++ } until $_ eq reverse $_; $_ };

    is_deeply [ $palinumbers->next(3) ], [ 99, 101, 111 ];
};

subtest recount => sub {
    my $recount = ( lazy_range 1, 100 )->map( sub { 1..$_ } );
    is_deeply [ $recount->next(6) ], [ 1, 1,2,1..3 ];
};

subtest odd => sub {
    my $odd = ( lazy_range 1, 100 )->grep( sub { $_ % 2 } );
    is_deeply( [ $odd->next(5) ], [ 1, 3, 5, 7, 9 ] );
};

done_testing;
