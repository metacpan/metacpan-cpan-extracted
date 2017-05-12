use inc::Module::Install;
name 'Finance-Instrument';
all_from 'lib/Finance/Instrument.pm';
readme_from 'lib/Finance/Instrument.pm';
build_requires 'Test::More' => 0.88;
extra_tests;
auto_set_repository;
install_share 'share';

requires 'methods';
requires 'Moose';
requires 'DateTime';
requires 'DateTime::Format::Strptime';
requires 'File::ShareDir';
requires 'List::MoreUtils';
requires 'Text::CSV';
requires 'YAML::Syck';
requires 'MooseX::ClassAttribute';


WriteAll;
