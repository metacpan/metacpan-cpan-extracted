use strict;
use Test::More tests => 4;
use CGI;

BEGIN{ use_ok("FormValidator::Simple") }

my $q = CGI->new;

$q->param( hoge => 'hogefoo' );

my $r = FormValidator::Simple->check( $q => [
    hoge => [ ['REGEX', qr/^hoge/] ],
] );

ok(!$r->invalid('hoge'));

my $r2 = FormValidator::Simple->check( $q => [
    hoge => [ ['NOT_REGEX', qr/^hoge/] ],
] );

ok($r2->invalid('hoge'));

my $r3 = FormValidator::Simple->check( $q => [
    hoge => [ ['REGEX', qr/^foo/] ], 
] );

ok($r3->invalid('hoge'));
