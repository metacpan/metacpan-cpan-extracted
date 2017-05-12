use warnings;
use strict;
#use Data::Printer;
#use Devel::Peek 'Dump';

use Test::More qw(no_plan);

BEGIN {
	use_ok( 'FreeBSD::Jails' );
}

my $jails = FreeBSD::Jails::get_jails();

is( ref( $jails ) , 'HASH', 'jls::get_jails returns hash reference' ) ; 

#say p( $jails ) ;

#Dump( $jails ) ; 
