use lib qw(../blib/lib ../blib/arch);
use ExtUtils::configPL;
<<--startperl-->> -w
use strict;
use Config;

print "1..3\n";

# Check to see if we can start
if ("<<--startperl-->>" eq "$Config{startperl}") {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}

# Check two different configs on the same line
if ("<<--cc-->> <<--cat-->>" eq "$Config{cc} $Config{cat}") {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}

# Check two of the same configs on the same line
if ("<<--cc-->> <<--cc-->>" eq "$Config{cc} $Config{cc}") {
    print "ok 3\n";
} else {
    print "not ok 3\n";
}
