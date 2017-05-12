print '1..4', "\n";

delete $INC{ 'Getopt/Casual.pm' };

@ARGV = qw/ -pi 3.1415 --debug 1.618 1.718281828 -a -b/;
require Getopt::Casual;
import Getopt::Casual @ARGV;

print 'not ' unless $ARGV[ 0 ] == 1.618;
print 'ok 1', "\n";

print 'not ' unless $ARGV[ 1 ] == 1.718281828;
print 'ok 2', "\n";

print 'not ' unless $ARGV[ 2 ] eq '-a';
print 'ok 3', "\n";

print 'not ' unless $ARGV[ 3 ] eq '-b';
print 'ok 4', "\n";
