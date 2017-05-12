use strict;
use inc::Module::Install;

# Because many filesystem modules are buggier
# on Windows, we're going to push for more aggressive
# dependencies to get the most current bug fixes.
my $WIN32 = ($^O eq 'MSWin32' or $^O eq 'cygwin');

name           'File-Flat';
all_from       'lib/File/Flat.pm';
requires       'Cwd'                   => 0;
requires       'prefork'               => '0.02';
requires       'File::Spec'            => ($WIN32 ? '3.24' : '0.85');    
requires       'File::Copy'            => 0;
requires       'File::Copy::Recursive' => '0.35';
requires       'File::Remove'          => '0.38';
requires       'File::Temp'            => '0.17';   
requires       'IO::File'              => 0;
build_requires 'Test::More'            => '0.47';
build_requires 'Test::ClassAPI'        => '1.04';

# Avoid use of system chmod -R in test script
build_requires 'File::Find'            => 0;

WriteAll;
