use strict;
use warnings;
use Test::More tests => 10;

use MIME::Head;

sub ct {
    return MIME::Head->new(["Content-Type: multipart/mixed$_[0]\n"]);
}

ok(ct('; boundary((c))="AAA"; boundary="BBB"')->ambiguous_content(),
   'Duplicate boundary behind a nested comment is ambiguous');
ok(ct('; boundary(\))="AAA"; boundary="BBB"')->ambiguous_content(),
   'Duplicate boundary behind a quoted-pair comment is ambiguous');
ok(ct('; (; boundary="AAA";) boundary="BBB"')->ambiguous_content(),
   'Boundary inside a comment is ambiguous');
ok(ct('; boundary(;)="BBB"')->ambiguous_content(),
   'Comment holding ";" in a parameter is ambiguous');
ok(ct(' (; boundary="BBB"; y=");boundary="AAA"')->ambiguous_content(),
   'Comment holding ";" after the type is ambiguous');
ok(ct('(; boundary="BBB"; y=");boundary="AAA"')->ambiguous_content(),
   'Comment holding ";" glued to the type is ambiguous');
ok(ct('; x=1 (; boundary="BBB"; y=");boundary="AAA"')->ambiguous_content(),
   'Comment holding ";" after a value is ambiguous');
ok(!ct('; charset="x" (x); (made by x=1) boundary="BBB"')->ambiguous_content(),
   'Comments without ";" or \'"\' are not ambiguous');
my $head = ct('; boundary(c)="AAA"');
ok(!$head->ambiguous_content(), 'Single boundary after a comment is not ambiguous');
is($head->multipart_boundary(), 'AAA', '... and is parsed');
