use strict;
use warnings;

use DateTime;

use Gedcom::Date;

use Test::More;

# -------------------

my $dt = DateTime->new( year => 2003, month => 7, day => 18 );
my $gd = Gedcom::Date->from_datetime( $dt );

isa_ok($gd, 'Gedcom::Date');
is($gd->gedcom, '18 JUL 2003', 'from_datetime');

my $gd2 = $gd->to_approximated;
is($gd2->gedcom, 'ABT 18 JUL 2003', 'to_approximated');

my $gd3 = $gd->to_approximated( 'calculated' );
is($gd3->gedcom, 'CAL 18 JUL 2003', 'to_approximated (cal)');

done_testing();
