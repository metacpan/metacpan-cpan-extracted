package Lingua::Identifier::Feature::Trigrams;
$Lingua::Identifier::Feature::Trigrams::VERSION = '0.01';
use 5.006;
use strict;

use Text::Ngram 'ngram_counts';

sub features {
    my $n = 3;

    my ($txt) = @_;
    my $hash = ngram_counts $txt, $n;

    my $total = 0;
    $total += $hash->{$_} for keys %$hash;

    for my $k (keys %$hash) {
        $hash->{$k} = $hash->{$k} / $total;
    }

    return $hash;
}

=for Pod::Coverage features

=cut


1;
