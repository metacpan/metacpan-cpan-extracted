use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Wikimedia OAuth2 provider for LWP::Authen::OAuth2.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'LWP-Authen-OAuth2-ServiceProvider-Wikimedia';
perl_version 5.006;
readme_from 'Wikimedia.pm';
recursive_author_tests('xt');
requires 'LWP::Authen::OAuth2::ServiceProvider::MediaWiki' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/LWP-Authen-OAuth2-ServiceProvider-Wikimedia/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/LWP-Authen-OAuth2-ServiceProvider-Wikimedia';
resources 'repository' => 'git://github.com/michal-josef-spacek/LWP-Authen-OAuth2-ServiceProvider-Wikimedia';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'LWP::Authen::OAuth2' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
