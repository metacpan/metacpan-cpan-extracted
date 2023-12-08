#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

# Cleanup
# https://proj.org/development/reference/functions.html#cleanup

plan tests => 1 + $no_warnings;

use Geo::LibProj::FFI qw( :all );


my ($c, $p);


eval {
	$c = proj_context_create();
	proj_context_use_proj4_init_rules($c, 1);
	$p = proj_create_crs_to_crs($c, "+init=epsg:25832", "+init=epsg:25833", 0);
	proj_destroy($p) if $p;
};
eval { proj_context_destroy($c) } if $c;

lives_ok { proj_cleanup() } 'cleanup';


done_testing;
