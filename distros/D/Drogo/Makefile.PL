use strict;
use warnings;
use inc::Module::Install;

perl_version '5.008004';

name 'Drogo';
all_from 'lib/Drogo.pm';
license 'perl';

requires 'XML::Simple';
requires 'CGI::Cookie';
requires 'Time::HiRes';
requires 'YAML';
requires 'File::Path';
requires 'URI';
requires 'Cwd';
requires 'File::Find';
requires 'IO::File';

install_script glob('bin/drogo');

WriteAll();
