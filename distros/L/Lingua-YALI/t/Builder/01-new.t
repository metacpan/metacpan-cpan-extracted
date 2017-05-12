use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;
use Time::HiRes;

BEGIN { use_ok('Lingua::YALI::Builder') };

my $builder1 = Lingua::YALI::Builder->new(ngrams=>[2, 3, 4]);
my $ngrams1 = $builder1->get_ngrams();
is((scalar @$ngrams1), 3, "3 different n-grams");
is($builder1->get_max_ngram(), 4, "4-gram is maximum");

dies_ok { my $builder2 = Lingua::YALI::Builder->new(ngrams=>[-2]) } "Negative n-gram.";

dies_ok { my $builder3 = Lingua::YALI::Builder->new(ngrams=>[0]) } "0-gram.";

dies_ok { my $builder4 = Lingua::YALI::Builder->new() } "n-grams are not specified";

my $builder5 = Lingua::YALI::Builder->new(ngrams=>[2, 3, 4, 2, 3, 4, 2, 3, 4]);
my $ngrams5 = $builder5->get_ngrams();
is((scalar @$ngrams5), 3, "3 different n-grams");
is($builder5->get_max_ngram(), 4, "4-gram is maximum");