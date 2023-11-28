use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Error::Pure HTML output helper.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.03;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Error-Pure-Output-Tags-HTMLCustomPage';
readme_from 'HTMLCustomPage.pm';
recursive_author_tests('xt');
requires 'Exporter' => 0;
requires 'HTTP::Headers::Fast' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/'.
	'Error-Pure-Output-Tags-HTMLCustomPage/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/'.
	'Error-Pure-Output-Tags-HTMLCustomPage';
resources 'repository' => 'git://github.com/michal-josef-spacek/'.
	'Error-Pure-Output-Tags-HTMLCustomPage';
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::More' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
