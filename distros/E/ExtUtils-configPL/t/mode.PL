use lib qw(../blib/lib ../blib/arch);
use ExtUtils::configPL mode => 0700;
<<--startperl-->> -w
use strict;

print "1..1\n";

if (((stat($0))[2] & 07777) == 0700) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}
