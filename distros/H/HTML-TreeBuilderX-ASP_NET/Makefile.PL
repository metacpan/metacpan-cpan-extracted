use inc::Module::Install;

name     'HTML-TreeBuilderX-ASP_NET';
all_from 'lib/HTML/TreeBuilderX/ASP_NET.pm';
author   'Evan Carroll <me@evancarroll.com>';

requires 'Class::MOP';
requires 'MooseX::Traits';
requires 'HTML::TreeBuilder';
requires 'HTTP::Request::Form';

# Because this module breaks a lot, and this is all that i've tested them with
requires 'MooseX::Types' => '0.19';
requires 'Moose' => '0.89';

repository 'git@github.com:EvanCarroll/perl-html-treebuilderx-asp_net.git';

build_requires 'Test::More';

auto_install;

WriteAll;

