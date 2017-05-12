use v5.10;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name 'Media-Type-Simple';
all_from 'lib/Media/Type/Simple.pm';
license 'artistic_2';

perl_version 5.010;

tests_recursive('t');

# tests_recursive('xt');

resources(
    homepage   => 'http://rrwo.tumblr.com',
    license    => 'http://www.perlfoundation.org/artistic_license_2_0',
    repository => 'git://github.com/robrwo/Media-Types-Simple.git',
    bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Media-Type-Simple',
);

configure_requires();

build_requires();

requires(
    'Carp'           => 0,
    'Exporter::Lite'  => 0,
    'File::Share'    => 0,
    'File::ShareDir' => 0,
    'Storable'       => 0,
    'version'        => 0,
);

recommends(
    'Test::Warnings'   => 0,
);

test_requires(
    'Test::Fork'       => 0,
    'Test::More'       => 0,
);

install_share 'share';

install_as_cpan;
auto_install;
WriteAll;
