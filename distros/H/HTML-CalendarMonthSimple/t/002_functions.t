# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 3;

BEGIN { use_ok( 'HTML::CalendarMonthSimple' ); }

my $cal=HTML::CalendarMonthSimple->new(year=>2010, month=>7);
isa_ok ($cal, 'HTML::CalendarMonthSimple');

is($cal->Days_in_Month, 31, 'Days_in_Month');
