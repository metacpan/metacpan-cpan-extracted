#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

# Info functions
# https://proj.org/development/reference/functions.html#info-functions

plan tests => 9 + 8 + 10 + 6 + $no_warnings;

use Geo::LibProj::FFI qw( :all );


my ($s, $p, $i);


# proj_info

lives_and { ok $i = proj_info() } 'info';
lives_and { ok $i->major > 4 } 'info major';
lives_and { ok $i->minor >= 0 } 'info minor';
lives_and { ok $i->patch >= 0 } 'info patch';
my $version = '';
eval { $version = $i->major . '.' . $i->minor . '.' . $i->patch };
diag "PROJ $version" if $ENV{AUTHOR_TESTING} || $ENV{AUTOMATED_TESTING};
lives_and { like $i->release, qr/\b\Q$version\E\b/ } 'info release';
lives_and { like $i->version, qr/^\Q$version\E\b/ } 'info version';
lives_and { like $i->searchpath, qr#\bAlien-proj\b|/proj\b# } 'info searchpath';
# These two are not publicly documented and always seem to return 0:
lives_ok { $i->paths } 'info paths';
lives_ok { $i->path_count } 'info path_count';


# proj_pj_info

$s = "proj=merc ellps=WGS84";
lives_and { ok $p = proj_create(0, $s) } 'proj_create';
SKIP: { skip "(proj_create failed)", 2 unless $p;
	lives_and { ok $i = proj_pj_info($p) } 'info';
	lives_and { is $i->id(), "merc" } 'pj_info id';
	lives_and { like $i->description(), qr/\bcoordinate op/ } 'pj_info description';
	lives_and { is $i->definition(), $s } 'pj_info definition';
	lives_and { is $i->has_inverse(), 1 } 'pj_info has_inverse';
	lives_and { is $i->accuracy(), -1 } 'pj_info accuracy';
}
lives_ok { proj_destroy($p) } 'proj_destroy';


# proj_grid_info

$s = "";
lives_and { ok $i = proj_grid_info($s) } 'grid_info';
lives_and { is $i->gridname(), $s } 'grid_info gridname';
lives_and { like $i->filename(), qr/\Q$s\E$/ } 'grid_info filename';
lives_and { is $i->format(), "missing" } 'grid_info format';
lives_and { like ref($i->lowerleft),  qr/\bPJ_COORD$/ } 'grid_info lowerleft';
lives_and { like ref($i->upperright), qr/\bPJ_COORD$/ } 'grid_info upperright';
lives_ok { $i->n_lon } 'grid_info n_lon';
lives_ok { $i->n_lat } 'grid_info n_lat';
lives_ok { $i->cs_lon } 'grid_info cs_lon';
lives_ok { $i->cs_lat } 'grid_info cs_lat';


# proj_init_info

$s = "ITRF2014";
lives_and { ok $i = proj_init_info($s) } 'init_info';
lives_and { is $i->name(), $s } 'init_info name';
lives_and { like $i->filename(), qr/\Q$s\E$/ } 'init_info filename';
lives_ok { $i->version() } 'init_info version';
lives_ok { $i->origin() } 'init_info origin';
lives_and { like $i->lastupdate(), qr/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ } 'init_info lastupdate';


done_testing;
