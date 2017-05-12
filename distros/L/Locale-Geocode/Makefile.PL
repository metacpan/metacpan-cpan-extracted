#!/usr/bin/perl -w

use warnings;
use strict;

use inc::Module::Install;

name			'Locale-Geocode';
author			'Mike Eldridge <diz@cpan.org>';
license			'perl';

build_requires	'Test::More'		=> '0.42';
build_requires	'Test::Pod'			=> 0;
requires		'XML::SAX::Expat'	=> 0.39;
requires		'XML::Simple'		=> 2.16;

version_from	'lib/Locale/Geocode.pm';

auto_install;

WriteAll;
