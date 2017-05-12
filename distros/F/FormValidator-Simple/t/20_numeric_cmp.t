use strict;
use Test::More tests => 15;
use CGI;

BEGIN{ use_ok("FormValidator::Simple") }

my $q = CGI->new;

$q->param( age1 => 25 );
$q->param( age2 => 25 );
$q->param( age3 => 25 );
$q->param( age4 => 25 );

my $r = FormValidator::Simple->check( $q => [
    age1 => [ 'INT', [qw/GREATER_THAN 20/] ],
    age2 => [ 'INT', [qw/LESS_THAN 30/] ],
    age3 => [ 'INT', [qw/EQUAL_TO 25/] ],
    age4 => [ 'INT', [qw/BETWEEN 20 30/] ],
] );

ok(!$r->invalid('age1'));
ok(!$r->invalid('age2'));
ok(!$r->invalid('age3'));
ok(!$r->invalid('age4'));

my $r2 = FormValidator::Simple->check( $q => [
    age1 => [ 'INT', [qw/GREATER_THAN 30/] ],
    age2 => [ 'INT', [qw/LESS_THAN 20/] ],
    age3 => [ 'INT', [qw/EQUAL_TO 22/] ],
    age4 => [ 'INT', [qw/BETWEEN 0 22/] ],
] );

ok($r2->invalid('age1'));
ok($r2->invalid('age2'));
ok($r2->invalid('age3'));
ok($r2->invalid('age4'));

my $r3 = FormValidator::Simple->check( $q => [
  age1 => [ 'INT', [qw/GREATER_THAN 0/] ],
  age2 => [ 'INT', [qw/LESS_THAN 0/]    ],
  age3 => [ 'INT', [qw/EQUAL_TO 0/]     ],
] );

ok(!$r3->invalid('age1'));
ok($r3->invalid('age2'));
ok($r3->invalid('age3'));

my $q2 = CGI->new;
$q2->param( num1 => 3 );
$q2->param( num2 => 23.4 );
$q2->param( num3 => -12.4 );

my $r4 = FormValidator::Simple->check( $q2 => [
    num1 => [ [qw/BETWEEN -4 2/] ],
    num2 => [ [qw/BETWEEN 23.3 23.5/] ],
    num3 => [ [qw/BETWEEN -20 -10/] ],
] );
ok($r4->invalid('num1'));
ok(!$r4->invalid('num2'));
ok(!$r4->invalid('num3'));

