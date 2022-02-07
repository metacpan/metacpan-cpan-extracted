#!/usr/bin/env perl

use inc::Module::Install;

# Generate the "Makefile"...
name 'ETL-Pipeline';
license 'perl';
all_from 'lib/ETL/Pipeline.pm';
repository 'https://github.com/rbwohlfarth/ETL-Pipeline';

requires 'Carp';
requires 'Data::DPath';
requires 'Data::Traverse';
requires 'JSON';
requires 'List::AllUtils';
requires 'Moose';
requires 'Moose::Role';
requires 'MooseX::Types::Path::Class';
requires 'Path::Class';
requires 'Path::Class::Rule';
requires 'Regexp::Common';
requires 'Spreadsheet::ParseExcel';
requires 'Spreadsheet::ParseExcel::Utility';
requires 'Spreadsheet::XLSX';
requires 'String::Util';
requires 'Text::CSV';
requires 'XML::Bare';

test_requires 'Test::More' => '0.88';
test_requires 'Test::Pod'  => '1.44';
test_requires 'Try::Tiny';

auto_manifest;
auto_install;

WriteAll;

# Warning when upgrading older versions.
if (eval 'require ETL::Pipeline' && ETL::Pipeline->VERSION < 3) {
	warn <<WARN;
You have an older version of this module. You will need to rewrite any custom
input sources. Version 3.00 introduced an updated input source API that is not
compatible with older versions. If you only used the standard input sources that
came with ETL::Pipeline, you'll be fine. If you wrote your own input sources,
then you need to rewrite them to be compatible. See
"perldoc ETL::Pipeline::Input".
WARN
}
