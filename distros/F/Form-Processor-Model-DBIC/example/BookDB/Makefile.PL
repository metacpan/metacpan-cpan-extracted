use inc::Module::Install;

name 'BookDB';
all_from 'lib/BookDB.pm';

requires 'Catalyst::Runtime' => '5.7010';
requires 'Catalyst::View::TT';
requires 'DBIx::Class';
requires 'Form::Processor';
requires 'Form::Processor::Model::DBIC';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::Form::Processor';
requires 'Catalyst::Plugin::FillInForm';
requires 'YAML'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
