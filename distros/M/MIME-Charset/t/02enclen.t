use strict;
use Test;

BEGIN { plan tests => 3 }

use MIME::Charset qw(:trans);

my $s = "Perl: \xe8\xa8\x80\xe8\xaa\x9e";
ok(encoded_header_len($s,"b","utf-8"), 28, encoded_header_len($s,"b","utf-8"));
ok(encoded_header_len($s,"q","utf-8"), 38, encoded_header_len($s,"q","utf-8"));
ok(encoded_header_len($s,"s","utf-8"), 28, encoded_header_len($s,"s","utf-8"));
