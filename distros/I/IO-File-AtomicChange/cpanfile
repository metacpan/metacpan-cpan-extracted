# -*- mode: cperl -*-

requires 'Time::HiRes';
requires 'IO::File';
requires 'File::Temp';
requires 'File::Copy';
requires 'File::Sync';
requires 'Path::Class';
requires 'POSIX';

on develop => sub {
    requires 'Module::Install';
    requires 'Module::Install::CPANfile';
};

on 'test' => sub {
    requires 'Test::More';
    requires 'Devel::Cover';
    requires 'FindBin';
};
