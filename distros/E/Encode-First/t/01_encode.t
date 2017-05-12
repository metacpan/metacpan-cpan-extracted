use strict;
use Test::Base;
use Encode::First;
use Encode;

plan tests => 2 * blocks;
filters 'chomp';

run {
    my $block = shift;
    my $str   = decode_utf8($block->input);

    my $buffer = $block->input;
    Encode::from_to($buffer, "utf-8", $block->encoding);

    my($enc, $bytes) = encode_first($block->encodings, $str);
    is $enc, $block->encoding, "encoding is $enc";
    is $bytes, $buffer, $block->name;
};

__END__

=== simple us-ascii
--- input
Hello World
--- encodings
us-ascii
--- encoding
us-ascii

=== us-ascii as a list
--- input
Hello World
--- encodings
us-ascii,latin-1
--- encoding
us-ascii

=== latin-1 beats us-ascii
--- input
Hello World
--- encodings
latin-1,us-ascii
--- encoding
latin-1

=== latin-1 characters
--- input
Héllo World
--- encodings
ascii,latin-1
--- encoding
latin-1

=== Japanese with iso-2022-jp
--- input
こんにちは
--- encodings
us-ascii,latin-1,iso-2022-jp
--- encoding
iso-2022-jp

=== Japanese with utf-8
--- input
こんにちは
--- encodings
us-ascii,latin-1,utf-8
--- encoding
utf-8

=== 
--- input
專業的研發團
--- encodings
ascii,latin-1,big5
--- encoding
big5

===
--- input
파숙지
--- encodings
ascii,latin-1,iso-2022-kr
--- encoding
iso-2022-kr

=== Unicode
--- SKIP
--- input
파숙지 專業的研發團 こんにちは
--- encodings
ascii,latin-1,euc-jp,iso-2022-jp,iso-2022-kr,big5,utf-8
--- encoding
utf-8
