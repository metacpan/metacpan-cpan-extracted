# Copyrights 2008-2014 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package Geo::GML::Util;
use vars '$VERSION';
$VERSION = '0.16';

use base 'Exporter';

our @gml200  = qw/NS_GML_200  NS_XLINK_1999/;
our @gml211  = qw/NS_GML_211  NS_XLINK_1999/;
our @gml212  = qw/NS_GML_212  NS_XLINK_1999/;
our @gml2120 = qw/NS_GML_2120 NS_XLINK_1999/;
our @gml2121 = qw/NS_GML_2121 NS_XLINK_1999/;
our @gml300  = qw/NS_GML_300  NS_XLINK_1999 NS_SMIL_20/;
our @gml301  = qw/NS_GML_301  NS_XLINK_1999 NS_SMIL_20/;
our @gml310  = qw/NS_GML_310  NS_XLINK_1999 NS_SMIL_20/;
our @gml311  = qw/NS_GML_311  NS_XLINK_1999 NS_GML_311_SF NS_SMIL_20/;

our @gml321  = qw/NS_GML_32 NS_GML_321
  NS_GMD_2005 NS_SMIL_20 NS_XLINK_1999/;

our @proto   = qw/NS_GML NS_GML_32 NS_GML_SF/;

our @EXPORT  =
 ( @proto
 , @gml200, @gml211, @gml212, @gml2120, @gml2121
 , @gml300, @gml301, @gml310, @gml311, @gml321
 );

our %EXPORT_TAGS =
 ( gml200    => \@gml200
 , gml211    => \@gml211
 , gml212    => \@gml212
 , gml2120   => \@gml2120
 , gml2121   => \@gml2121
 , gml300    => \@gml300
 , gml301    => \@gml301
 , gml310    => \@gml310
 , gml311    => \@gml311
 , gml321    => \@gml321
 , protocols => \@proto
 );


use constant NS_GML        => 'http://www.opengis.net/gml';
use constant NS_GML_32     => 'http://www.opengis.net/gml/3.2';

# used in various schemas
use constant NS_GMD_2005   => 'http://www.isotc211.org/2005/gmd';
use constant NS_SMIL_20    => 'http://www.w3.org/2001/SMIL20/';
use constant NS_XLINK_1999 => 'http://www.w3.org/1999/xlink';


use constant NS_GML_200    => NS_GML;
use constant NS_GML_211    => NS_GML;
use constant NS_GML_212    => NS_GML;
use constant NS_GML_2120   => NS_GML;
use constant NS_GML_2121   => NS_GML;
use constant NS_GML_300    => NS_GML;
use constant NS_GML_301    => NS_GML;
use constant NS_GML_310    => NS_GML;
use constant NS_GML_311    => NS_GML;
use constant NS_GML_321    => NS_GML_32;

use constant NS_GML_SF     => 'http://www.opengis.net/gmlsf';
use constant NS_GML_311_SF => NS_GML_SF;

1;
