#
#   This file is part of the Kools::Okapi package
#   a Perl C wrapper for the Thomson Reuters Kondor+ OKAPI api.
#
#   Copyright (C) 2009 Gabriel Galibourg
#
#   The Kools::Okapi package is free software; you can redistribute it and/or
#   modify it under the terms of the Artistic License 2.0 as published by
#   The Perl Foundation; either version 2.0 of the License, or
#   (at your option) any later version.
#
#   The Kools::Okapi package is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   Perl Artistic License for more details.
#
#   You should have received a copy of the Artistic License along with
#   this package.  If not, see <http://www.perlfoundation.org/legal/>.
# 
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Kools-Okapi.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Kools::Okapi') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

