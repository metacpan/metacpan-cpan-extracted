#!/usr/bin/env perl
use inc::Module::Install;

name 'ETL-Pipeline';
license 'perl';
all_from 'lib/ETL/Pipeline.pm';
repository 'https://github.com/rbwohlfarth/ETL-Pipeline';

requires 'Carp';
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
requires 'XML::XPath';

test_requires 'Test::More' => '0.88';
test_requires 'Test::Pod'  => '1.44';

auto_manifest;
auto_install;

WriteAll;
