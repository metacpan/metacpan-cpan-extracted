use inc::Module::Install;

all_from 'lib/IronMan/Schema.pm';

requires 'DBIx::Class::Schema';

# Testing deps
test_requires 'Test::More';

WriteAll;
