use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/unify_long_repeats/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/unify_long_repeats/);

is(unify_long_repeats("アッーーー！"   x 2), 'アッー！' x 2, 'yaranaika');
is($normalizer->normalize("アッーー！" x 2), 'アッー！' x 2, 'yaranaika');

done_testing;
