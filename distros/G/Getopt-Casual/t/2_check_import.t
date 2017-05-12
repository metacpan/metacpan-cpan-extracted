print '1..6', "\n";

use Getopt::Casual qw/ -pi 3.1415 --debug 1.618 1.718281828 -a -b/;

print 'not ' unless $ARGV{ '-pi' } == 3.1415;
print 'ok 1', "\n";

print 'not ' unless $ARGV{ '--debug' } == 1;
print 'ok 2', "\n";

print 'not ' unless $ARGV{ '1.618' } == 1;
print 'ok 3', "\n";

print 'not ' unless $ARGV{ '1.718281828' } == 1;
print 'ok 4', "\n";

print 'not ' unless $ARGV{ '-a' } == 1;
print 'ok 5', "\n";

print 'not ' unless $ARGV{ '-b' } == 1;
print 'ok 6', "\n";