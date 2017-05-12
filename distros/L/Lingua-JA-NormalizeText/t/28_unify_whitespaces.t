use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/unify_whitespaces/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/unify_whitespaces/);

my @skip_chars = ( chr hex('0009'), chr hex('000A'), chr hex('000D'), chr hex('3000') );
my $text = "\x{0009}\x{000A}\x{000B}\x{000C}\x{000D}\x{0020}\x{0085}\x{00A0}\x{1680}\x{2000}\x{2001}\x{2002}\x{2003}\x{2004}\x{2005}\x{2006}\x{2007}\x{2008}\x{2009}\x{200A}\x{2028}\x{2029}\x{202F}\x{205F}\x{3000}";

for my $char (split(//, $text))
{
    if (grep { $char eq $_ } @skip_chars)
    {
        is(unify_whitespaces($char), $char);
        is(unify_whitespaces($char x 2), $char x 2);
        is($normalizer->normalize($char x 3), $char x 3);
    }
    else
    {
        is(unify_whitespaces($char), "\x{0020}");
        is(unify_whitespaces($char x 2), "\x{0020}" x 2);
        is($normalizer->normalize($char x 3), "\x{0020}" x 3);
    }
}

done_testing;
