#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;
# Run "perldoc ExtUtils::MakeMaker" for more information.

my $mod = 'lib/IPC/Semaphore/SmokeSignals.pm';
my $v = $ExtUtils::MakeMaker::VERSION;
WriteMakefile(
    'NAME'              => 'IPC::Semaphore::SmokeSignals',
    'VERSION_FROM'      => $mod,
    'PREREQ_PM'         => {
        'strict' => 0,                  # in 'core'
        'vars' => 0,                    # in 'core'
        'IO::Handle' => 0,              # in 'core'
        'Exporter' => 0,                # in 'core'
        'bytes' => 0,                   # in 'core'
        'Errno' => 0,                   # in 'core'
        'Fcntl' => 0,                   # in 'core'
        'Time::HiRes' => 0,             # in 'core'
        # Testing only:
        'File::Basename' => 0,          # in 'core'
        'lib' => 0,                     # in 'core'
        # Only used when needed:
        'POSIX' => 0,                   # in 'core'
        'Carp' => 0,                    # in 'core'
    },
    $] < 5.005  ?  ()  :  (
        'AUTHOR'        => 'Tye McQueen',
        'ABSTRACT_FROM' => $mod,
    ),
    $v < 6.31  ?  ()  :  (
        LICENSE => 'unrestricted' ),
);
