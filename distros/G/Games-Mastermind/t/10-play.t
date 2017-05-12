use Test::More;
use Games::Mastermind;

my @tests = (
    # all combinaisons
    [ [qw( A B C D )], [qw(E E E E)], [ 0, 0 ] ],
    [ [qw( A B C D )], [qw(E F D F)], [ 0, 1 ] ],
    [ [qw( A B C D )], [qw(E C B E)], [ 0, 2 ] ],
    [ [qw( A B C D )], [qw(B A E C)], [ 0, 3 ] ],
    [ [qw( A B C D )], [qw(C A D B)], [ 0, 4 ] ],
    [ [qw( A B C D )], [qw(A E F E)], [ 1, 0 ] ],
    [ [qw( A B C D )], [qw(E A C F)], [ 1, 1 ] ],
    [ [qw( A B C D )], [qw(E B D C)], [ 1, 2 ] ],
    [ [qw( A B C D )], [qw(C A B D)], [ 1, 3 ] ],
    [ [qw( A B C D )], [qw(E B F D)], [ 2, 0 ] ],
    [ [qw( A B C D )], [qw(C B E D)], [ 2, 1 ] ],
    [ [qw( A B C D )], [qw(A D C B)], [ 2, 2 ] ],
    [ [qw( A B C D )], [qw(A B E D)], [ 3, 0 ] ],
    [ [qw( A B C D )], [qw(A B C D)], [ 4, 0 ] ],

    # other tests
    [ [qw( A B C D )], [qw(C D E F)], [ 0, 2 ] ],
    [ [qw( B A B B )], [qw(A B B B)], [ 2, 2 ] ],
);
plan tests => 2 * @tests + 1;

my $marks;
my $mm = Games::Mastermind->new( pegs => [ 'A' .. 'F' ] );
for (@tests) {
    $mm->code( $_->[0] );
    $marks = is_deeply( $mm->play( @{ $_->[1] } ),
        $_->[2], "@{$_->[0]} / @{$_->[1]} => @{$_->[2]}" );

    # and the opposite should be true as well!
    $mm->code( $_->[1] );
    $marks = is_deeply( $mm->play( @{ $_->[0] } ),
        $_->[2], "@{$_->[1]} / @{$_->[0]} => @{$_->[2]}" );

}

# check errors
$mm->reset;
eval { $mm->play(qw( A B C )); };
like( $@, qr/^Not enough pegs in guess \(A B C\)/, "Not enough pegs");

