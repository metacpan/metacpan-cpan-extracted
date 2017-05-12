print '1..9', "\n";

delete $INC{ 'Getopt/Casual.pm' };
@ARGV = qw/ -d 0 aux rows 12 cols 24 a=b -bcd -e -fg=h i 
            --debug=no --silent /;
use lib '..';
require Getopt::Casual;
import Getopt::Casual @ARGV;

if ($ARGV{ 'a' } eq 'b' && $ARGV{ 'u' } == 1 &&
    $ARGV{ 'x' } == 1 && $ARGV{ 'aux' } == 1) {

  print 'ok 1', "\n";

} else {

  print 'not ok 1', "\n";

}

if ($ARGV{ 'rows' } == 12 && $ARGV{ 'cols' } == 24) {

  print 'ok 2', "\n";

} else {

  print 'not ok 2', "\n";

}

if ($ARGV{ 'a' } eq 'b') {

  print 'ok 3', "\n";

} else {

  print 'not ok 3', "\n";

}

if ($ARGV{ '-b' } == 1 && $ARGV{ '-c' } == 1 &&
  $ARGV{ '-d' } == 0 && $ARGV{ '-bcd' } == 1) {

  print 'ok 4', "\n";

} else {

  print 'not ok 4', "\n";

}

if ($ARGV{ '-e' }) {

  print 'ok 5', "\n";

} else {

  print 'not ok 5', "\n";

}

if (!exists $ARGV{ '-f' } && !exists $ARGV{ '-g' } &&
  $ARGV{ '-fg' } eq 'h') {

  print 'ok 6', "\n";

} else {

  print 'not ok 6', "\n";

}

if ($ARGV{ 'i' } == 1) {

  print 'ok 7', "\n";

} else {

  print 'not ok 7', "\n";

}

if ($ARGV{ '--debug' } eq 'no') {

  print 'ok 8', "\n";

} else {

  print 'not ok 8', "\n";

}

if ($ARGV{ '--silent' } == 1) {

  print 'ok 9', "\n";

} else {

  print 'not ok 9', "\n";

}
