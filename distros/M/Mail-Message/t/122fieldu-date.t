#!/usr/bin/env perl
# Test processing of date fields.
#

use strict;
use warnings;

use Test::More;

use Mail::Message::Field::Date;

my $date1 = Mail::Message::Field::Date->new(Date => "Fri, 28 Nov 2025 09:27:51 +0000");
is $date1->date, 'Fri, 28 Nov 2025 09:27:51 +0000', 'destructed and constructed equivalent';

my $date2 = Mail::Message::Field::Date->new(Date => "28 Nov 2025 09:27:51 +0000");
is $date2->date, '28 Nov 2025 09:27:51 +0000', 'optional day name';

my $date3 = Mail::Message::Field::Date->new(Date => "Fri, 28 Nov 2025 09:27 +0000");
is $date3->date, 'Fri, 28 Nov 2025 09:27:00 +0000', 'optional seconds';

my $date4 = Mail::Message::Field::Date->new(Date => "Fri,28  Nov  2025 09 :27 :51+0001");
is $date4->date, 'Fri, 28 Nov 2025 09:27:51 +0001', 'optional blanks';

done_testing;
