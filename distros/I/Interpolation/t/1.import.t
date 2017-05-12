#!perl -T

use Test::More tests => 13;

BEGIN {
	use_ok( 'Interpolation' );
}

diag( "Testing Interpolation $Interpolation::VERSION, Perl $], $^X" );

use Interpolation N1 => 'null';

# Use
is("$N1{1+2}", "3", "eval works for numerical expressions");
is("$N1{substr('this', 1, 2)}", "hi", "eval works for function calls");

# `no' doesn't work and can't be made to work;
# at present its effects can't be made to have lexical
# scope, and they always occur at compile time.  So
# `no' is useless.
#
# If you want to mask the interpolator, just declare a lexical has with that name
#     my %N1;
#
# {
#   no Interpolation N1;
#   check("$N1{1+2}" eq "");
#   check("$N1{substr('this', 1, 2)}" eq "");
# }

# import
{
  local $^W = 0;		# Suppress `undefined value' warnings
  is("$N2{1+2}", "", "import happens at runtime");
}
import Interpolation N2 => 'eval';
is("$N2{1+2}", "3", "numerical expression");
is("$N2{substr('this', 1, 2)}", "hi", "function call");

# unimport
{
  local $^W = 0;		# Suppress `undefined value' warnings
  unimport Interpolation 'N2';
  is("$N2{1+2}", "", "returns nothing after unimport");
  is("$N2{substr('this', 1, 2)}", "", "returns nothing after unimport");
}

# tie
ok( tie( %N3, Interpolation, sub {$_[0]}), "tie a simple interpolator");
is("$N3{1+2}", "3", "numerical");
is("$N3{substr('this', 1, 2)}", "hi", "function call");

# untie
{
  local($^W) = 0;   # Suppress `undefined value' warnings
  untie %N3;
  is("$N3{1+2}", "", "untied");
  is("$N3{substr('this', 1, 2)}", "", "untied");
}
