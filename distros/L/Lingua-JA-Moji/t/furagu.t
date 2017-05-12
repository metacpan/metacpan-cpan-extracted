use warnings;
use strict;
use Test::More;
use Lingua::JA::Moji 'is_romaji';

my @words = qw(hana flower tora);
my @copy = @words;
my @valid_words = grep {is_romaji $_} @words;

is_deeply (\@words, \@copy);
done_testing ();


