use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Object for SPDX licenses handling.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_share 'share';
license 'bsd';
name 'License-SPDX';
perl_version 5.008;
readme_from 'SPDX.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Cpanel::JSON::XS' => 0;
requires 'Error::Pure' => 0;
requires 'File::Share' => 0;
requires 'List::Util' => 0;
requires 'Perl6::Slurp' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/License-SPDX/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/License-SPDX';
resources 'repository' => 'git://github.com/michal-josef-spacek/License-SPDX';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
