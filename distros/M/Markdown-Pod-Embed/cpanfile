requires 'Carp';
requires 'Config';
requires 'Data::Dumper';
requires 'Exporter';
requires 'File::Basename';
requires 'File::Copy';
requires 'File::Find';
requires 'File::Spec';
requires 'File::Temp';
requires 'Getopt::Long';
requires 'IPC::Run3';
requires 'Markdown::Pod', '0.008';
requires 'PPI';
requires 'perl', '5.010';
requires 'strict';
requires 'vars';
requires 'warnings';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
    requires 'perl', '5.010';
    requires 'version';
    suggests 'ASPEER::MakeMaker::Markdown::Pod', '1.010';
};

on test => sub {
    requires 'File::Path';
    requires 'File::Temp';
    requires 'Pod::Checker';
    requires 'Test::More';
};
