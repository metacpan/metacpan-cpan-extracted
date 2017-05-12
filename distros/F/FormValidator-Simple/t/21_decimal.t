use strict;
use Test::More tests => 5;
BEGIN{ use_ok("FormValidator::Simple") }
use CGI;

my $q = CGI->new;
$q->param( num1 => '123.456' );
$q->param( num2 => '123' );
$q->param( num3 => '1234' );
$q->param( num4 => '123.4567' );

my $r = FormValidator::Simple->check( $q => [
    num1 => [ [qw/DECIMAL 3 3/] ],
    num2 => [ [qw/DECIMAL 3 3/] ],
    num3 => [ [qw/DECIMAL 3 3/] ],
    num4 => [ [qw/DECIMAL 3 3/] ],
] );

ok(!$r->invalid('num1'));
ok(!$r->invalid('num2'));
ok($r->invalid('num3'));
ok($r->invalid('num4'));

