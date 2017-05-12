use strict;
use inc::Module::Install;

name('File-Extract');
all_from('lib/File/Extract.pm');

requires('Class::Data::Inheritable');
requires('CAM::PDF');
requires('Encode');
requires('File::MMagic::XS');
requires('HTML::TreeBuilder');
requires('IO::Scalar');
requires('IPC::Open2');
requires('MP3::Info');
requires('RTF::HTMLConverter');
requires('Spreadsheet::ParseExcel');
requires('UNIVERSAL::isa');

auto_install;
WriteAll;
