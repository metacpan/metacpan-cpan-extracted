#!perl -T
use strict;
use warnings;
use Test::More tests => 1;

use_ok 'Dist::Zilla::Plugin::UseBuildPL' or BAIL_OUT "Can't use module";
diag "Testing Dist::Zilla::Plugin::UseBuildPL $Dist::Zilla::Plugin::UseBuildPL::VERSION, Perl $], $^X";
