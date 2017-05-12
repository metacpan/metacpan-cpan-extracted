use strict;
use warnings;
use inc::Module::Install;
use Module::Install::Repository;
use Module::Install::AuthorTests;

all_from 'lib/Dist/Maker.pm';

# CPAN modules
requires 'Text::Xslate'              => 0.2008;
requires 'Mouse'                     => 0.64;
requires 'MouseX::StrictConstructor' => 0.02;
requires 'MouseX::NativeTraits'      => 0.002;
requires 'Config::Tiny';

requires 'Module::Install';
requires 'Module::Install::AuthorTests';
requires 'Module::Install::Repository';
requires 'Module::Install::XSUtil';

requires 'Test::More'      => 0.88;
requires 'Test::Requires'  => 0.03;
requires 'Test::LeakTrace' => 0.13;

# standard modules
requires 'Getopt::Long' => 2.36;
requires 'parent';
requires 'File::Spec';
requires 'File::Path';
requires 'File::Basename';

test_requires 'Moose';
test_requires 'MooseX::StrictConstructor';
test_requires 'Any::Moose';
test_requires 'Test::Pod::Coverage';
test_requires 'Test::Perl::Critic';

install_script 'dim';

tests_recursive;
author_tests 'xt';

auto_set_repository;

clean_files qw(
    Dist-Maker-* *.stackdump
    cover_db
    nytprof
    *.out
    .test*
);

WriteAll(check_nmake => 0);
