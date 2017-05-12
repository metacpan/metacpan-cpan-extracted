# -*- cperl -*-
use lib qw(./blib/lib ../blib/lib);
use strict;
BEGIN { $| = 1; print "1..12\n"; }
use Inline::Files;

# 1..2
open X, ">out.tmp" or die;
print X "ok 2\n";
close X;
print "ok 1\n" if -f "out.tmp";
open Y, "out.tmp" or die;
print <Y>;
close Y;
unlink "out.tmp";

# 3..4
open X, ">", "out.tmp" or die;
print X "ok 4\n";
close X;
print "ok 3\n" if -f "out.tmp";
open Y, "<", "out.tmp" or die;
print <Y>;
close Y;
unlink "out.tmp";

# 5..7
open X, ">out.tmp" or die;
print X "ok 6\n";
close X;
print "ok 5\n" if -f "out.tmp";
open X, ">>out.tmp" or die;
print X "ok 7\n";
close X;
open Y, "out.tmp" or die;
print <Y>;
close Y;
unlink "out.tmp";

# 8..10
open X, ">","out.tmp" or die;
print X "ok 9\n";
close X;
print "ok 8\n" if -f "out.tmp";
open X, ">>","out.tmp" or die;
print X "ok 10\n";
close X;
open Y, "<out.tmp" or die;
print <Y>;
close Y;
unlink "out.tmp";

# 11..12
open X, qq{$^X -e "print 'ok 11'" | } or die "$!";
print <X>, "\n";
close X;
open X, "-|", qq{$^X -e "print 'ok 12'" } or die "$!";
print <X>, "\n";
close X;

