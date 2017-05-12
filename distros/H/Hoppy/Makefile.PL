use inc::Module::Install;
name 'Hoppy';
all_from 'lib/Hoppy.pm';

requires 'EV';
requires 'POE';
requires 'POE::Sugar::Args';
requires 'POE::Filter::Line';
requires 'POE::Component::Server::TCP';
requires 'UNIVERSAL::require';
requires 'Carp';
requires 'Class::Accessor::Fast';
requires 'Class::Data::ConfigHash';
requires 'JSON';
requires 'Encode';
requires 'Encode::Guess';
requires 'Data::GUID';

build_requires 'Test::More';
build_requires 'FindBin::libs';
build_requires 'IO::Socket';

use_test_base;
auto_include;
WriteAll;
