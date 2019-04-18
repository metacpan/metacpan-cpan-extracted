
# The "test_header.h" we intend to load is ./test_header.h (which defines TEST_DEFINE to 2112).
# With MS compilers expect that the unintended ./test_header/test_header.h (which defines
# TEST_DEFINE to 2113) will instead be loaded.

use warnings;
use diagnostics;
use FindBin '$Bin';
use lib $Bin;
use Config;
BEGIN {
  use Cwd;
  $cwd = getcwd;
  my $separator = $^O =~ /MSWin32/ ? ';' : ':';
  {
    no warnings 'uninitialized';

    # $ENV{INCLUDE} is used by Microsoft toolset
    # We can't prepend $Bin/test_header to $ENV{INCLUDE} because the lack of "-iquote" capability
    # can have unacceptable consequences if we do that. So we append $Bin/test_header to $ENV{INCLUDE}
    # and then witness (courtesy of this test) that doing so still results in the inclusion
    # of the unintended header.

    $ENV{INCLUDE} .= ";" . qq{"$Bin/test_header"};

    # $ENV{CPATH} used by gcc toolset
    # The "-iquote" capability means that we *can* prepend $Bin/test_header to $ENV{CPATH},
    # so we do just that, and test that the intended "test_header.h" still gets included.

    $ENV{CPATH} = qq{"$Bin/test_header"} . $separator . $ENV{CPATH};
  }
};

use TestInlineSetup;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;

print "1..1\n";

use Inline C => Config =>
#    BUILD_NOISY => 1,
    FORCE_BUILD => 1,
    ;

use Inline C => <<'EOC';

#include "test_header.h"

int foo() {
#if TEST_DEFINE == 2112
  return 1;
#elif TEST_DEFINE == 2113
  return -1;
#else
  return 0;
#endif
}

EOC

my $ret = foo();

if(($Config{osname} eq 'MSWin32') and ($Config{cc} =~ /\b(cl\b|clarm|icl)/)) {

  # Expect MS compilers to load the unintended header file.
  # If intended header is loaded then this test fails, indicating that we
  # need to rewrite this test and remove the hard-coded warning emitted
  # by validate() in C.pm.

  if($ret == -1) {
    warn "\n # TODO: wrong header file was loaded\n";
    print "ok 1\n";
  }

  elsif($ret == 1) {
    warn "\n TODO unexpectedly passed.\n",
         " The hard coded warning being emitted by the\n",
         " validate() sub in C.pm needs to be removed\n";
    print "not ok 1\n";
  }

  else {
    warn "\nUnexpected error - should be investigated\n";
    print "not ok 1\n";
  }


}

else {

  if($ret == 1) { print "ok 1\n" }
  else { print "not ok 1\n" }

}

