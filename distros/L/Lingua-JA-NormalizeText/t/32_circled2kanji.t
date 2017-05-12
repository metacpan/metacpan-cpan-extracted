use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/circled2kanji/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

my $normalizer = Lingua::JA::NormalizeText->new(qw/circled2kanji/);

is(circled2kanji('㊩㊫㊚㊒㊖！'), '医学男有財！');
is($normalizer->normalize('㊩㊫㊚㊒㊖！' x 2), '医学男有財！' x 2);

is(circled2kanji("㉅\x{1F250}"), '幼得');

done_testing;
