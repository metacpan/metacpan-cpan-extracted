use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/remove_controls/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/remove_controls/);

# \t = U+0009
my @skip_chars = ( "\t", chr hex('000A'), chr hex('000D') );
my @not_controls  = ( chr hex('0020'), chr hex('00A0') );

for my $dec (
    hex('0000') .. hex('0020'),
    hex('007F'),
    hex('0080') .. hex('009F'),
    hex('00A0')
)
{
    my $chara = chr $dec;
    my $hex   = '\x{' . sprintf("%04X", $dec) . '}';

    if ( grep { $chara eq $_ } (@skip_chars, @not_controls) )
    {
        is(remove_controls($chara), $chara, $hex);
        is(remove_controls($chara x 2), $chara x 2, $hex);
        is($normalizer->normalize($chara), $chara, $hex);
        is($normalizer->normalize($chara x 3), $chara x 3, $hex);
    }
    else
    {
        is(remove_controls($chara), '', $hex);
        is(remove_controls($chara x 3), '', $hex);
        is($normalizer->normalize($chara), '', $hex);
        is($normalizer->normalize($chara x 2), '', $hex);
    }
}

is(remove_controls("あ\x{0000}あ" x 2), "ああ" x 2);

done_testing;
