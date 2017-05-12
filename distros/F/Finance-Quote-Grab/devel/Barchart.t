#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Finance-Quote-Grab.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use Test::More tests => 21;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Finance::Quote::Barchart;


#------------------------------------------------------------------------------
# dash_frac_to_decimals

is (Finance::Quote::Barchart::dash_frac_to_decimals('1'), '1');
is (Finance::Quote::Barchart::dash_frac_to_decimals('-1'), '-1');
is (Finance::Quote::Barchart::dash_frac_to_decimals('7-1'), '7.125');
is (Finance::Quote::Barchart::dash_frac_to_decimals('77-2'), '77.25');
is (Finance::Quote::Barchart::dash_frac_to_decimals('997-3'), '997.375');
is (Finance::Quote::Barchart::dash_frac_to_decimals('11117-4'), '11117.5');
is (Finance::Quote::Barchart::dash_frac_to_decimals('7-5'), '7.625');
is (Finance::Quote::Barchart::dash_frac_to_decimals('7-6'), '7.75');
is (Finance::Quote::Barchart::dash_frac_to_decimals('7-7'), '7.875');

is (Finance::Quote::Barchart::dash_frac_to_decimals('123456-00'), '123456');
is (Finance::Quote::Barchart::dash_frac_to_decimals('123456-01'), '123456.03125');
is (Finance::Quote::Barchart::dash_frac_to_decimals('123456-08'), '123456.25');
is (Finance::Quote::Barchart::dash_frac_to_decimals('123456-31'), '123456.96875');

is (Finance::Quote::Barchart::dash_frac_to_decimals('99999-000'), '99999');
is (Finance::Quote::Barchart::dash_frac_to_decimals('99999-010'), '99999.03125');
is (Finance::Quote::Barchart::dash_frac_to_decimals('99999-002'), '99999.0078125');
is (Finance::Quote::Barchart::dash_frac_to_decimals('0-002'), '0.0078125');
is (Finance::Quote::Barchart::dash_frac_to_decimals('99999-005'), '99999.015625');
is (Finance::Quote::Barchart::dash_frac_to_decimals('99999-007'), '99999.0234375');
is (Finance::Quote::Barchart::dash_frac_to_decimals('99999-317'), '99999.9921875');
is (Finance::Quote::Barchart::dash_frac_to_decimals('99999-160'), '99999.5');


exit 0;
