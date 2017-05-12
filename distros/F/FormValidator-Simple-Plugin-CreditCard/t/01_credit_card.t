use strict;
use Test::More tests => 4;

use FormValidator::Simple qw/CreditCard/;
use CGI;

my $q = CGI->new;
$q->param( number1 => '5276 4400 6542 1319' );
$q->param( number2 => '111111' );

my $result = FormValidator::Simple->check( $q => [
    number1 => [ 'CREDIT_CARD' ],
    number2 => [ 'CREDIT_CARD' ],
] );

ok(!$result->invalid('number1'));
ok($result->invalid('number2'));

my $result2 = FormValidator::Simple->check( $q => [  
    number1 => [ ['CREDIT_CARD', 'VISA', 'MASTER'] ],
    number2 => [ ['CREDIT_CARD', 'VISA'] ],
] );

ok(!$result2->invalid('number1'));
ok($result2->invalid('number2'));
