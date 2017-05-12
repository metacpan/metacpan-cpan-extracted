use inc::Module::Install;

name                 'Lux-IO';
author               'Kentaro Kuribayashi, <kentarok@cpan.org>';
all_from             'lib/Lux/IO.pm';
license              'perl';
build_requires       'Test::More';
build_requires       'File::Temp';
makemaker_args       CC    => 'g++';
makemaker_args       LD    => 'g++';
makemaker_args       XSOPT => '-C++';
makemaker_args       XSOPT => '-C++';
makemaker_args       LIBS  => '-lluxio';
cc_inc_paths         '.';
cc_files             'IO.c';
can_cc               or die 'This module requires C++ compiler.';
use_test_base;
auto_include_deps;
WriteAll;
