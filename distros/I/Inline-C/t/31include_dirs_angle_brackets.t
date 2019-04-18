use warnings;
use diagnostics;
use FindBin '$Bin';
use lib $Bin;
use Config;
BEGIN { use Cwd; $cwd = getcwd; };

use TestInlineSetup;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;

use Test::More tests => 1;

use Inline C => Config =>
#    BUILD_NOISY => 1,
    FORCE_BUILD => 1,
    INC => qq{-I"$Bin/test_header"};

use Inline C => <<'EOC';

#include <iquote_test.h>

int foo() {
#if defined(DESIRED_HEADER)
  return 1;
#endif
  return 0;
}

EOC

my $ret = foo();

is($ret, 1, 'load correct header file');
