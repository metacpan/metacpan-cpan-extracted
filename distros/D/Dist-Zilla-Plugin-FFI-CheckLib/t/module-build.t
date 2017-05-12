use strict;
use warnings FATAL => 'all';

# Ported from Dist::Zilla::Plugin::CheckLib (C) 2014 Karen Etheridge

use Path::Tiny;
my $code = path('t', 'basic.t')->slurp_utf8;

$code =~ s/'MakeMaker'/'ModuleBuild'/g;
$code =~ s/ExtUtils::MakeMaker/Module::Build/g;
$code =~ s/Makefile.PL/Build.PL/g;
$code =~ s/# build prereqs go here/build => \{ requires => \{ 'Module::Build' => ignore \} \},/;

eval $code;
die $@ if $@;
