# $Id: Gale.pm,v 1.2 2007-01-26 13:53:48 mike Exp $

package Keystone::Resolver::plugins::Service::Gale;

# This behaves exactly the same way the Infotrac service -- I've added
# it because this is the name that the CUFTS database knows it by.

use strict;
use warnings;
use Keystone::Resolver::plugins::Service::Infotrac;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::plugins::Service::Infotrac);


1;
