#!/usr/bin/perl
# $Id: Makefile.PL,v 1.5 2005/10/05 14:23:53 jodrell Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Gtk2::Ex::PrintDialog',
    'VERSION_FROM'	=> 'lib/Gtk2/Ex/PrintDialog.pm',
    'PREREQ_FATAL'	=> 1,
    'PREREQ_PM'		=> {
        File::Basename	=> 0,
        File::Spec	=> 0,
        File::Temp	=> 0,
        Gtk2		=> 0,
        Locale::gettext	=> 0,
    },
);

if ($^O eq 'MSWin32') {
	my $LIBS = 0;
	eval {
		require Win32::Printer;
		require Printer;
		$LIBS = 1;
	};
	print STDERR "For best results on Windows, make sure Win32::Printer and Printer are installed!\n" unless ($LIBS == 1);

} else {
	my $CUPS = 0;
	eval {
		require Net::CUPS;
		$CUPS = 1;
	};
	print STDERR "For best results on Unix, make sure Net::CUPS is installed!\n" unless ($CUPS == 1);

}
