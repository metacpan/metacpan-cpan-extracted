use strict; use warnings; use diagnostics;
my $t; use lib ($t = -e 't' ? 't' : 'test');
use Cwd;
use TestInlineSetup;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;

BEGIN {
  my $cwd = Cwd::getcwd();
  my $incdir1 = $cwd . "/$t/foo/";
  my $incdir2 = $cwd . "/$t/bar/";
  $main::includes = "-I$incdir1  -I$incdir2";
};

use Inline C => Config =>
 INC => $main::includes;

use Inline C => <<'EOC';

#include <find_me_in_foo.h>
#include <find_me_in_bar.h>

SV * foo() {
  return newSViv(-42);
}

EOC

print "1..1\n";

my $f = foo();
if($f == -42) {print "ok 1\n"}
else {
  warn "\n\$f: $f\n";
  print "not ok 1\n";
}



