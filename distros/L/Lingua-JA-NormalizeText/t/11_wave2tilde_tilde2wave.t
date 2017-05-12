use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/wave2tilde tilde2wave/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

my $tilde = chr(hex("FF5E"));
my $wave  = chr(hex("301C"));
my $wavy  = chr(hex("3030"));

my $normalizer_w2t = Lingua::JA::NormalizeText->new(qw/wave2tilde/);
my $normalizer_t2w = Lingua::JA::NormalizeText->new(qw/tilde2wave/);

is(wave2tilde("$wave$wavy"),  $tilde x 2);
is(wave2tilde($tilde), $tilde);
is($normalizer_w2t->normalize("$wave$wavy"),  $tilde x 2);
is($normalizer_w2t->normalize($tilde), $tilde);

is(tilde2wave("$wave$wavy"),  "$wave$wavy");
is(tilde2wave($tilde), $wave);
is($normalizer_t2w->normalize("$wave$wavy"),  "$wave$wavy");
is($normalizer_t2w->normalize($tilde), $wave);

my $tilde2 = $tilde . 'あ' . $tilde;
my $wave2  = $wave  . 'あ' . $wavy;

is(wave2tilde($wave2), $tilde2);
is(wave2tilde($tilde2), $tilde2);
is($normalizer_w2t->normalize($wave2 x 2),  $tilde2 x 2);
is($normalizer_w2t->normalize($tilde2 x 2), $tilde2 x 2);

is(tilde2wave($wave2 x 2), $wave2 x 2);
is(tilde2wave($tilde2 x 2), "${wave}あ${wave}" x 2);
is($normalizer_t2w->normalize($wave2),  $wave2);
is($normalizer_t2w->normalize($tilde2), "${wave}あ${wave}");

done_testing;
