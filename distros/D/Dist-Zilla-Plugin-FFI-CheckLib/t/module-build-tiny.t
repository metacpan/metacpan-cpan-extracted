use strict;
use warnings FATAL => 'all';

# Ported from Dist::Zilla::Plugin::CheckLib (C) 2014 Karen Etheridge

use Test::Requires { 'Dist::Zilla::Plugin::ModuleBuildTiny' => '0.007' };

use Path::Tiny;
my $code = path('t', 'basic.t')->slurp_utf8;

$code =~ s/'MakeMaker'/'ModuleBuildTiny'/g;
$code =~ s/ExtUtils::MakeMaker/Module::Build::Tiny/g;
$code =~ s/Makefile.PL/Build.PL/g;
$code =~ s/# build prereqs go here/build => \{ requires => \{ 'Module::Build::Tiny' => ignore \} \},/
    if eval { Dist::Zilla::Plugin::ModuleBuildTiny->VERSION('999') }; # adjust later

eval $code;
die $@ if $@;
