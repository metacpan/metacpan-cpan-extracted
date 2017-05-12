use strict;
use warnings;
use utf8;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

my @hex;

for my $dec ( hex('0000') .. hex('10FFFF') )
{
    my $chara = chr $dec;

    if ($chara =~ /\p{White_Space}/)
    {
        my $hex = sprintf("%04X", $dec);
        next if $hex eq '0009' || $hex eq '0020' || $hex eq '000A' || $hex eq '000D' || $hex eq '3000';
        push(@hex, $hex);
    }
}

my @white_space = qw/000B 000C 0085 00A0 1680 2000 2001 2002 2003 2004
2005 2006 2007 2008 2009 200A 2028 2029 202F 205F/;

is_deeply(\@hex, \@white_space);

done_testing;
