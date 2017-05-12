use strict;
use Test::More tests => 8;

BEGIN {
	use_ok('Lingua::StopWords');
	use_ok('Lingua::StopWords::EN');
	use_ok('Lingua::StopWords::FR');
};

my $wordlist = Lingua::StopWords::getStopWords('en');

ok($wordlist->{me});
ok(!$wordlist->{moi});

my $wordlist3 = Lingua::StopWords::getStopWords('xx');
is($wordlist3, undef);

my $wordlist1 = Lingua::StopWords::getStopWords('fr');
my $wordlist2 = Lingua::StopWords::FR::getStopWords();
is_deeply($wordlist1, $wordlist2);

my $text = 'ceci est un texte avec des mots au hasard';
my @words = split / /, $text;
my $t = join ' ', grep { !$wordlist1->{$_} } @words;
is ($t, 'ceci texte mots hasard');

