use strict;
use warnings;
use Lingua::JA::WordNet;
use Test::More;

my $wn = Lingua::JA::WordNet->new;
my $allsynsets_arrayref = $wn->AllSynsets;
is(scalar @{$allsynsets_arrayref}, 117659, 'num of all synsets');
like($allsynsets_arrayref->[0], qr/^[0-9]{8}-[arnv]$/, 'synset format');

done_testing;
