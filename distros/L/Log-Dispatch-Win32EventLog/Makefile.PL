# Makefile.PL for Log::Dispatch::Win32EventLog
#
# Copyright (C) 2007 David Landgren

use ExtUtils::MakeMaker;
use strict;

eval "use ExtUtils::MakeMaker::Coverage";
if( $@ ) {
    print "Skipping testcover target, ExtUtils::MakeMaker::Coverage not found\n";
}
else {
    print "Adding testcover target\n";
}

my @license =
    do {
        my $version = $ExtUtils::MakeMaker::VERSION;
        $version =~ tr/_//d;
        $version} > 6.30
    ? qw(LICENSE perl)
    : ();

WriteMakefile(
    NAME          => 'Log::Dispatch::Win32EventLog',
    AUTHOR        => 'David Landgren',
    ABSTRACT_FROM => 'lib/Log/Dispatch/Win32EventLog.pm',
    VERSION_FROM  => 'lib/Log/Dispatch/Win32EventLog.pm',
    @license,
    PREREQ_PM     => {
	'Log::Dispatch'    => '2.01',
	'Params::Validate' => 0,
	'Test::Warn'       => 0,
	'Win32'            => 0,
	'Win32::EventLog'  => 0,
    },
);