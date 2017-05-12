#############################################################################
# Test file for Lingua::Stem::Es                                            #
# Opens a sample vocabulary file (voc.txt) taken from                       #
# http://snowball.tartarus.org/algorithms/spanish/stemmer.html              #
# and runs the algorithm on these words. It then compares the results with  #
# those downloadable from the same page, output.txt, as control.            #
#############################################################################

use Test::More tests => 28378;

BEGIN { use_ok('Lingua::Stem::Es') };

binmode STDOUT, ":utf8";

my @words;

open(my $voc, '<:utf8','t/voc.txt') or die "Unable to open 'voc.txt': $!";

while(<$voc>) {
	chomp;
	push @words, $_;
}
close $voc;

my $results = Lingua::Stem::Es::stem(-words => \@words);

open OUT, '<:utf8', 't/output.txt' or die "Unable to open 'output.txt': $!";

my $i = 0;
while(<OUT>) {
	chomp;
    next unless defined $_;
    is( $results->[$i], $_, "Stem for '$words[$i]' is correct: $_") 
        if $words[$i];
	$i++;
}

close OUT;

