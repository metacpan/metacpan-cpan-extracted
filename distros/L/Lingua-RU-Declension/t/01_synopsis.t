use 5.014;
use utf8;

use Test::More;
use Test::More::UTF8;

use Lingua::RU::Declension;

my $rus = Lingua::RU::Declension->new();

# Decline all words to accusitive case
my $case = 'acc';
my $friend = 'друг';

my $acc_friend = $rus->decline_noun($friend, $case); # друга
my $acc_new = $rus->decline_adjective('новый', $friend, $case); # нового
my $acc_our = $rus->decline_pronoun('наш', $friend, $case); # нашего

is($acc_friend, "друга");
is($acc_new, "нового");
is($acc_our, "нашего");
is($rus->russian_sentence_stem($case) . " $acc_our $acc_new $acc_friend!",
   "Я вижу нашего нового друга!");

done_testing();