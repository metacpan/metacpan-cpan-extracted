# $Id: ServiceTypeRule.pm,v 1.1 2007-07-19 13:39:13 mike Exp $

package Keystone::Resolver::DB::ServiceTypeRule;

use strict;
use warnings;
use Keystone::Resolver::DB::Rule;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::DB::Rule);


sub table { "service_type_rule" }

1;
