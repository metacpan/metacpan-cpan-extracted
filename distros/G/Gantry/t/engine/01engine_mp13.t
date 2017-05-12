use Test::More;
use strict;

use lib qw( t );
use engine::engine_methods qw( @engine_methods );

eval "use mod_perl;";
my $mp1 = 1 unless $@;

if ( ! $mp1 ) {
	plan skip_all => "mod_perl1 not detected";
}
elsif ( $mp1 &&  $mod_perl::VERSION >= 1.99 ) {
	plan skip_all => "mod_perl1 not detected";
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

use_ok('Gantry::Engine::MP13');
can_ok('Gantry::Engine::MP13', @engine_methods);
