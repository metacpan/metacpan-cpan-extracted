use strict;
use inc::Module::Install::DSL;

name        Devel-Hints
license     CC0
all_from    Hints.pm
readme_from Hints.pm

build_requires ok
build_requires Test::More

ppport
cc_optimize_flags -Wno-format-security

sign
WriteAll
