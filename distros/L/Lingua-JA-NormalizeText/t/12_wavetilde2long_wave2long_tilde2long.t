use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/wavetilde2long wave2long tilde2long/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $tilde = chr(hex("FF5E"));
my $wave  = chr(hex("301C"));
my $wavy  = chr(hex("3030"));
my $long  = chr(hex("30FC"));

my $tilde_wave_wavy_long = "$tilde$wave$wavy$long";

is(wavetilde2long($tilde_wave_wavy_long), $long x 4);
is(wave2long($tilde_wave_wavy_long  x 2), "$tilde$long$long$long" x 2);
is(tilde2long($tilde_wave_wavy_long x 2), "$long$wave$wavy$long"  x 2);

my $normalizer_wt2l = Lingua::JA::NormalizeText->new(qw/wavetilde2long/);
my $normalizer_w2l  = Lingua::JA::NormalizeText->new(qw/wave2long/);
my $normalizer_t2l  = Lingua::JA::NormalizeText->new(qw/tilde2long/);

is($normalizer_wt2l->normalize($tilde_wave_wavy_long),    $long x 4);
is($normalizer_w2l->normalize($tilde_wave_wavy_long x 2), "$tilde$long$long$long" x 2);
is($normalizer_t2l->normalize($tilde_wave_wavy_long x 2), "$long$wave$wavy$long"  x 2);

done_testing;
