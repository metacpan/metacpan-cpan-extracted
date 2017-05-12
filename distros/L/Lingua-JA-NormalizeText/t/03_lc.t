use strict;
use warnings;
use Lingua::JA::NormalizeText;
use Test::More;

my $normalizer = Lingua::JA::NormalizeText->new(qw/lc/);

is($normalizer->normalize("DdD"), 'ddd');
is($normalizer->normalize(""), '');
is($normalizer->normalize(undef), undef);

done_testing;
