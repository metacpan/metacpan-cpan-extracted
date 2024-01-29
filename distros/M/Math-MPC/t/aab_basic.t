use warnings;
use strict;
use Math::MPC qw(:mpc);
use Math::MPFR qw(:mpfr);

if(Math::MPC::MPC_VERSION >= 66304) {
  print "1..9\n";
}
else {
  print "1..7\n";
}

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

if($Math::MPC::VERSION eq '1.32') {print "ok 1\n"}
else {
  warn "Math::MPC version: $Math::MPC::VERSION\n";
  print "not ok 1\n";
}

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

if($Math::MPC::VERSION eq $Math::MPC::Constant::VERSION) {print "ok 6\n"}
else {
  warn "\$Math::MPC::VERSION: $Math::MPC::VERSION\n\$Math::MPC::Constant::VERSION: $Math::MPC::Constant::VERSION\n";
  print "not ok 6\n";
}

if(MPC_HEADER_V == MPC_VERSION) {print "ok 7\n" }
else {
  warn MPC_HEADER_V, " != ", MPC_VERSION;
  print "not ok 7\n";
}

if(Math::MPC::MPC_VERSION >= 66304) { # else, $Math::MPC::Radius::VERSION and
                                      # $Math::MPC::Ball::VERSION will not be visible
  if($Math::MPC::VERSION eq $Math::MPC::Radius::VERSION) {print "ok 8\n"}
  else {
    warn "\$Math::MPC::VERSION: $Math::MPC::VERSION\n\$Math::MPC::Radius::VERSION: $Math::MPC::Radius::VERSION\n";
    print "not ok 8\n";
  }

  if($Math::MPC::VERSION eq $Math::MPC::Ball::VERSION) {print "ok 9\n"}
  else {
    warn "\$Math::MPC::VERSION: $Math::MPC::VERSION\n\$Math::MPC::Ball::VERSION: $Math::MPC::Ball::VERSION\n";
    print "not ok 9\n";
  }
}


