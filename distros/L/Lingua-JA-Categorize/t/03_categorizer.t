use strict;
use Lingua::JA::Categorize::Categorizer;
use Test::More tests => 3;
use Data::Dumper;

my $categorizer = Lingua::JA::Categorize::Categorizer->new;

isa_ok($categorizer, 'Lingua::JA::Categorize::Categorizer');
isa_ok($categorizer->brain, 'Algorithm::NaiveBayes');
can_ok($categorizer, qw( new categorize save load ));


