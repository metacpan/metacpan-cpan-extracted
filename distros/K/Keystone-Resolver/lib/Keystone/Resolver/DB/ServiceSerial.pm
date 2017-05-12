# $Id: ServiceSerial.pm,v 1.1 2008-04-02 17:54:48 mike Exp $

package Keystone::Resolver::DB::ServiceSerial;

use strict;
use warnings;
use Keystone::Resolver::DB::Object;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::DB::Object);


sub table { "service_serial" }

sub fields { (service_id => undef,
	      serial_id => undef,
	      ) }

# Since this is only a link table, there is no point in setting
# display_fields() etc.  The only method it needs to support is
# find().

1;
