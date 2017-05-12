use strict;
use ExtUtils::Depends;
use inc::Module::Install;

name 'Methods-CheckNames';
all_from 'lib/Methods/CheckNames.pm';

configure_requires 'ExtUtils::Depends';
configure_requires 'B::Hooks::OP::Check';
configure_requires 'B::Hooks::OP::PPAddr';

test_requires 'Test::More' => '0.88';

requires 'namespace::clean';
requires 'B::Hooks::OP::Check';
requires 'B::Hooks::OP::PPAddr';

my $pkg = ExtUtils::Depends->new('Methods::CheckNames', 'B::Hooks::OP::Check', 'B::Hooks::OP::PPAddr');
makemaker_args($pkg->get_makefile_vars);

WriteAll;
