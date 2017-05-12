use strict;
use warnings;

use lib '.';
use inc::Module::Install;

name 'HTML-TableParser';
license 'gpl3';

auto_license( holder => 'Smithsonian Astrophysical Observatory' );

all_from 'lib/HTML/TableParser.pm';

repository 'http://bitbucket.org/djerius/html-tableparser';

author_tests( 'xt' );

cpanfile;

WriteAll;

