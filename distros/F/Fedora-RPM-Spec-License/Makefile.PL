use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Handle Fedora RPM spec license string.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Fedora-RPM-Spec-License';
perl_version 5.008;
readme_from 'License.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'License::SPDX' => 0.04;
requires 'List::Util' => 0;
requires 'Parse::RecDescent' => 0;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Fedora-RPM-Spec-License/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/Fedora-RPM-Spec-License';
resources 'repository' => 'git://github.com/michal-josef-spacek/Fedora-RPM-Spec-License';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
