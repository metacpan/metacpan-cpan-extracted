use strict;
use warnings;

use Test::More tests => 6;

use_ok('Lingua::JA::Summarize');

my $s;

undef $@;
eval {
    $s = Lingua::JA::Summarize->new;
};
is(ref($s), "Lingua::JA::Summarize", 'constructor');
is($s->mecab, $ENV{LJS_MECAB} || 'mecab', 'default mecab path');
is($s->default_cost, 1, 'default cost');

$s = Lingua::JA::Summarize->new({
    mecab => '/tmp/bin/mecab',
    default_cost => 0.5,
});
is($s->mecab, '/tmp/bin/mecab', 'customize mecab path');
is($s->default_cost, 0.5, 'customize default cost');

