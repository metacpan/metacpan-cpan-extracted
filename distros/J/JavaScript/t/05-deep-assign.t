#!perl

use Test::More tests => 20;

use strict;
use warnings;

use Test::Exception;

use JavaScript;

my $rt1 = JavaScript::Runtime->new();
my $cx1 = $rt1->create_context();

lives_ok { $cx1->bind_function( name => 'foo.bar.baz', func => sub { return 8 } ) } "bound foo.bar.baz as function ok";
lives_ok { $cx1->bind_value( 'egg.spam.spam' => "urrrgh" ) } "bound egg.spam.span as vaulue ok";

is( $cx1->eval(q!foo.bar.baz()!), 8, "got 8" );
is( $cx1->eval(q!egg.spam.spam!), 'urrrgh', "beans are off" );

lives_ok { $cx1->bind_value( spam => 'urrrgh' ) } "bind value ok";
is( $cx1->eval(q!spam!), 'urrrgh', "beans are off" );
is( $cx1->eval(q!foo.bar.baz()!), 8, "got 8" );

lives_ok { $cx1->bind_value( 'egg.yolk.spam' => "got me?" ) } "bound egg.yolk.spam ok";

is( $cx1->eval(q!egg.yolk.spam!), 'got me?', "beans are off" );
is( $cx1->eval(q!egg.spam.spam!), 'urrrgh', "beans are off" );

throws_ok { $cx1->bind_value( 'spam' => "urrgh" ); } qr/spam already exists, unbind it first/;
throws_ok { $cx1->bind_value( 'egg.yolk.spam' => "got me again?" ); } qr/egg.yolk.spam already exists, unbind it first/;

lives_ok { $cx1->unbind_value("spam"); } "unbound spam ok";
ok(!defined $cx1->eval("spam;"), "unbound spam really is ok");
lives_ok { $cx1->unbind_value("egg.yolk.spam") } "unbound egg.yolk.spam ok";
ok(!defined $cx1->eval("egg.yolk.spam"), "unbound egg.yolk.spam really is ok");
lives_ok { $cx1->bind_value( spam => 1 ) } "rebound spam ok";
lives_ok { $cx1->bind_value( 'egg.yolk.spam' => 2 ) } "rebound egg.yolk.spam ok";

is( $cx1->eval(q!spam!), 1, "got 1" );
is( $cx1->eval(q!egg.yolk.spam!), 2, "got 2" );
