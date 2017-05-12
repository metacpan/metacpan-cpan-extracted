use strict;
use warnings;
use Lingua::JA::WordNet;
use Test::More;
use Test::Warn;

my $wn = Lingua::JA::WordNet->new(
    verbose => 1,
);

my @hypes = $wn->Rel('00448232-n', 'hype');
is_deeply(\@hypes, [qw/00447540-n 00433216-n/]);

my @dmnrs = $wn->Rel('00448232-n', 'dmnr');
is_deeply(\@dmnrs, [qw/08921850-n/]);

warning_is { @hypes = $wn->Rel('hogehoge-n', 'hype') }
    'Rel: there are no hype links for hogehoge-n', 'rel of unknown synset';

is(scalar @hypes, 0);

done_testing;
