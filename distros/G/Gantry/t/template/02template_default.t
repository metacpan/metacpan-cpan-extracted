use Test::More qw(no_plan);
use strict;

# template default plugin
use_ok('Gantry::Template::Default');
can_ok('Gantry::Template::Default', 'do_action', 'do_error', 'do_process' );

