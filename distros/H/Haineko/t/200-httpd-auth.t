use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::HTTPD::Auth;
use Haineko::JSON;
use Test::More;

$Haineko::HTTPD::Auth::PasswordDB = Haineko::JSON->loadjson( <DATA> );
isa_ok( $Haineko::HTTPD::Auth::PasswordDB, 'HASH' );

my $methodargv = { 'username' => 'haineko', 'password' => 'kijitora' };
ok( Haineko::HTTPD::Auth->basic( %$methodargv ) );

$methodargv = {};
is( Haineko::HTTPD::Auth->basic( %$methodargv ), 0 );

$methodargv = { 'username' => 'neko' };
is( Haineko::HTTPD::Auth->basic( %$methodargv ), 0 );

$methodargv = { 'password' => 'neko' };
is( Haineko::HTTPD::Auth->basic( %$methodargv ), 0 );

$methodargv = { 'username' => 'neko', 'password' => 'neko' };
is( Haineko::HTTPD::Auth->basic( %$methodargv ), 0 );

$Haineko::HTTPD::Auth::PasswordDB = undef;
is( Haineko::HTTPD::Auth->basic( %$methodargv ), undef );

done_testing();
__DATA__
haineko: '{SSHA}9p2euyteR33mp0TYKjmYhTlIt1ctxuRn'
