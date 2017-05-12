use inc::Module::Install;
name 'List-Enumerator';
all_from 'lib/List/Enumerator.pm';

requires 'List::Util';
requires 'List::MoreUtils';
requires 'Exception::Class';
requires 'Sub::Exporter';
requires 'Class::Accessor::Fast';
requires 'Class::ISA';
requires 'Devel::Symdump';

test_requires 'Test::More';
test_requires 'Test::Class';
test_requires 'Test::Exception';
#test_requires 'Test::Dependencies';
#test_requires 'Test::Perl::Critic';

use_test_base;
auto_include;
WriteAll;
