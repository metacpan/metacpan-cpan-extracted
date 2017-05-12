use strict;
use warnings;
use Lingua::JA::NormalizeText;
use Test::More;
use Test::Fatal;


my @subs = (qw/new normalize/, @Lingua::JA::NormalizeText::EXPORT_OK);
can_ok('Lingua::JA::NormalizeText', @subs);

my $exception = exception{ Lingua::JA::NormalizeText->new; };
like($exception, qr/at least/, 'at least one option exception');

$exception = exception{ Lingua::JA::NormalizeText->new(qw/cl ld/); };
like($exception, qr/unknown option\(s\): cl, ld/, 'unknown option exception');

$exception = exception{ Lingua::JA::NormalizeText->new(qw/lc cl/); };
like($exception, qr/unknown option\(s\): cl/, 'unknown option exception');

$exception = exception{ Lingua::JA::NormalizeText->new(qw/lc nfc/); };
is($exception, undef, 'no exception');


my $normalizer = Lingua::JA::NormalizeText->new(qw/lc/);
isa_ok($normalizer, 'Lingua::JA::NormalizeText', 'new with array');

$normalizer = Lingua::JA::NormalizeText->new([qw/lc/]);
isa_ok($normalizer, 'Lingua::JA::NormalizeText', 'new with arrayref');

my $result;
$result = $normalizer->normalize($result);
is($result, undef, 'result of normalizing uninitialized text');

$result = $normalizer->normalize('');
is($result, '', 'result of normalizing empty text');

done_testing;
