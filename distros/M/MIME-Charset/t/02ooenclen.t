use strict;
use Test;

BEGIN { plan tests => 4 }

use MIME::Charset qw(:trans);

my $s = "Perl: \xe8\xa8\x80\xe8\xaa\x9e";
my $obj = MIME::Charset->new("utf-8");
ok($obj->encoded_header_len($s), 28, $obj->encoded_header_len($s));
ok($obj->encoded_header_len($s,"b"), 28, $obj->encoded_header_len($s,"b"));
ok($obj->encoded_header_len($s,"q"), 38, $obj->encoded_header_len($s,"q"));
ok($obj->encoded_header_len($s,"s"), 28, $obj->encoded_header_len($s,"s"));
