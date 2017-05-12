# #!perl
#
# Testsuite from the original distribution
#
# This needs some more work, I just did a minimal conversion to Test::More
#

use strict;
use warnings;
use Test::More;
use Lingua::Stem::Ru;

use strict;
use warnings;

sub test_stem {
    my ($t, $words, $expected) = @_;
    my $error_count = 0;
    my $stemmed_words = Lingua::Stem::Ru::stem( { -words => $words } );
    foreach my $stem (@$stemmed_words) {
        if ($stem ne $expected) {
            print STDERR "\t# expected '$expected', got '$stem'\n";
            ++$error_count;
        }
    }
    ok($error_count == 0, "stemming test for $expected");
}

sub test_stem_word {
    my($t, $word, $expected) = @_;

    my $stem = Lingua::Stem::Ru::stem_word($word);
    if ($stem ne $expected) {
        print STDERR "\t# expected '$expected', got '$stem'\n";
        return 0;
    }
    return 1;
}	



test_stem(2, ["гулял", "гуляла", "гуляли"], "гуля");
test_stem(3, ["ходить", "ходил", "ходили"], "ход");
test_stem(4, ["ездить", "езда", "езд"], "езд");

# sample stemmed lists
# from http://snowball.tartarus.org/algorithms/russian/stemmer.html
my(@vocs, @output);
    
open(my $fh, '<', 't/voc.txt');
foreach (<$fh>) {
   chomp;
   push @vocs, $_;
}
close($fh);

open(my $out, '<', 't/output.txt');
foreach(<$out>) {
   chomp;
   push @output, $_;
}
close($out);

my $error_count = 0;
for (0..$#vocs) {
    if (!test_stem_word($_+2, $vocs[$_], $output[$_])) {
        $error_count++;
    }
}
ok($error_count == 0, "test sample stemmed lists");

done_testing();

