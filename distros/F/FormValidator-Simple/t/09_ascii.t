use strict;
use Test::More tests => 5;
use CGI;

BEGIN{ use_ok("FormValidator::Simple") }

my $q = CGI->new;
$q->param( param1 => 'abcd' );
$q->param( param2 => '日本語' );

my $r = FormValidator::Simple->check( $q => [
    param1 => [qw/ASCII/],
    param2 => [qw/ASCII/],
] );

ok(!$r->invalid('param1'));
ok($r->invalid('param2'));

my $r2 = FormValidator::Simple->check( $q => [
    param1 => [qw/NOT_ASCII/],
    param2 => [qw/NOT_ASCII/],
] );


ok($r2->invalid('param1'));
ok(!$r2->invalid('param2'));

