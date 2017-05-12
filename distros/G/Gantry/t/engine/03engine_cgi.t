use Test::More qw(no_plan);
use strict;

use lib qw( t );
use engine::engine_methods qw( @engine_methods );

use_ok('Gantry');
use_ok('Gantry::Stash');
use_ok('Gantry::Stash::View');
use_ok('Gantry::Stash::View::Form');
use_ok('Gantry::Stash::Controller');

use_ok('Gantry::Engine::CGI');
can_ok('Gantry::Engine::CGI', 
	@engine_methods, 'cgi_obj', 'config', 'locations' );
