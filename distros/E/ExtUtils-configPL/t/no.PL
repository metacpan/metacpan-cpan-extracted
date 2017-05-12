use lib qw(../blib/lib ../blib/arch);
use ExtUtils::configPL;
<<--startperl-->> -w
use strict;
use Config;

print "1..3\n";

if ("<<--cc-->>" eq $Config{cc}) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}

no ExtUtils::configPL;

if ("<<--cc-->>" eq "\<\<--cc--\>\>") {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}

use ExtUtils::configPL;

if ("<<--cc-->>" eq $Config{cc}) {
    print "ok 3\n";
} else {
    print "not ok 3\n";
}
