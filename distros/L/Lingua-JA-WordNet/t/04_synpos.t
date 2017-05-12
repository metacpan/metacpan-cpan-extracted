use strict;
use warnings;
use Lingua::JA::WordNet;
use Test::More;
use Test::Warn;

my $wn = Lingua::JA::WordNet->new(
    verbose => 1,
);

my @synsets = $wn->SynPos('野球', 'n');
is_deeply(\@synsets, [qw/00476140-n 00471613-n/]);

@synsets = $wn->SynPos('野球', 'n', 'jpn');
is_deeply(\@synsets, [qw/00476140-n 00471613-n/]);

@synsets = $wn->SynPos('baseball', 'n', 'eng');
is_deeply(\@synsets, [qw/00471613-n 02799071-n/]);

warning_is { @synsets = $wn->SynPos('Perl', 'n', 'jpn') }
    "SynPos: there are no synsets for 'Perl' corresponding to 'n' and 'jpn'", 'synpos of unknown word';

is(scalar @synsets, 0);

done_testing;
