use strict;
use inc::Module::Install 0.87;

perl_version '5.008';

name 'Lingua-JA-Halfwidth';
all_from 'lib/Lingua/JA/Halfwidth.pm';

test_requires 'Test::Perl::Critic';
use_test_base;

auto_install;

WriteAll;
