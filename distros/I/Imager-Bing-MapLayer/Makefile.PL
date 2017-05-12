use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name 'Imager-Bing-MapLayer';
version_from 'lib/Imager/Bing/MapLayer.pm';
author q{Robert Rothenberg <rrwo@cpan.org>};
license 'artistic_2';

perl_version 5.010001;

tests_recursive('t');
# tests_recursive('xt') if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING};

resources(
    homepage   => 'http://rrwo.tumblr.com',
    license    => 'artistic2',
    repository => 'git://github.com/robrwo/Imager-Bing-MapLayer.git',
    bugtracker => 'https://github.com/robrwo/Imager-Bing-MapLayer/issues',
);

configure_requires();

build_requires(
    'aliased'          => 0,
    'File::Find::Rule' => 0,
    'File::Temp'       => 0,
    'if'               => 0,
    'Image::Size'      => 0,
    'Test::Exception'  => 0,
    'Test::More'       => 0,
    'Test::Most'       => 0,
    'Test::Warnings'   => 0,
);

requires(
    'Carp'                         => 0,
    'Class::MOP::Method'           => 0,
    'Const::Exporter'              => 0,
    'Const::Fast'                  => 0,
    'Cwd'                          => 0,
    'Exporter::Lite'               => 0,
    'Imager'                       => 0,
    'List::MoreUtils'              => 0.07,
    'List::Util'                   => 1.30,
    'Path::Class'                  => 0,
    'POSIX::2008'                  => 0,
    'Module::Load'                 => 0,
    'Moose'                        => 0,
    'Moose::Util::TypeConstraints' => 0,
    'MooseX::StrictConstructor'    => 0,
    'namespace::autoclean'         => 0,
    'Type::Tiny'                   => 0,
    'version'                      => 0.77,
);

recommends( 'Type::Tiny::XS' => 0, );

install_as_cpan;
auto_install;
WriteAll;
