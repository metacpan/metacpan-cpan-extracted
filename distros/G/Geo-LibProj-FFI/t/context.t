#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

# Threading contexts
# https://proj.org/development/reference/functions.html#threading-contexts

plan tests => 3 + $no_warnings;

use Geo::LibProj::FFI qw( :all );


my ($c);


# proj_context_create

lives_and { ok $c = proj_context_create() } 'context_create';


# proj_context_clone

# proj_context_use_proj4_init_rules

lives_ok { proj_context_use_proj4_init_rules($c, 1) } 'context_use_proj4_init_rules';


# proj_context_destroy

lives_ok { proj_context_destroy($c) } 'context_destroy';


done_testing;
