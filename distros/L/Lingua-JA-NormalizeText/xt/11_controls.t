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

    if ($chara =~ /\p{Cc}/)
    {
        my $hex = sprintf("%04X", $dec);
        next if $hex eq '0009' || $hex eq '000A' || $hex eq '000D';
        push(@hex, $hex);
    }
}

my @controls = qw/
0000 0001 0002 0003 0004 0005 0006 0007 0008           000B 000C      000E 000F
0010 0011 0012 0013 0014 0015 0016 0017 0018 0019 001A 001B 001C 001D 001E 001F
007F
0080 0081 0082 0083 0084 0085 0086 0087 0088 0089 008A 008B 008C 008D 008E 008F
0090 0091 0092 0093 0094 0095 0096 0097 0098 0099 009A 009B 009C 009D 009E 009F
/;

is_deeply(\@hex, \@controls);

done_testing;
