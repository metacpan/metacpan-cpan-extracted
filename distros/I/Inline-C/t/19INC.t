use strict; use warnings; use diagnostics;
use FindBin '$Bin';
use lib $Bin;
my $t;
BEGIN {
    $t = $Bin;
}
use Cwd;
use TestInlineSetup;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;

BEGIN {
  my $incdir1 = "$t/foo/";
  my $incdir2 = "$t/bar/";
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



