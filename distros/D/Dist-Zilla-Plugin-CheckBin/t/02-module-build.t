use strict;
use warnings FATAL => 'all';

use Path::Tiny;
my $code = path('t', '01-basic.t')->slurp_utf8;

$code =~ s/'MakeMaker'/'ModuleBuild'/g;
$code =~ s/ExtUtils::MakeMaker/Module::Build/g;
$code =~ s/Makefile.PL/Build.PL/g;
$code =~ s/# build prereqs go here/build => \{ requires => \{ 'Module::Build' => ignore \} \},/;

eval $code;
die $@ if $@;
