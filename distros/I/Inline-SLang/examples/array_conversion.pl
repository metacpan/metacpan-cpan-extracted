use strict;

use Inline 'SLang' => Config => EXPORT => [ 'sl_array2perl' ];
use Inline 'SLang';

# use array references for all S-Lang arrays
sl_array2perl(0);
my $a0 = get_array();
print "Array returned as an " . ref($a0) . "\n";
print "  dim size = " . (1+$#$a0) . "\n";

# use Array_Type for all S-Lang arrays
sl_array2perl(1);
my $a1 = get_array();
print "Array returned as an " . ref($a1) . "\n";
my ( $dims, $ndim, $atype ) = $a1->array_info();
print "  dim size = $$dims[0]\n";
print "  type     = $atype\n";

# use a piddle (assumes Inline::SLang::sl_have_pdl() == 1)
sl_array2perl(2);
my $a2 = get_array();
print "Array returned as an " . ref($a2) . "\n";
print "  dim size = " . $a2->getdim(0) . "\n";
print "  type     = " . $a2->type . "\n";

__END__
__SLang__

define get_array() { return [ 14.0, 3 ]; }
