use strict; use warnings; use diagnostics;
my $t; use lib ($t = -e 't' ? 't' : 'test');
use TestInlineSetup;
use Config;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;

print "1..1\n";

use Inline C => Config =>
    #BUILD_NOISY => 1,
    #CLEAN_AFTER_BUILD => 0,
    FORCE_BUILD => 1,
    PRE_HEAD => "$t/prehead.in";

use Inline C => <<'EOC';

int foo() {
    return EXTRA_DEFINE;
}

EOC

my $def = foo();

if($def == 1234) {
  print "ok 1\n";
}
else {
  warn "\n Expected: 1234\n Got: $def\n";
  print "not ok 1\n";
}
