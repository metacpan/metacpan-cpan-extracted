use utf8;
no warnings qw(qw);
use open qw(:std :utf8);

use Test::More qw(no_plan);
use Test::Deep;

use Lingua::RU::OpenCorpora::Tokenizer;

use constant THRESHOLD => $ENV{TOKENIZER_THRESHOLD} || 0.5;

my @tests = (
    [
        'Простейшее предложение.',
        [9, 21, 22],
    ],
    [
        'Это предложение чуть сложнее, но все ещё простое.',
        [2, 14, 19, 27, 28, 31, 35, 39, 47, 48],
    ],
    [
        'Текст с двоеточием на конце:',
        [4, 6, 17, 20, 26],
    ],
    [
        '«Школа злословия» учит прикусить язык',
        [0, 5, 15, 16, 21, 31, 36],
    ],
    [
        'Юникǒдныé çимвȭлы',
        [8, 16],
    ],
    [
        pack('UU', 0x415, 0x308) . 'ще Юникод',
        [2, 9],
    ],
);

my $tokenizer = Lingua::RU::OpenCorpora::Tokenizer->new;

for my $t (@tests) {
    my $bounds = $tokenizer->tokens_bounds($t->[0]);
    for(my $i = 0; $i <= $#{ $t->[1] }; $i++) {
        is $bounds->[$i][0], $t->[1][$i], "boundary: $t->[0]";
        ok $bounds->[$i][1] >= THRESHOLD, "probability: $t->[0]";
    }
}
