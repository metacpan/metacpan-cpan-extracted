use Test::More;
use strict;

use lib qw( t );
use engine::engine_methods qw( @engine_methods );

eval "use mod_perl2;";
my $mp2 = 1 unless $@;

eval "use Apache2::Request;";
my $has_libapreq = 1 unless $@;

if ( ! $mp2 ) {
	plan skip_all => "mod_perl2 not detected";
}
elsif ( ! $has_libapreq ) {
    diag( "mod_perl2 detected" );
    diag( "However Apache2::Request (libapreq2) was not." );
    diag( "Gantry's mod_perl2 engine requires Apache2::Request." );
    diag( "see http://httpd.apache.org/apreq/docs/libapreq2 for more" );
    diag( "information about installing libapreq2" );
    diag( "* this installation is painless and well worth it :-)" );
    
	plan skip_all => "Apache::Request not detected";
    
}
else {

    diag( "" );
    diag( "mod_perl version: " . $mod_perl::VERSION . " detected" );
    diag( "Do you want to run mod_perl $mod_perl::VERSION tests [yes]?" );
    my $p = <STDIN>;
    chomp( $p );
	$p ||= 'yes';
    if ( $p =~ /^yes/i ) {
        plan qw(no_plan);
        use_ok( 'Apache2::Request' );
    }
    else {
        plan skip_all => "mod_perl version $mod_perl::VERSION tests";
    }
}

use_ok('Gantry');
use_ok('Gantry::Stash');
use_ok('Gantry::Stash::View');
use_ok('Gantry::Stash::View::Form');
use_ok('Gantry::Stash::Controller');

use_ok('Gantry::Engine::MP20');
can_ok('Gantry::Engine::MP20', @engine_methods);



