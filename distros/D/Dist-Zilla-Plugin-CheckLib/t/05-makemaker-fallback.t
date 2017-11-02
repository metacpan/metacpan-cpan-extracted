use strict;
use warnings;

use Test::Needs 'Dist::Zilla::Plugin::MakeMaker::Fallback';

use Path::Tiny;
my $code = path('t', '01-basic.t')->slurp_utf8;

$code =~ s/^(.*)'MakeMaker'(.*)$/${1}'MakeMaker::Fallback'${2}\n${1}'ModuleBuild'${2}/m;

if (eval { Dist::Zilla::Plugin::MakeMaker::Fallback->VERSION(0.024); 1 }) {
    $code =~ s/^(.*)'ExtUtils::MakeMaker'(.*)\[MakeMaker\K/::Fallback\]\n${1}'Module::Build'${2}\[ModuleBuild/m;
} elsif (eval { Dist::Zilla::Plugin::MakeMaker::Fallback->VERSION(0.015); 1 }) {
    $code =~ s/^(.*)'ExtUtils::MakeMaker'(.*)\[MakeMaker\](.*)$/${1}'Module::Build'${2}\[ModuleBuild\]${3}/m;
} else {
    $code =~ s/^(.*)'ExtUtils::MakeMaker'(.*)\[MakeMaker\](.*)\K$/\n${1}'Module::Build'${2}\[ModuleBuild\]${3}/m;
}

$code =~ s/# build prereqs go here/build => \{ requires => \{ 'Module::Build' => ignore \} \},/;

eval $code;
die $@ if $@;
