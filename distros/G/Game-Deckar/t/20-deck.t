#!perl
# deck related tests
use 5.26.0;
use warnings;
use Game::Deckar;
use Test2::V0;
use Scalar::Util 'refaddr';

plan(73);

# initial decks need to be named in the list of decks, to hopefully cut
# down on typos between the two
like dies { Game::Deckar->new( initial => { nope => ["foo"] } ) },
  qr/no such deck/;

########################################################################
#
# Empty Object

{
    my $deck = Game::Deckar->new;
    like dies { $deck->del_deck('nope') }, qr/no such deck/;
    like dies { $deck->empty('nope') },    qr/no such deck/;
    like dies { $deck->get('deck') },      qr/no such deck/;
    like dies { $deck->get_decks },        qr/no decks/;
    like dies { $deck->shuffle('nope') },  qr/no such deck/;
}

########################################################################
#
# A Reasonable Deck

{
    my $deck = Game::Deckar->new(
        decks   => [qw/deck player1 player2 discard/],
        initial => { deck => [ 'Z', 'A' .. 'F' ], },
    );

    # that the deck references are preserved
    my @addr1 = map { refaddr $deck->get($_) } $deck->get_decks;

    like dies { $deck->add_deck('player1') },    qr/deck already exists/;
    like dies { $deck->collect('deck') },        qr/not enough decks/;
    like dies { $deck->collect(qw(deck nope)) }, qr/no such deck/;
    like dies { $deck->deal( 'nope', 'nope' ) }, qr/no such deck/;
    like dies { $deck->deal( 'player1', 'nope' ) },     qr/no such deck/;
    like dies { $deck->deal( 'deck', 'player1', -1 ) }, qr/out of range/;
    like dies { $deck->deal( 'deck', 'player1', 8 ) },  qr/out of range/;
    like dies { $deck->empty('player1') },              qr/deck is empty/;
    like dies { $deck->move( 'nope', 'player1', 1 ) },  qr/no such deck/;
    like dies { $deck->move( 'player1', 'nope', 1 ) },  qr/no such deck/;
    like dies { $deck->move( 'deck', 'player1', 1, -1 ) },
      qr/index out of range/;
    like dies { $deck->move( 'deck', 'player1', 1, 7 ) },
      qr/index out of range/;
    like dies { $deck->move( 'deck', 'player1', 8 ) },
      qr/count out of range/;
    like dies { $deck->pick( 'nope', 'player1', [] ) }, qr/no such deck/;
    like dies { $deck->pick( 'player1', 'nope', [] ) }, qr/no such deck/;
    like dies { $deck->pick( 'player1', 'deck', [] ) }, qr/no indices/;
    like dies { $deck->pick( 'player1', 'deck', [42] ) },
      qr/too many indices/;
    like dies { $deck->pick( 'deck', 'player1', [-1] ) },
      qr/index out of range/;
    like dies { $deck->pick( 'deck', 'player1', [8] ) },
      qr/index out of range/;
    like dies { $deck->pick( 'deck', 'player1', [ 1, 1 ] ) },
      qr/duplicate index/;
    like dies { $deck->shuffle('player1') }, qr/deck is empty/;

    is [ $deck->get_decks ], [qw/deck discard player1 player2/];

    my $unadd = $deck->add_deck('foo');
    is [ $deck->get_decks ], [qw/deck discard foo player1 player2/];
    $unadd->();

    is $deck->get('deck'),    [ 'Z', 'A' .. 'F' ];
    is $deck->get('discard'), [];

    my $unempty = $deck->empty('deck');
    is $deck->get('deck'), [];

    my $undel = $deck->del_deck('deck');
    is [ $deck->get_decks ], [qw/discard player1 player2/];
    $undel->();
    is [ $deck->get_decks ], [qw/deck discard player1 player2/];

    $unempty->();
    is $deck->get('deck'), [ 'Z', 'A' .. 'F' ];

    srand(640);
    my $undo = $deck->shuffle('deck');
    is $deck->get('deck'), [qw(A B Z E F D C)];
    $undo->();
    is $deck->get('deck'), [ 'Z', 'A' .. 'F' ];

    my @log;

    my ( $card, $un ) = $deck->deal( deck => 'player1' );
    is $card, 'Z';
    unshift @log, $un;

    # default destination is to the "top", or index 0
    ( undef, $un ) = $deck->deal( deck => 'player1', 0, 1 );
    unshift @log, $un;
    is $deck->get('player1'), [qw(A Z)];

    # deal to the "bottom" of the target deck, or past the last index
    ( undef, $un ) = $deck->deal( deck => 'player1', 0, 0 );
    unshift @log, $un;
    is $deck->get('player1'), [qw(A Z B)];

    $_->() for @log;
    is $deck->get('deck'),    [ 'Z', 'A' .. 'F' ];
    is $deck->get('player1'), [];

    # by custom index (this does not work easily in bulk, therefore the
    # new method below)
    ( $card, $un ) = $deck->deal( deck => 'player1', 2 );
    is $deck->get('player1'), ['B'];
    is $card,                 'B';
    $un->();
    is $deck->get('deck'),    [ 'Z', 'A' .. 'F' ];
    is $deck->get('player1'), [];

    ####################################################################
    #
    # pick

    my $picked;
    @log = ();
    ( $picked, $un ) = $deck->pick( deck => 'player1', [ 5, 6, 4 ] );
    unshift @log, $un;
    is $deck->get('deck'),    [ 'Z', 'A' .. 'C' ];
    is $picked,               [qw(E F D)];
    is $deck->get('player1'), [qw(E F D)];

    ( $picked, $un ) = $deck->pick( deck => 'player1', [ 3, 2, 1 ], 0 );
    unshift @log, $un;
    is $deck->get('deck'),    [qw(Z)];
    is $picked,               [qw(C B A)];
    is $deck->get('player1'), [qw(E F D C B A)];

    ( $picked, $un ) = $deck->pick( deck => 'player1', [0], 1 );
    unshift @log, $un;
    is $deck->get('deck'),    [];
    is $picked,               [qw(Z)];
    is $deck->get('player1'), [qw(Z E F D C B A)];

    $_->() for @log;
    is $deck->get('deck'),    [ 'Z', 'A' .. 'F' ];
    is $deck->get('player1'), [];

    ####################################################################
    #
    # move (bulk "deal", and a slightly different interface)

    @log = ();
    ( $picked, $un ) = $deck->move( deck => 'player1', 2 );
    unshift @log, $un;
    is $deck->get('deck'),    [ 'B' .. 'F' ];
    is $picked,               [qw(Z A)];
    is $deck->get('player1'), [qw(Z A)];

    ( $picked, $un ) = $deck->move( deck => 'player1', 3, 1, 0 );
    unshift @log, $un;
    is $deck->get('deck'),    [qw(B F)];
    is $picked,               [qw(C D E)];
    is $deck->get('player1'), [qw(Z A C D E)];

    $_->() for @log;
    is $deck->get('deck'),    [ 'Z', 'A' .. 'F' ];
    is $deck->get('player1'), [];

    # did anything change one of the original deck references?
    my @addr2 = map { refaddr $deck->get($_) } $deck->get_decks;
    is \@addr1, \@addr2;
}

########################################################################
#
# Deck with ::Card objects and the means to mass set metadata

{
    my $deck = Game::Deckar->new(
        decks         => [qw/stack p1 p2/],
        initial_cards => { stack   => [ 'A' .. 'C' ] },
        meta          => { visible => 0 },
    );

    my @addr1 = map { refaddr $deck->get($_) } $deck->get_decks;

    my $ref = $deck->get('stack');
    is $ref->[1]->data,            'B';
    is $ref->[1]->meta('visible'), 0;

    $deck->deal( stack => 'p1' );    # 'A'
    $deck->deal( stack => 'p2' );    # 'B', with 'C' still on stack

    # cards are put onto the "top" of the target in the order listed
    my $undo = $deck->collect(qw(stack p1 p2));
    is [ map { $_->data } $deck->get('stack')->@* ], [qw(B A C)];

    $undo->();
    is $deck->get('stack')->[0]->data, 'C';
    is $deck->get('p1')->[0]->data,    'A';
    is $deck->get('p2')->[0]->data,    'B';

    my @addr2 = map { refaddr $deck->get($_) } $deck->get_decks;
    is \@addr1, \@addr2;
}
