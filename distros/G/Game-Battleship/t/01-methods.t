use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Game::Battleship') }

my $obj = eval { Game::Battleship->new };
print "$@\n" if $@;
isa_ok $obj, 'Game::Battleship', 'with no arguments';

$obj = Game::Battleship->new;
$obj->add_player('gene');
$obj->add_player('aaron');
isa_ok $obj, 'Game::Battleship', 'with named players';

my $gene = $obj->player('gene');
isa_ok $gene, 'Game::Battleship::Player', 'gene by object';
my $aaron = $obj->player('aaron');
isa_ok $aaron, 'Game::Battleship::Player', 'aaron by object';

my $alisa = $obj->add_player('alisa');
isa_ok $alisa, 'Game::Battleship::Player', 'alisa';
is $alisa->{id}, 3, 'generated player id number';
isa_ok $obj->player(3), 'Game::Battleship::Player', 'alisa by number';
isa_ok $obj->player('player_3'), 'Game::Battleship::Player', 'alisa by key';
isa_ok $obj->player('alisa'), 'Game::Battleship::Player', 'alisa by name';
ok $obj->player(3) eq $obj->player('player_3') && $obj->player(3) eq $obj->player('alisa'), 'alisa';

my $bogus = $obj->player('bogus');
is $bogus, undef, 'bogus is not a player';

my $craft = $aaron->craft(id => 'A');
isa_ok $craft, 'Game::Battleship::Craft', 'by id';
isa_ok $aaron->craft(name => 'aircraft carrier'), 'Game::Battleship::Craft', 'by name';
ok $craft->hit == $craft->{points} - 1, 'craft hit';

my $ggrid = $gene->matrix;
ok length($ggrid), "gene's initial grid:\n" . join( "\n", $ggrid );
diag "gene's initial grid:\n" . join( "\n", $ggrid );
my $agrid = $aaron->matrix;
ok length($agrid), "aaron's initial grid:\n" . join( "\n", $agrid );
diag "aaron's initial grid:\n" . join( "\n", $agrid );

my $strike;
my $count = 0;

for my $i ( 0 .. 9 ) {
    for my $j ( 0 .. 9 ) {
        if( $count++ % 2 ) {
            $strike = $aaron->strike($gene, $i, $j);
            ok $strike == 0 || $strike == 1,
                "aaron strikes gene at row=$i, col=$j";
#            $agrid = $aaron->matrix($gene);
#            ok length($agrid), "aaron vs gene grid:\n" . join( "\n", $agrid );
        }
        else {
            $strike = $gene->strike($aaron, $i, $j);
            ok length($strike),
                "gene strikes aaron at row=$i, col=$j";
#            $ggrid = $gene->matrix($aaron);
#            ok length($ggrid), "gene vs aaron grid:\n" . join( "\n", $ggrid );
        }

        ok $strike == 0 || $strike == 1 || $strike == -1,
            "..and it's a ($strike) " .
            ($strike == 1 ? 'hit!' :
             $strike == 0 ? 'miss.'
                          : 'duplicate strike?');
    }
}

    $strike = $gene->strike($aaron, 0, 0);
    ok length($strike), "gene strikes aaron at row=0, col=0";
#    $ggrid = $gene->matrix($aaron);
#    ok length($ggrid), "gene vs aaron grid:\n" . join( "\n", $ggrid );
    ok $strike == 0 || $strike == 1 || $strike == -1,
        "..and it's a ($strike) " .
        ($strike == 1 ? 'hit!' :
         $strike == 0 ? 'miss.'
                      : 'duplicate strike?');

$ggrid = $gene->matrix;
ok length($ggrid), "gene's resulting grid:\n" . join( "\n", $ggrid );
$agrid = $aaron->matrix;
ok length($agrid), "aaron's resulting grid:\n" . join( "\n", $agrid );

done_testing();

__END__
# This works great but is sometimes seemingly infinitely long...
$obj->play;
