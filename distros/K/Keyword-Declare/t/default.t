use warnings;
use strict;

use Keyword::Declare;

keyword  okay (Int $n = '$default') {{{ print "ok «$n»\n" }}}
keyword dokay (Int $n = '$default') :keepspace {{{ print "ok «$n=~s{^\s+}{}r»\n" }}}
keyword aokay (Int @n = '$default') {{{ print "ok «@n»\n" }}}
keyword kokay (Int @n = '$default') :keepspace {{{ print "ok «map { s{^\s+}{}r } @n»\n" }}}

print "1..12\n";
my $default = 1;
okay        ;
okay 2      ;
$default = 3;
okay;
$default = 4;
dokay       ;
dokay 5     ;
$default = 6;
dokay;
$default = 7;
aokay       ;
aokay 8     ;
$default = 9;
aokay;
$default = 10;
kokay       ;
kokay 11     ;
$default = 12;
kokay;
