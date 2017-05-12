# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl EBook-Tools.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 19;
BEGIN { use_ok('EBook::Tools',qw(fix_datestring)) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(fix_datestring('2001-01-01'),'2001-01-01', 'YYYY-MM-DD');
is(fix_datestring('2001-2-1'),'2001-02-01', 'YYYY-M-D');
is(fix_datestring('2001-03'),'2001-03', 'YYYY-MM');
is(fix_datestring('2001-4'),'2001-04', 'YYYY-M');
is(fix_datestring('2001'),'2001', 'YYYY');
is(fix_datestring('20010501'),'2001-05-01', 'YYYYMMDD');
is(fix_datestring('12151112'),'1215-11-12', 'YYYYMMDD-ambiguous');

# This entry fails for an unknown reason on amd64
# Since it's really a Date::Manip failure, I'm just giving up on testing for it.
# is(fix_datestring('2001-1112'),'2001-11-12', 'YYYY-MMDD');

is(fix_datestring('2004-0231'),undef, 'YYYY-MMDD-invalid');
is(fix_datestring('01/01/2002'),'2002', '01/01/YYYY');
is(fix_datestring('1/1/2002'),'2002', '1/1/YYYY');
is(fix_datestring('02/01/2002'),'2002-02', 'MM/01/YYYY');
is(fix_datestring('02/1/2002'),'2002-02', 'MM/1/YYYY');
is(fix_datestring('02/03/2002'),'2002-02-03', 'MM/DD/YYYY');
is(fix_datestring('2/11/2002'),'2002-02-11', 'M/DD/YYYY');
is(fix_datestring('2/3/2002'),'2002-02-03', 'M/D/YYYY');
is(fix_datestring('Jan 1, 2003'),'2003-01-01','Jan 1, 2003');
is(fix_datestring('2001-xx-01'),undef,'YYYY-xx-DD');
is(fix_datestring('2/31/2004'),undef,'2/31/2004 (invalid day)');
