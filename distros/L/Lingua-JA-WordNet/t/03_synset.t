use strict;
use warnings;
use Lingua::JA::WordNet;
use Test::More;
use Test::Warn;

my $wn = Lingua::JA::WordNet->new(
    verbose => 1,
);

my @synsets = $wn->Synset('相撲');
is_deeply(\@synsets, [qw/00448232-n 10674713-n/]);

@synsets = $wn->Synset('相撲', 'jpn');
is_deeply(\@synsets, [qw/00448232-n 10674713-n/]);

@synsets = $wn->Synset('sumo', 'eng');
is_deeply(\@synsets, [qw/00448232-n/]);

warning_is { @synsets = $wn->Synset('Perl', 'jpn') }
    "Synset: there are no synsets for 'Perl' in jpn", 'synset of unknown word';

is(scalar @synsets, 0);

done_testing;
