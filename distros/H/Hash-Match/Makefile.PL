use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Hash-Match';
all_from 'lib/Hash/Match.pm';
license  'artistic_2';

perl_version 5.010;

tests_recursive('t');
# tests_recursive('xt');

resources (
   homepage   => 'http://rrwo.tumblr.com',
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   repository => 'git://github.com/robrwo/Hash-Match.git',
   bugtracker => 'https://github.com/robrwo/Hash-Match/issues',
);

configure_requires ();

build_requires (
    'Test::More'      => 0.98, # for subtests
    'Test::Exception' => 0,
);

requires (
    'Carp'                 => 0,
    'List::MoreUtils'      => 0.07,
    'namespace::autoclean' => 0,
    'version'              => 0.77,
);

test_requires (
    'Test::More'      => 0.98,
    'Test::Exception' => 0,
);

install_as_cpan;
auto_install;
WriteAll;
