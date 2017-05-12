use inc::Module::Install;

name 'HTML-ExtractContent';
all_from 'lib/HTML/ExtractContent.pm';

requires 'Class::Accessor::Lvalue::Fast';
requires 'Exporter::Lite';
requires 'List::Util';
requires 'HTML::Entities';

build_requires 'Test::More';
build_requires 'File::Slurp';

auto_include;
WriteAll;
