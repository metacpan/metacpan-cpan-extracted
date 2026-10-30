use strict;
use warnings;
use Test::More tests => 4;

use MIME::Head;

sub ct {
    return MIME::Head->new(["Content-Type: multipart/mixed; $_[0]\n"]);
}

ok(ct('boundary="abc=?us-ascii?Q?def?="')->ambiguous_content(),
   'Boundary ending in an encoded word is ambiguous');
ok(ct('boundary="=?us-ascii?Q?abc?=x"')->ambiguous_content(),
   'Boundary starting with an encoded word is ambiguous');
ok(ct('boundary="a?= =?b"')->ambiguous_content(),
   'Boundary that decoding would join is ambiguous');
ok(!ct('boundary="abc=?def"')->ambiguous_content(),
   'Boundary with a plain "=?" is not ambiguous');
