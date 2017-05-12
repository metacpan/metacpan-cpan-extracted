# Copyrights 2008 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.05.
use warnings;
use strict;

package Geo::ISO19139::2005;
use vars '$VERSION';
$VERSION = '0.10';

use base 'Geo::GML';

use Geo::ISO19139::Util qw/:2005/;

use Log::Report 'geo-iso', syntax => 'SHORT';

use XML::Compile::Cache ();
use XML::Compile::Util  qw/unpack_type pack_type/;

my $xsd = __FILE__;
$xsd    =~ s!/2005+\.pm$!/xsd!;
my @xsd = glob("$xsd/2005/*/*.xsd");


sub init($)
{   my ($self, $args) = @_;
    $self->{GI9_version} = $args->{version} || '2005';
    $args->{version} = $args->{gml_version} || '3.2.1';

    my $pref = $args->{prefixes} ||= {};
    $pref->{gco} ||= NS_GCO_2005;
    $pref->{gmd} ||= NS_GMD_2005;
    $pref->{gmx} ||= NS_GMX_2005;
    $pref->{gsr} ||= NS_GSR_2005;
    $pref->{gss} ||= NS_GSS_2005;
    $pref->{gts} ||= NS_GTS_2005;

    $self->SUPER::init($args);
    $self->importDefinitions(\@xsd);
    $self;
}


sub gmlVersion() {shift->SUPER::version}
sub version()    {shift->{GI9_version}}

1;
