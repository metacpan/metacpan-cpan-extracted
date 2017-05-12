#!/usr/bin/perl
# $Id: Makefile.PL,v 1.2 2005/10/16 17:47:42 jodrell Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Gtk2::Ex::MPlayerEmbed',
    'VERSION_FROM'	=> 'lib/Gtk2/Ex/MPlayerEmbed.pm',
    'PREREQ_FATAL'	=> 1,
    'PREREQ_PM'		=> {
        Gtk2		=> 0,
        Carp		=> 0,
        FileHandle	=> 0,
    },
);

chomp(my $mplayer = `which mplayer 2>/dev/null`);

if (!-x $mplayer) {
	print "NB: This module will work better if it can find the 'mplayer' program!\n";
}
