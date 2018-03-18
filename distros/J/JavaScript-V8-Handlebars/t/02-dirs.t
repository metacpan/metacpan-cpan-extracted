#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use FindBin;

use_ok( 'JavaScript::V8::Handlebars' ) || print "Bail out!\n";

my $hb = JavaScript::V8::Handlebars->new;
isa_ok( $hb, 'JavaScript::V8::Handlebars' );

eval { $hb->add_template_dir( "doesnt_exist" ) };
like( $@, qr/Failed to find/i, "Died with nonexistant directory" );

ok( $hb->add_template_dir( "$FindBin::Bin/data" ) );

like( $hb->execute_template('top'), qr/top/i, "Cached a template from the dir" );
like( $hb->execute_template('foo/foo'), qr/foo/i, "Cached a template from a sub-dir" );

my $bundle = $hb->bundle;

like( $bundle, qr{\['foo/foo'\]}, 'Bundle has cached files in it' );
like( $bundle, qr{\['bar/bar'\]} );
like( $bundle, qr{\['top'\]} );
like( $bundle, qr{registerPartial\('partials/part1'}, "Includes the partial" );

like( $hb->execute_template("partialtest"), qr/partial/ );

done_testing;
