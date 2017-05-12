#
# $Id: 1-incharset.t,v 0.1 2002/05/03 05:28:21 dankogai Exp $
#
use 5.007003;
use strict;
use Test::More tests => 1;

use Encode::InCharset;
use utf8;
"I am \x{5c0f}\x{98fc}\x{3000}\x{5f3e}" =~ /(\p{InJIS0208}+)/o;
is($1, "\x{5c0f}\x{98fc}\x{3000}\x{5f3e}", "\\p{InJIS0208}");

