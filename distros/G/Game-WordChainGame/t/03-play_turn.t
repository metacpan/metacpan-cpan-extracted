use strict;
use warnings;
use Game::WordChainGame;
use Test::More;

my $game = Game::WordChainGame->new(players => ['Jack', 'Jill']);
my $current_player = 'Jack';
 
# Test valid play turn method
subtest "Test valid play turn method" => sub {
    my $word = 'apple';
    my $command = qq{echo $word |};
    open(my $fake_stdin, $command);
    local *STDIN = $fake_stdin;
    my $result = $game->play_turn($current_player);
    is($result, 1, "Valid turn with word '$word'");
};

# Test invalid turn due to word already used
subtest "Test invalid play turn method" => sub {
    $current_player = 'Jill';
    my $word = 'apple';
    $game->used_words->{$word} = 1;
    my $command = qq{echo $word |};
    open(my $fake_stdin, $command);
    local *STDIN = $fake_stdin;
    my $result = $game->play_turn($current_player);
    is($result, 0, "Invalid turn with word '$word' (word already used)");
};

# Test invalid turn with incorrect starting letter
subtest "Test invalid turn with incorrect starting letter" => sub {
    $current_player = 'Jack';
    $game->used_words->{'Jill'} = 'apple';
    my $word = 'air';
    my $command = qq{echo $word |};
    open(my $fake_stdin, $command);
    local *STDIN = $fake_stdin;
    my $result = $game->play_turn($current_player);
    is($result, 0, "Invalid turn with word '$word' (incorrect starting letter)");
};

# Test valid turn with correct starting letter
subtest "Test valid turn with correct starting letter" => sub {
    $current_player = 'Jack';
    $game->used_words->{'Jill'} = 'apple';
    my $word = 'elephant';
    my $command = qq{echo $word |};
    open(my $fake_stdin, $command);
    local *STDIN = $fake_stdin;
    my $result = $game->play_turn($current_player);
    is($result, 1, "Valid turn with word '$word' (correct starting letter)");
};

done_testing(4);
