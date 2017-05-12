use inc::Module::Install;

name 'Geo-WKT-Simple';
all_from 'lib/Geo/WKT/Simple.pm';

tests 't/*.t';

requires 'parent';
test_requires 'Test::More';

# readme_markdown_from 'lib/Geo/WKT/Simple.pm';

WriteAll;
