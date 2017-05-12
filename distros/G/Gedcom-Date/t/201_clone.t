use strict;
use warnings;

use Gedcom::Date;

use Test::More;

# -------------------

while (<DATA>) {
    chomp;
    my $gd1 = Gedcom::Date->parse( $_ );
    my $gd2 = $gd1->clone;
    isa_ok( $gd2, 'Gedcom::Date' );

    # Changing date 2 should not have any effect on date 1
    $gd2->add( years => 10, months => 2 );
    is( $gd1->gedcom, $_, "cloning '$_'" );
}

done_testing();

__DATA__
10 JUL 2003
JUL 2003
2003
ABT 10 JUL 2003
CAL 10 JUL 2003
EST 10 JUL 2003
FROM 10 JUL 2003
TO 10 JUL 2003
FROM 10 JUL 2003 TO 20 JUL 2003
AFT 10 JUL 2003
BEF 10 JUL 2003
BET 10 JUL 2003 AND 20 JUL 2003
INT 10 JUL 2003 (foo)
(foo)
