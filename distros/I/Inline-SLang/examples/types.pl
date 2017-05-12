#
# Examples taken from the introduction to the
# Inline::SLang::Types documentation
#

use Inline SLang => Config => BIND_SLFUNCS => [ "vmessage" ];
use Inline SLang;
use Math::Complex;

# the S-Lang Complex_Type variable is automatically converted
# to a Math::Complex object in Perl.
#
my $val = makecplx();
print "Perl has been sent $val\n";

# the multiplication is done using Math::Complex objects and
# the result then converted to a S-Lang Complex_Type variable,
# since vmessage is a S-Lang function [the %S means convert
# the variable to its string representation]
#
vmessage( "S-Lang has been sent %S", $val * cplx(0,1) );

my $type = typecplx($val);
print "And the S-Lang datatype is $type\n";
print "        Perl object        " .  $type->typeof . "\n";

__END__
__SLang__

define makecplx() { return 3 + 4i; }
define typecplx(cval) { return typeof(cval); }
