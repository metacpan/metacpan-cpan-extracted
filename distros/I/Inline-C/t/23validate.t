# Check that a small bugfix in Inline::C::validate() (ticket #11748)
# is behaving as expected.

use warnings;
use strict;
use Config;

print "1..5\n";

require Inline::C;

# Next 2 lines are for the benefit of 5.8.8.
my (%o1, %o2, %o3);
my($o1, $o2, $o3) = (\%o1, \%o2,\ %o3);

$o1->{FOOBAR}{STUFF} = 1;

$o2->{FOOBAR}{STUFF} = 1;
$o2->{ILSM}{MAKEFILE}{INC} = '-I/foo -I/bar';

$o3->{FOOBAR}{STUFF} = 1;

bless($o1, 'Inline::C');
bless($o2, 'Inline::C');
bless($o3, 'Inline::C');

Inline::C::validate($o1);

if(($Config{osname} eq 'MSWin32') and ($Config{cc} =~ /\b(cl\b|clarm|icl)/)) {

  ## $o1->{ILSM}{MAKEFILE}{INC} should be unset
  ## as it's $ENV{INCLUDE} that is instead amended

  if($o1->{ILSM}{MAKEFILE}{INC}) {print "not ok 1\n"}
  else {print "ok 1\n"}
}
else {

  ## $o1->{ILSM}{MAKEFILE}{INC} should be set
  ## to "-I\"$FindBin::Bin\""

  if($o1->{ILSM}{MAKEFILE}{INC}) {print "ok 1\n"}
  else {print "not ok 1\n"}
}

Inline::C::validate($o2);

if($o2->{ILSM}{MAKEFILE}{INC} eq '-I/foo -I/bar') {print "ok 2\n"}
else {
  warn "INC: ", $o2->{ILSM}{MAKEFILE}{INC}, "\n";
  print "not ok 2\n";
}

Inline::C::validate($o2, 'INC', '-I/baz');

if($o2->{ILSM}{MAKEFILE}{INC} =~ / \-I\/baz/) {print "ok 3\n"}
else {
  warn "INC: ", $o2->{ILSM}{MAKEFILE}{INC}, "\n";
  print "not ok 3\n";
}

if($o2->{ILSM}{MAKEFILE}{INC} eq '-I/foo -I/bar -I/baz') {print "ok 4\n"}
else {
  warn "INC: ", $o2->{ILSM}{MAKEFILE}{INC}, "\n";
  print "not ok 4\n";
}

Inline::C::validate($o3, 'INC', '-I/baz');

if(($Config{osname} eq 'MSWin32') and ($Config{cc} =~ /\b(cl\b|clarm|icl)/)) {

  ## $o3->{ILSM}{MAKEFILE}{INC} should be set to " -I/baz"

  if($o3->{ILSM}{MAKEFILE}{INC} eq ' -I/baz' ) {print "ok 5\n"}
  else {
    warn "INC: ", $o3->{ILSM}{MAKEFILE}{INC}, "\n";
    print "not ok 5\n";
  }

}
else {

  ## $o3->{ILSM}{MAKEFILE}{INC} should be set
  ## to "-I\"$FindBin::Bin\"" followed by " -I/baz"

  if($o3->{ILSM}{MAKEFILE}{INC} =~ / \-I\/baz/ &&
     $o3->{ILSM}{MAKEFILE}{INC} ne ' -I/baz' ) {print "ok 5\n"}
  else {
    warn "INC: ", $o3->{ILSM}{MAKEFILE}{INC}, "\n";
    print "not ok 5\n";
  }

}
