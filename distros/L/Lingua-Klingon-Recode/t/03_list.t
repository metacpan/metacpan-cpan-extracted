# vim:set filetype=perl sw=4 et:

#########################

use Test::More tests => 2;
use Test::Differences;
use Carp;

BEGIN {use_ok 'Lingua::Klingon::Recode', ':all'; }

eq_or_diff [ recode('tlhIngan Hol', 'XIFAN HOL', qw/tlhIngan Hol Dajatlh'a'/) ],
           [ qw/XIFAN HOL DAJAX'A'/ ],
           "list output of recode";
