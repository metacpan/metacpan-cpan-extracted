use strict;
use lib '.';
use inc::Module::Install;

name            ('Makefile-Parser');
perl_version    ('5.006001');
all_from        ('lib/Makefile/Parser.pm');

repository 'http://github.com/agentzh/makefile-parser-pm';

install_script  ('script/plmake');
install_script  ('script/pgmake-db');
install_script  ('script/makesimple');

requires        ('Text::Balanced');
requires        ('List::Util');
requires        ('List::MoreUtils');
requires        ('File::Spec');
requires        ('Class::Accessor::Fast');
requires        ('Cwd');
requires        ('File::Slurp');
requires        ('Makefile::DOM' => '0.008');
requires        ('Class::Trigger' => '0.13');
requires        ('Time::HiRes');

build_requires  ('Test::More');
build_requires  ('IPC::Run3' => '0.036');

use_test_base;

auto_install;
WriteAll;

