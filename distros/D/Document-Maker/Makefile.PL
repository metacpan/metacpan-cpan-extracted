use inc::Module::Install;

name 'Document-Maker';
all_from 'lib/Document/Maker.pm';

build_requires 'Test::More';
requires qw/Path::Class/;
requires qw/Moose 0.26/;
requires qw/Scalar::Util/;
requires qw/Log::Log4perl/;
requires qw/File::Find::Rule/;
requires qw/Carp/;
requires qw/Sub::Exporter/;

auto_install;

WriteAll;

