use strict;
use warnings;
use Lingua::JA::WordNet;
use Test::More;

my $wn = Lingua::JA::WordNet->new;

my $allsynsets_arrayref = $wn->AllSynsets;

for my $synset (@{$allsynsets_arrayref})
{
    like($synset, qr/^[0-9]{8}-[arnv]$/, 'format check');
}

done_testing;
