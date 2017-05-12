use strict;
use warnings;
use inc::Module::Install;

perl_version '5.008004';

name 'IPTables-Mangle';
all_from 'lib/IPTables/Mangle.pm';
license 'perl';

requires 'IPC::Open3';
requires 'YAML';

install_script glob('bin/ipmangle');

WriteAll();
