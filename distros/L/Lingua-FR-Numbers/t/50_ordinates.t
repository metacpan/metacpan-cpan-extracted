#!/usr/bin/perl -w
use strict;
use Test;
BEGIN { plan tests => 20 }
use Lingua::FR::Numbers qw( ordinate_to_fr );

# switch off warnings
$SIG{__WARN__} = sub {};

use vars qw( @numbers );
do 't/ordinates';

while ( @numbers ){
	my ( $number, $result ) = splice( @numbers, 0, 2);
	ok( ordinate_to_fr($number), $result);
}

