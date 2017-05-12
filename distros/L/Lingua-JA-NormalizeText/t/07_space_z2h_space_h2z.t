use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/space_z2h space_h2z/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

my $zenkaku_space = q|　|;
my $hankaku_space = q| |;

is(space_z2h($zenkaku_space), $hankaku_space);
is(space_h2z($hankaku_space), $zenkaku_space);

my $normalizer = Lingua::JA::NormalizeText->new(qw/space_z2h/);
is($normalizer->normalize($zenkaku_space x 2), $hankaku_space x 2);

$normalizer = Lingua::JA::NormalizeText->new(qw/space_h2z/);
is($normalizer->normalize($hankaku_space x 3), $zenkaku_space x 3);

done_testing;
