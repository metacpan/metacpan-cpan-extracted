# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-ES-Syllabify.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 15;
BEGIN { use_ok('Lingua::ES::Syllabify', ':test') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $syllabeLike1 = "cao";
my @syllabes1 = ("ca", "o");
is_deeply([processHiatus($syllabeLike1)], \@syllabes1, "Test process simple hiatus");

my $syllabeLike2 = "ahon";
my @syllabes2 = ("a", "hon");
is_deeply([processHiatus($syllabeLike2)], \@syllabes2, "Test process hiatus with interleaved 'h'");

my $syllabeLike3 = "aún";
my @syllabes3 = ("a", "ún");
is_deeply([processHiatus($syllabeLike3)], \@syllabes3, "Test process stressed hiatus");

my $syllabeLike4 = "ahín";
my @syllabes4 = ("a", "hín");
is_deeply([processHiatus($syllabeLike4)], \@syllabes4, "Test process stressed hiatus with interleaved 'h'");

my $syllabeLike5 = "aun";
my @syllabes5 = ("aun");
is_deeply([processHiatus($syllabeLike5)], \@syllabes5, "Test process diphthong to find hiatus");

my $syllabeLike6 = "hin";
my @syllabes6 = ("hin");
is_deeply([processHiatus($syllabeLike6)], \@syllabes6, "Test process normal syllabe");

my $syllabeLike7 = "fía";
my @syllabes7 = ("fí", "a");
is_deeply([processHiatus($syllabeLike7)], \@syllabes7, "Test process stressed hiatus with soft vowel at begining");

my $syllabeLike8 = "traí";
my @syllabes8 = ("tra", "í");
is_deeply([processHiatus($syllabeLike8)], \@syllabes8, "Test process stressed hiatus with consonants at begining");

my $syllabeLike9 = "trai";
my @syllabes9 = ("trai");
is_deeply([processHiatus($syllabeLike9)], \@syllabes9, "Test process non-stressed non-hiatus with consonants at begining");

my $word10 = "casa";
my @syllables10 = ("ca", "sa");
is_deeply([getSyllables($word10)], \@syllables10, "Test get syllables");

my $word11 = "cohecho";
my @syllables11 = ("co", "he", "cho");
is_deeply([getSyllables($word11)], \@syllables11, "Test get syllables when word has hiatus");

my $word12 = "entrañe";
my @syllables12 = ("en", "tra", "ñe");
is_deeply([getSyllables($word12)], \@syllables12, "Test get syllables when word 'ñ'");

my $word13 = "sobreaguáis";
my @syllables13 = ("so", "bre", "a", "guáis");
is_deeply([getSyllables($word13)], \@syllables13, "Test get syllables");

my $word14 = "éxodo";
my @syllables14 = ("é", "xo", "do");
is_deeply([getSyllables($word14)], \@syllables14, "Test get syllables when 'x'");
