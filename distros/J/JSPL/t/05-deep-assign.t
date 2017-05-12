#!perl

use Test::More tests => 24;

use strict;
use warnings;

use Test::Exception;

use JSPL;

my $rt1 = JSPL::Runtime->new();
my $cx1 = $rt1->create_context();

lives_ok { $cx1->bind_function( name => 'foo.bar.baz', func => sub { return 8 } ) } "bound foo.bar.baz as function ok";
lives_ok { $cx1->bind_value( 'egg.spam.spam' => "urrrgh" ) } "bound egg.spam.span as value ok";

is( $cx1->eval(q|foo.bar.baz()|), 8, "got 8" );
is( $cx1->eval(q|egg.spam.spam|), 'urrrgh', "beans are off" );

lives_ok { $cx1->bind_value( spam => 'urrrgh' ) } "bind value ok";
is( $cx1->eval(q|spam|), 'urrrgh', "beans are off" );
is( $cx1->eval(q|foo.bar.baz()|), 8, "got 8" );

lives_ok { $cx1->bind_value( 'egg.yolk.spam' => "got me?" ) } "bound egg.yolk.spam ok";

is( $cx1->eval(q|egg.yolk.spam|), 'got me?', "beans are off" );
is( $cx1->eval(q|egg.spam.spam|), 'urrrgh', "beans are off" );

throws_ok { $cx1->bind_value( 'spam' => "urrgh" ); }
    qr/spam already exists, unbind it first/, "Must unbind";
throws_ok { $cx1->bind_value( 'egg.yolk.spam' => "got me again?" ); }
    qr/egg.yolk.spam already exists, unbind it first/, "Must unbind";

lives_ok { $cx1->unbind_value("spam") } "unbound spam ok";
throws_ok { $cx1->eval("spam;") } 
    qr/is not defined/, "unbound spam really is ok";

lives_ok { $cx1->unbind_value("egg.yolk.spam") } "unbound egg.yolk.spam ok";

ok(!defined($cx1->eval("egg.yolk.spam;")), "unbound egg.yolk.spam really is ok");
lives_ok { $cx1->bind_value( spam => 1 ) } "rebound spam ok";
lives_ok { $cx1->bind_value( 'egg.yolk.spam' => 2 ) } "rebound egg.yolk.spam ok";

is( $cx1->eval(q|spam|), 1, "got 1" );
is( $cx1->eval(q|egg.yolk.spam|), 2, "got 2" );

# foo.bar.baz is a perl func, check binding on that
lives_ok { $cx1->bind_value('foo.bar.baz.egg' => 'other') } "Bind over visitor";
is( $cx1->eval(q|foo.bar.baz.egg|), 'other', 'got other');
isa_ok( $cx1->eval(q|foo.bar.baz|), 'CODE', 'Still coderef');
is( $cx1->eval(q|foo.bar.baz()|), 8, "called again");
