# $Id: citeref.pm,v 1.2 2007-01-26 13:53:49 mike Exp $

package Keystone::Resolver::plugins::ServiceType::citeref;

# This behaves exactly the same way as the websearch service-type.

use strict;
use warnings;
use Keystone::Resolver::plugins::ServiceType::websearch;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::plugins::ServiceType::websearch);


1;
