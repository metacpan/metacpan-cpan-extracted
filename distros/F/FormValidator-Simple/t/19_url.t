use strict;
use Test::More tests => 3;
use CGI;

BEGIN{ use_ok("FormValidator::Simple") }

my $q = CGI->new;

$q->param( hoge => 'http://www.lost-season.jp/mt/' );
$q->param( foo  => 'lyo.kato@gmail.com' );

my $r = FormValidator::Simple->check( $q => [
    hoge => [ 'HTTP_URL' ],
    foo  => [ 'HTTP_URL' ],
] );

ok(!$r->invalid('hoge'));

ok($r->invalid('foo'));
