use strict;
use warnings;

use Test::Needs { 'Dist::Zilla::Plugin::ModuleBuildTiny' => '0.007' };

use Path::Tiny;
my $code = path('t', '01-basic.t')->slurp_utf8;

$code =~ s/'MakeMaker'/'ModuleBuildTiny'/g;
$code =~ s/ExtUtils::MakeMaker/Module::Build::Tiny/g;
$code =~ s/Makefile.PL/Build.PL/g;
$code =~ s/# build prereqs go here/build => \{ requires => \{ 'Module::Build::Tiny' => ignore \} \},/
    if eval { Dist::Zilla::Plugin::ModuleBuildTiny->VERSION('999') }; # adjust later

eval $code;
die $@ if $@;
