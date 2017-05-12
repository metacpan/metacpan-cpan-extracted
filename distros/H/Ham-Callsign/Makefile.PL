# Copyright (C) 2008 Wes Hardaker
# License: GNU GPLv2.  See the COPYING file for details.
#!/usr/bin/perl

use ExtUtils::MakeMaker;

%opts = (
	 'NAME'		=> 'Ham::Callsign',
	 'PREREQ_PM'    => { DBI => 0 },
	 'EXE_FILES'    => [qw(cs)],
         'PMLIBDIRS'    => [qw(lib)],
         'VERSION_FROM' => 'lib/Ham/Callsign/DB.pm', # finds $VERSION
	);

if (!($^O eq 'MSWin32' || $Config{'ccflags'} =~ /-D_?WIN32_?/)) {
    # doesn't work on windows: no sed
    $opts{'PM_FILTER'} = 'sed -e "s|/usr/share|$(PREFIX)/share|"';
}

WriteMakefile(%opts);
