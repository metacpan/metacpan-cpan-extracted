use strict;
use inc::Module::Install;

name('Filter-SQL');
all_from('lib/Filter/SQL.pm');

requires 'Carp';
requires 'DBI';
requires 'Filter::Simple'  => 0.82;
requires 'List::MoreUtils' => 0.21;
requires 'Text::Balanced'  => '2.0.0';

auto_install;
WriteAll;
