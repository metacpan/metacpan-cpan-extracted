use inc::Module::Install;

name 'Email-Archive';
all_from 'lib/Email/Archive.pm';

requires 'Moo';
requires 'Carp';
requires 'DBI';
requires 'DBD::SQLite';
requires 'File::ShareDir';
requires 'File::Slurp';
requires 'Email::MIME';
requires 'Email::Abstract';
requires 'SQL::Abstract';
requires 'autodie';

auto_install;

WriteAll;
