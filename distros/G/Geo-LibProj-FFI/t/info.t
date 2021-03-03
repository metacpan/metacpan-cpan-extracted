#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings;

# Info functions
# https://proj.org/development/reference/functions.html#info-functions

plan tests => 9 + 1;

use Geo::LibProj::FFI qw( :all );


my ($i);


# proj_info

lives_and { ok $i = proj_info() } 'info';
lives_and { ok $i->major > 4 } 'info major';
lives_and { ok $i->minor >= 0 } 'info minor';
lives_and { ok $i->patch >= 0 } 'info patch';
my $version = '';
eval { $version = $i->major . '.' . $i->minor . '.' . $i->patch };
diag "PROJ $version";
lives_and { like $i->release, qr/\b\Q$version\E\b/ } 'info release';
lives_and { like $i->version, qr/^\Q$version\E\b/ } 'info version';
lives_and { like $i->searchpath, qr#\bAlien-proj\b|/proj\b# } 'info searchpath';
# These two are not publicly documented and always seem to return 0:
lives_ok { $i->paths } 'info paths';
lives_ok { $i->path_count } 'info path_count';


# proj_pj_info

# proj_grid_info

# proj_init_info


done_testing;
