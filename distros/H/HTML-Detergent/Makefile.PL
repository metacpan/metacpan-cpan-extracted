use inc::Module::Install;

name     'HTML-Detergent';
all_from 'lib/HTML/Detergent.pm';
author   q{Dorian Taylor <dorian@cpan.org>};
license  'apache';

requires 'Moose';
requires 'MooseX::Types';
requires 'namespace::autoclean';
requires 'XML::LibXML';
requires 'XML::LibXSLT';
requires 'XML::LibXML::LazyBuilder';
requires 'HTML::HTML5::Parser';

build_requires 'Test::More';

auto_install;

WriteAll;

