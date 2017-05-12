#!perl -T

use Test::More;

BEGIN {
  unless (eval "use PPI;1") {
    plan skip_all => "PPI not available. "
        . "Install PPI distribution to test PPI-version of this distro";
  } else {
    plan tests => 1;
  }
    use_ok( 'Devel::DumpTrace::PPI' ) || print "Bail out!
";
}

diag "Testing Devel::DumpTrace::PPI ",
     "$Devel::DumpTrace::VERSION, Perl $], $^X";
