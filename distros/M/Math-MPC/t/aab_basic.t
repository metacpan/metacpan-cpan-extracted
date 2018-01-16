use warnings;
use strict;
use Math::MPC qw(:mpc);
use Math::MPFR qw(:mpfr);

print "1..5\n";

my $string = Rmpc_get_version();

print STDERR "\n# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print STDERR "# Using Math::MPC version ", $Math::MPC::VERSION, "\n";
print STDERR "# Math::MPC uses mpc library version ", Rmpc_get_version(), "\n";
print STDERR "# Math::MPFR uses mpfr library version ", Rmpfr_get_version(), "\n";
print STDERR "# Math::MPC uses mpfr library version ", Math::MPC::mpfr_v(), "\n";
print STDERR "# Math::MPFR uses gmp library version ", Math::MPFR::gmp_v(), "\n";
print STDERR "# Math::MPC uses gmp library version ", Math::MPC::gmp_v(), "\n";

Math::MPC::_have_Complex_h() ?
 warn "\n# Built with support for 'double _Complex' and 'long double _Complex' types\n"
                             :
 warn "\n# Built without support for 'double _Complex' and 'long double _Complex types'\n";

if($Math::MPC::VERSION eq '1.08') {print "ok 1\n"}
else {print "not ok 1 $Math::MPC::VERSION\n"}

if(MPC_VERSION_MAJOR > 0 || MPC_VERSION_MINOR > 7) {print "ok 2\n"}
else {print "not ok 2 MPC Library version ", MPC_VERSION_STRING, " is too old\n"}

if($string eq MPC_VERSION_STRING) {print "ok 3\n"}
else {print "not ok 3 \"", Rmpc_get_version, "\" (library version) does not match \"", MPC_VERSION_STRING, "\" (header file version)\n"}

if(MPC_VERSION == MPC_VERSION_NUM(MPC_VERSION_MAJOR, MPC_VERSION_MINOR, MPC_VERSION_PATCHLEVEL)) {print "ok 4\n"}
else {print "not ok 4 ", MPC_VERSION, " does not match ",
                         MPC_VERSION_NUM(MPC_VERSION_MAJOR, MPC_VERSION_MINOR, MPC_VERSION_PATCHLEVEL), "\n"}

if($Math::MPC::VERSION eq Math::MPC::_get_xs_version()) {print "ok 5\n"}
else {
  warn "\$Math::MPC::VERSION: $Math::MPC::VERSION\nXS_VERSION: ", Math::MPC::_get_xs_version(), "\n";
  print "not ok 5\n";
}

