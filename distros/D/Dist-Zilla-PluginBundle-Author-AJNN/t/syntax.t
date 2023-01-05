#!perl

use 5.026;
use warnings;

use Test::More;
use Test::Warnings;

plan tests => 5 + 1;

require_ok 'Pod::Weaver::PluginBundle::Author::AJNN::Author';
require_ok 'Pod::Weaver::PluginBundle::Author::AJNN::License';
require_ok 'Pod::Weaver::PluginBundle::Author::AJNN';
require_ok 'Dist::Zilla::PluginBundle::Author::AJNN::Readme';
require_ok 'Dist::Zilla::PluginBundle::Author::AJNN';

done_testing;
