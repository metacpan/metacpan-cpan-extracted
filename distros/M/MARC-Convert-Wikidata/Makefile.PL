use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Conversion class between MARC record and Wikidata object.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'MARC-Convert-Wikidata';
perl_version 5.006002;
readme_from 'Wikidata.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Data::Kramerius' => 0;
requires 'DateTime' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'MARC::Convert::Wikidata::Object' => 0;
requires 'Readonly' => 0;
requires 'Roman' => 0;
requires 'Unicode::UTF8' => 0;
requires 'Wikibase::Datatype' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/MARC-Convert-Wikidata/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/MARC-Convert-Wikidata';
resources 'repository' => 'git://github.com/michal-josef-spacek/MARC-Convert-Wikidata';
test_requires 'File::Object' => 0;
test_requires 'MARC::Record' => 0;
test_requires 'Perl6::Slurp' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Warn' => 0;
test_requires 'Unicode::UTF8' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
