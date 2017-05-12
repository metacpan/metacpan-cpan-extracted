use Test::More;
use Games::Mastermind;

plan tests => 5;

my $mm = Games::Mastermind->new;
isa_ok( $mm, 'Games::Mastermind' );

# defaults
is_deeply( $mm->pegs, [qw( K B G R Y W )], "Default pegs" );
is_deeply( $mm->holes, 4,  "Default size" );

# setters
is_deeply( $mm->pegs( [ 1 .. 4 ] ), [ 1 .. 4 ], "Setter correct" );
is_deeply( $mm->pegs, [ 1 .. 4 ], "Getter correct" );
