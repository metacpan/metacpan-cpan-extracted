use FindBin '$Bin';
use lib "$Bin";
use LJMT;

my @words = qw(hana flower tora);
my @copy = @words;
my @valid_words = grep {is_romaji $_} @words;

is_deeply (\@words, \@copy);
done_testing ();


