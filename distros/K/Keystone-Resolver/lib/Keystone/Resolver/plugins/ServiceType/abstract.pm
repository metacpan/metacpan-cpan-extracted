# $Id: abstract.pm,v 1.2 2007-01-26 13:53:49 mike Exp $

package Keystone::Resolver::plugins::ServiceType::abstract;

# This behaves exactly the same way the fulltext service-type.

use strict;
use warnings;
use Keystone::Resolver::plugins::ServiceType::fulltext;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::plugins::ServiceType::fulltext);


1;
