# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'HTML::CalendarMonthSimple' ); }

my $object = HTML::CalendarMonthSimple->new ();
isa_ok ($object, 'HTML::CalendarMonthSimple');
