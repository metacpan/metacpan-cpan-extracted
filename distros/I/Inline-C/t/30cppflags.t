use strict;
use warnings;
use diagnostics;
use FindBin '$Bin';
use lib $Bin;
use TestInlineSetup;
use Config;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;

print "1..1\n";

use Inline C => Config =>
    #BUILD_NOISY => 1,
    FORCE_BUILD => 1,
    CCFLAGS     => $Config{ccflags};

# DEV NOTE: do not actually test CPPFLAGS effect on Inline::Filters here,
# only test the ability to pass CPPFLAGS argument through Inline::C;
# see t/Preprocess_cppflags.t in Inline::Filters for real tests
use Inline C => <<'END' => CPPFLAGS => ' -DPREPROCESSOR_DEFINE';
int foo() { return 4321; }
END

my $foo_retval = foo();

if ( $foo_retval == 4321 ) {
    print "ok 1\n";
}
else {
    warn "\n Expected: 4321\n Got: $foo_retval\n";
    print "not ok 1\n";
}
