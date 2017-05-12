# Copyrights 2008-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package Geo::EOP::Util;
use vars '$VERSION';
$VERSION = '0.50';

use base 'Exporter';

our @hmas      = qw/NS_ATM_ESA NS_OHR_ESA NS_SAR_ESA NS_HMA_ESA/;
our @eops      = qw/NS_ATM_ESA NS_OPT_ESA NS_SAR_ESA NS_EOP_ESA/;

our @EXPORT    = (@hmas, @eops);

our @EXPORT_TAGS =
 ( hma10     => \@hmas
 , eop11     => \@eops
 , eop12beta => \@eops
 , eop121    => \@eops
 );


use constant NS_ATM_ESA => 'http://earth.esa.int/atm';
use constant NS_SAR_ESA => 'http://earth.esa.int/sar';

# HMA before renaming
use constant NS_OHR_ESA => 'http://earth.esa.int/ohr';
use constant NS_HMA_ESA => 'http://earth.esa.int/hma';

# EOP renaming
use constant NS_OPT_ESA => 'http://earth.esa.int/opt';
use constant NS_EOP_ESA => 'http://earth.esa.int/eop';

1;
