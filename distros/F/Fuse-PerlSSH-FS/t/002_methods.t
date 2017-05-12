

use Fuse::PerlSSH::FS;
use Test::More tests => 2;


$Fuse::PerlSSH::FS::self = { root => '/remote/filesystem' };

is( Fuse::PerlSSH::FS::path('/'), 	'/remote/filesystem',		'path: root dir translation');
is( Fuse::PerlSSH::FS::path('/subdir'),	'/remote/filesystem/subdir',	'path: subdir translation');
