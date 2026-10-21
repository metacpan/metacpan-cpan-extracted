use strict;
use warnings;

use utf8;

use MARC::Charset qw(marc8_to_utf8);
use MARC::Charset::Constants qw(:all);
use Encode;

use Test::More tests => 1;

my $japanese_marc8 = ESCAPE . MULTI_G0_A . CJK . q{i%oi%si%@! $i%,i%"i%0} .
                     ESCAPE . '(B ' . 
                     ESCAPE . MULTI_G0_A . CJK . '!BX! $9Qy' . 
                     ESCAPE . '(B ; ' . 
                     ESCAPE . MULTI_G0_A . CJK . 'i$$i$7i$$i$bi$bi$3' . 
                     ESCAPE . '(B ' .
                     ESCAPE . MULTI_G0_A . CJK . 'KYF' .
                     ESCAPE . '(B.';
my $japanese_utf8 = marc8_to_utf8($japanese_marc8);

is($japanese_utf8, "ワンダ･ガアグ 文･絵 ; いしいももこ 訳.", 'converted CCCII halfwidth middle dot to UTF8');
exit 0;
