#!perl
use strict;
use warnings;
use Test::More;
use Judy::Mem qw( Peek );
use Judy::L qw( Set Get Free );
use Config '%Config';

if ( ( $Config{ivsize} == $Config{longsize} )
   && ( $Config{uvsize} == $Config{longsize} )
   ) {
   plan( skip_all => 'sizeof(IV) == sizeof(long), hurrah' );
}
else {
     plan( tests => 3 );
}

my $judy;

my $warned = '';
$SIG{__WARN__} = sub { $warned = shift @_ };
Set($judy,0, 4294967360 );
like( $warned, qr/Truncating 4294967360 to 2147483647/, 'Truncating 4294967360 to 2147483647' );
$warned = '';

Set($ judy, -2, 0 );
like( $warned, qr/Coercing -2 to 0/, 'Coercing -2 to 0' );
$warned = '';

Set($ judy, -1, 0 );
is( $warned, '', 'No warning or truncation for -1' );
$warned = '';
