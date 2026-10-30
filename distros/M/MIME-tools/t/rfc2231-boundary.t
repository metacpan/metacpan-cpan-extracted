use strict;
use warnings;
use Test::More tests => 8;

use MIME::Head;

sub ct {
    return MIME::Head->new(["Content-Type: multipart/mixed; $_[0]\n"]);
}

ok(ct('boundary*0="FOO "')->ambiguous_content(),
   'Continuation boundary with trailing space is ambiguous');
ok(ct('boundary*0="=?us-ascii?Q?abc?="')->ambiguous_content(),
   'Continuation boundary with encoded word is ambiguous');
ok(ct('boundary*0="A"; boundary*0="B"')->ambiguous_content(),
   'Repeated continuation index is ambiguous');
ok(ct('boundary*0="X"; boundary*1="A"; boundary*01="B"')->ambiguous_content(),
   'Repeated continuation index with a leading zero is ambiguous');
ok(ct('boundary*1="A"')->ambiguous_content(),
   'Continuation without section 0 is ambiguous');
ok(ct('boundary*0="A"; boundary*2="B"')->ambiguous_content(),
   'Continuation with a gap is ambiguous');
ok(!ct('boundary*0="abc"')->ambiguous_content(),
   'Plain continuation boundary is not ambiguous');
ok(!ct('boundary*0="ab"; boundary*1="cd"')->ambiguous_content(),
   'Two continuation sections are not ambiguous');
