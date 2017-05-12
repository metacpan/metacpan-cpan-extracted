# Gearman Perl front end
# Copyright (C) 2013 Data Differential, http://datadifferential.com/
# Copyright (C) 2009-2010 Dennis Schoen
# All rights reserved.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.9 or,
# at your option, any later version of Perl 5 you may have available.

use Test::More tests => 5;

BEGIN {
  use_ok('Gearman::XS');
  use_ok('Gearman::XS::Client');
  use_ok('Gearman::XS::Job');
  use_ok('Gearman::XS::Task');
  use_ok('Gearman::XS::Worker');
}

diag( "Testing Gearman::XS $Gearman::XS::VERSION" );
