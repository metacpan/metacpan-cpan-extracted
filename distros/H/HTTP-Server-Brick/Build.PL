# $Id$

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTTP::Server::Brick',
    license             => 'perl',
    dist_author         => 'Mark Aufflick <mark@aufflick.com>',
    dist_version        => '0.1.7',
    dist_abstract       => 'Simple pure perl http/https server for prototyping "in the style of" Ruby\'s WEBrick',
    requires => {
        'Module::Build' => 0,
        'Test::More' => 0,
		'version' => 0,
		'HTTP::Daemon' => 0,
		'HTTP::Status' => 0,
		'LWP::MediaTypes' => 0,
        'LWP' => 0,
        'LWP::UserAgent' => 0,
		'IO::Handle' => 0,
    },
    recommends => {
        'HTTP::Daemon::SSL' => '1.02',
    },
    add_to_cleanup      => [ 'HTTP-Server-Brick-*' ],
);

$builder->create_build_script();
