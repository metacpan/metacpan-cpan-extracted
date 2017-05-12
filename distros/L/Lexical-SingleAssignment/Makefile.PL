use strict;
use ExtUtils::Depends;
use inc::Module::Install;

name 'Lexical-SingleAssignment';
all_from 'lib/Lexical/SingleAssignment.pm';

configure_requires 'ExtUtils::Depends';
configure_requires 'B::Hooks::OP::Check';

test_requires 'Test::More' => '0.88';

requires 'namespace::clean';
requires 'B::Hooks::OP::Check';

my $pkg = ExtUtils::Depends->new('Lexical::SingleAssignment', 'B::Hooks::OP::Check');
makemaker_args($pkg->get_makefile_vars);

repository 'git://github.com/nothingmuch/Lexical-SingleAssignment.git';

ppport;

WriteAll;
