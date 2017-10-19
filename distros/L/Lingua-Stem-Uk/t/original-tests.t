# #!perl
#
# Testsuite from the original distribution
#
# This needs some more work, I just did a minimal conversion to Test::More
#
use utf8;
use strict;
use warnings;
use Test::More;
use Lingua::Stem::Uk;

use strict;
use warnings;

use open ':std', ':encoding(UTF-8)';

sub test_stem {
    my ($t, $words, $expected) = @_;
    my $error_count = 0;
    my $stemmed_words = Lingua::Stem::Uk::stem( { -words => $words } );
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

    my $stem = Lingua::Stem::Uk::stem_word($word);
    if ($stem ne $expected) {
        print STDERR "\t# expected '$expected', got '$stem'\n";
        return 0;
    }
    return 1;
}	



test_stem(2, ["гуляв", "гуляла", "гуляли"], "гуля");
test_stem(3, ["ходить", "ходив", "ходили"], "ход");
test_stem(4, ["молода", "молоде", "молодий", "молодим", "молодими", "молодих", "молоді", "молодій", "молодім", "молодого", "молодої", "молодому", "молодою", "молоду"], "молод");
test_stem(5, ["безпритульна", "безпритульне", "безпритульний", "безпритульним", "безпритульними", "безпритульних", "безпритульні", "безпритульній", "безпритульнім", "безпритульного", "безпритульної", "безпритульному", "безпритульною", "безпритульну"], "безпритул");



#my(@vocs, @output);
#
#open(my $fh, '<', 't/voc.txt');
#foreach (<$fh>) {
#   chomp;
#   push @vocs, $_;
#}
#close($fh);

#open(my $out, '<', 't/output.txt');
#foreach(<$out>) {
#   chomp;
#   push @output, $_;
#}
#close($out);

#my $error_count = 0;
#for (0..$#vocs) {
#    if (!test_stem_word($_+2, $vocs[$_], $output[$_])) {
#        $error_count++;
#    }
#}
#ok($error_count == 0, "test sample stemmed lists");

done_testing();

