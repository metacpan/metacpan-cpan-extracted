#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

#plan tests => 25;

use_ok( 'JavaScript::V8::Handlebars' ) || print "Bail out!\n";

my $hb = JavaScript::V8::Handlebars->new;
isa_ok( $hb, 'JavaScript::V8::Handlebars' );

is( $hb->render_string("hello {{name}}", {name=>"bob"}), "hello bob" );

is( $hb->render_string("hello {{#if name}}{{name}}{{/if}}",{name=>"bob"}), "hello bob" );

ok( $hb->register_helper("helper1",sub{return "helper1 done"}) );

is( $hb->render_string( "test {{helper1}}" ), "test helper1 done" );

ok( $hb->register_helper("helper2","function(){return 'helper2 done'}") );

is( $hb->render_string( "test {{helper2}}" ), "test helper2 done" );


is( $hb->render_string( "test {{#each list}}{{var}}{{/each}}", {list=>[{var=>1},{var=>2},{var=>3}]} ),
	"test 123",
	"Test a built-in helper"
);

ok( $hb->register_partial( "partial1", "partial1" ) );
is( $hb->render_string( "test {{> partial1 }}" ), "test partial1", "Testing user defined javascript partials" );

ok( $hb->register_partial( "partial2", $hb->template($hb->precompile("partial2")) ) );
is( $hb->render_string( "test {{> partial2 }}" ), "test partial2", "Testing user defined code partials" );

is( $hb->compile("test {{foo}}")->({foo=>42}), "test 42" );

my $precompile = $hb->precompile("test {{bar}}");
ok( $precompile );

ok( my $template = $hb->template( $precompile ) );

is( $template->({bar=>43}), "test 43" );


my $c = $hb->c; #Get a JS context with Handlebars preloaded

ok( $hb->add_template( "precompiletest", "hello this is {{var}}" ) );
my $code = $hb->bundle;
ok( $code );
ok( $c->eval( $code ) );

is( $c->eval( "Handlebars.templates.precompiletest({var:'precompiled'})" ), "hello this is precompiled" );
ok( not defined $@ );


eval { JavaScript::V8::Handlebars->new };
ok( ! $@, "Creating multiple objects doesn't explode anything" );

ok( $hb->escape_expression( "foo" ), "Call doesn't die" );

ok( eval{ $hb->eval( "console.log()" ); 1; }, "Console.log doesn't die!" );

done_testing();
