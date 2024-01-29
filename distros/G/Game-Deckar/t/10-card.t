#!perl
# that the card class behaves
use 5.26.0;
use warnings;
use Game::Deckar;
use Test2::V0;

plan(8);

like dies { Game::Deckar::Card->new }, qr/data/;

{
    my $card = Game::Deckar::Card->new( data => 42 );
    is $card->data, 42;

    is $card->meta('foo'), undef;

    $card->set_meta( foo => 1 );
    is $card->meta('foo'), 1;

    my $undo = $card->set_meta( foo => 2 );

    is $card->meta('foo'), 2;

    $undo->();
    is $card->meta('foo'), 1;
}

{
    my $card = Game::Deckar::Card->new(
        data => 42,
        meta => { hidden => 1, counter => 3 }
    );

    is $card->meta('hidden'),  1;
    is $card->meta('counter'), 3;
}
