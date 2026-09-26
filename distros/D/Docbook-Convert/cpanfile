requires 'Carp';
requires 'Cwd';
requires 'Data::Dumper';
requires 'File::Basename';
requires 'HTML::Entities';
requires 'IPC::Run3';
requires 'File::Find';
requires 'File::Spec';
requires 'File::Temp';
requires 'FindBin';
requires 'Getopt::Long';
requires 'IO::File';
requires 'Pod::Usage';
requires 'Text::Table';
requires 'Text::Wrap';
requires 'XML::Twig', '3.40';
requires 'base';
requires 'perl', '5.010';
requires 'strict';
requires 'vars';
requires 'warnings';
suggests 'Image::Magick';
suggests 'LWP::UserAgent';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
    requires 'perl', '5.010';
    requires 'version';
    suggests 'ASPEER::MakeMaker::Markdown::Pod', '1.010';
};

on test => sub {
    requires 'Digest::MD5';
    requires 'File::Path';
    requires 'File::Temp';
    requires 'Test::More';
};
