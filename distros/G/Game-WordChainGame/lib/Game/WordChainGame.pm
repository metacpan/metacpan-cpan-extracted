package Game::WordChainGame;
use Moose;
use WordNet::QueryData;

our $VERSION = '1.0';

has 'players' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 2
);

has 'wn' => (
    is      => 'ro',
    isa     => 'WordNet::QueryData',
    default => sub { WordNet::QueryData->new }
);

has 'used_words' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} }
);

has 'last_active_player' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { $_[0]->players ? $_[0]->players->[0] : '' }  # Default to an empty string if players are not defined
);

has 'winner' => (
    is      => 'rw',
    isa     => 'Str',
    default => ''
);

sub validate_word {
    my ($self, $word) = @_;
    return $self->wn->validForms($word);
}

sub play_turn {
    my ($self, $current_player) = @_;

    my $prev_player = $self->last_active_player;
    my $prev_word = $self->used_words->{$prev_player};

    if (defined $prev_word) {
        my $last_letter = substr($prev_word, -1);
        print "$current_player, enter a word starting with '$last_letter': ";
    } else {
        print "$current_player, enter a word: ";
    }

    my $current_word = lc(<STDIN>);
    chomp $current_word;

    if ($current_word eq "quit") {
        print "Thanks for playing!\n";
        return;
    }

    if (!$self->validate_word($current_word)) {
        print "The word '$current_word' is not valid. $current_player loses.\n";
        return 0;  # Player eliminated
    }

    if ($self->used_words->{$current_word}) {
        print "Word already used. $current_player loses.\n";
        return 0;  # Player eliminated
    }

    if (defined $prev_word && substr($current_word, 0, 1) ne substr($prev_word, -1)) {
        print "Invalid word. $current_player loses.\n";
        return 0;  # Player eliminated
    }

    $self->used_words->{$current_word} = 1;  # Mark the word as used
    $self->used_words->{$current_player} = $current_word;
    $self->last_active_player($current_player) if $current_player ne $prev_player;

    return 1;  # Player continues
}

sub play {
    my ($self) = @_;
    my $num_players = @{$self->players};
    print "Welcome to Word Chain Game with $num_players players!\n";

    $self->_recursive_play(@{$self->players});
    return $self->winner if ($self->winner);
}

sub _recursive_play {
    my ($self, $current_player, @remaining_players) = @_;

    return if !@remaining_players; 

    my $player_continues = $self->play_turn($current_player);
    if ($player_continues) {
        my $next_player = shift @remaining_players;
        push @remaining_players, $current_player;
        $self->_recursive_play($next_player, @remaining_players);
    } else {
        my $next_player = shift @remaining_players;
        $self->_recursive_play($next_player, @remaining_players);
    }

    # Check if there's only one player left and set them as the winner
    if (@remaining_players == 0 && !$self->winner) {
        $self->winner($current_player);
    }
}

1;

__END__

=head1 NAME

Game::WordChainGame - A game where players form a word chain based on last letter of previous player.

=head1 VERSION

Version 1.0

=head1 SYNOPSIS

    use Game::WordChainGame;
    
    # Create a new game with two or more players
    my $game = Game::WordChainGame->new(players => ['Player1', 'Player2', ...]);
    
    # Start the game
    my $winner = $game->play();
    
    if ($winner) {
        print "The winner is $winner!\n";
    } else {
        print "No winner. It's a tie!\n";
    }

=head1 ATTRIBUTES

=head2 players

An array reference containing the names of the players participating in the game.
This attribute is required and should include at least two player names.

Example:

    my $game = Game::WordChainGame->new(players => ['Player1', 'Player2', 'Player3']);

This sets up the game with three players named Player1, Player2, and Player3.

=head2 wn

A read-only attribute that holds a WordNet::QueryData object for word validation.
Defaults to a new instance of WordNet::QueryData.

This attribute is responsible for validating words entered by players during the game.
It uses WordNet::QueryData to check whether a word is a valid English word.

To use the default WordNet::QueryData object:

    my $default_wn = $game->wn;

You can also provide your own WordNet::QueryData object during object creation:

    my $custom_wn = WordNet::QueryData->new(some_options);
    my $game = Game::WordChainGame->new(players => ['Player1', 'Player2'], wn => $custom_wn);

For more information on WordNet::QueryData, please refer to its documentation.

=head2 used_words

A hash reference that keeps track of the words used by each player during the game.
This attribute allows monitoring which words have already been used to form the word chain.

Example of usage:

    # Access the used_words hash reference
    my $used_words = $game->used_words;

    # Check if a specific word has been used by any player
    if ($used_words->{'Player1'}{'apple'}) {
        print "The word 'apple' has been used by Player1.\n";
    }

    # Mark a word as used
    $used_words->{'Player2'}{'banana'} = 1;

Note: This attribute is automatically managed by the game during play and is read-write.

=head2 last_active_player

    my $last_player = $game->last_active_player;

A read-write attribute that represents the name of the last active player in the game. 
This attribute is automatically updated during the game to keep track of the player who most recently took a turn.

=head2 winner

    my $winner = $game->winner();

Returns the name of the player who won the game. 
If there is no winner yet or the game hasn't been played, it returns an empty string ('').
If multiple players are still active at the end of the game, there will be no winner, and this attribute will remain as an empty string.
This attribute allows you to determine the outcome of the game after calling the C<play> method.

=head1 METHODS

=head2 new

    my $game = Game::WordChainGame->new(players => ['Player1', 'Player2']);

Creates a new Game::WordChainGame object. Requires an array reference of player names.

=head2 play

    my $winner = $game->play();

Starts the game. Players take turns entering words. The game continues until there's only one player
left or all players choose to quit. Returns the name of the winning player or an empty string if there
is no winner.

=head1 INTERNAL METHODS

=head2 play_turn

    my $player_continues = $game->play_turn($current_player);

Handles a single turn of a player, prompting them to enter a word.
Returns a boolean indicating whether the player's turn continues.

=head2 validate_word

    my $is_valid = $game->validate_word($word);

Validates whether a given word is a valid English word using WordNet. 
This method takes a single argument, which is the word to be validated. It returns a boolean value:

- If the provided word is a valid English word, it returns true (1).
- If the provided word is not a valid English word, it returns false (0).

Note: This method relies on the WordNet::QueryData module for word validation.

=head2 _get_previous_player

    my $prev_player = $game->_get_previous_player($current_player);

This is an internal method used to determine the previous player in the game's turn order based on the current player's name.


=head2 _recursive_play

    $game->_recursive_play($current_player, @remaining_players);

An internal recursive method used to manage the turn-based gameplay. 
This method handles the logic of players taking turns and determining the winner of the game.
This method is automatically called by the C<play> method and should not be called directly. 
It recursively cycles through the players in the game, allowing them to take turns. 
When the game ends, either due to a single winner or all players quitting, the name of the winning player is set in the C<winner> attribute.

=head1 AUTHOR

Rohit R Manjrekar, C<< <manjrekarrohit76@gmail.com> >>

=head1 REPOSITORY

L<https://github.com/rmanjrekar/Games>

=head1 LICENSE AND COPYRIGHT

MIT License

Copyright (c) 2023 Rohit R Manjrekar

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut