use lib '.';
use strict;
use warnings;

use inc::Module::Install;

$ENV{'ALIEN_DJVULIBRE_PROBE_TOOLS'} = 'djvudump';

# Definition.
abstract 'Detect DjVu file';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'DjVu-Detect';
perl_version 5.006002;
readme_from 'Detect.pm';
recursive_author_tests('xt');
requires 'Alien::DjVuLibre' => 0.05;
requires 'Error::Pure' => 0.15;
requires 'Exporter' => 0;
requires 'File::Spec::Functions' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/DjVu-Detect/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/DjVu-Detect';
resources 'repository' => 'git://github.com/michal-josef-spacek/DjVu-Detect';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Object' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
