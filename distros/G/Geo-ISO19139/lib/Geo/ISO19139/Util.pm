# Copyrights 2008 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.05.
use warnings;
use strict;

package Geo::ISO19139::Util;
use vars '$VERSION';
$VERSION = '0.10';

use base 'Exporter';

our @r2005   = qw/NS_GCO_2005 NS_GMD_2005 NS_GMX_2005
  NS_GSR_2005 NS_GSS_2005 NS_GTS_2005 NS_GML_2005/;

our @EXPORT_OK = ( @r2005 );

our %EXPORT_TAGS =
 ( 2005 => \@r2005
 );


use constant NS_GML_2005 => 'http://www.opengis.net/gml/3.2';
use constant NS_GCO_2005 => 'http://www.isotc211.org/2005/gco';
use constant NS_GMD_2005 => 'http://www.isotc211.org/2005/gmd';
use constant NS_GMX_2005 => 'http://www.isotc211.org/2005/gmx';
use constant NS_GSR_2005 => 'http://www.isotc211.org/2005/gsr';
use constant NS_GSS_2005 => 'http://www.isotc211.org/2005/gss';
use constant NS_GTS_2005 => 'http://www.isotc211.org/2005/gts';

1;
