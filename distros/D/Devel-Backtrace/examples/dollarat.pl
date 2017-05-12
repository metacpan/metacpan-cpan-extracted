#!perl
use strict;
use warnings;
use Devel::DollarAt;

eval 'print 0/0';

# Output: Error line is 1
print "Error line is ", $@->line, "\n";

# Output: Error text is Illegal division by zero at (eval 3) line 1.
print "Error text is $@";

# Note: In perl 5.8 and below, the line gets reported as 2.
