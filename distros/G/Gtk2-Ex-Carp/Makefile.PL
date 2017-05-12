#!/usr/bin/perl
# $Id: Makefile.PL,v 1.1 2005/09/21 15:20:49 jodrell Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Gtk2::Ex::Carp',
    'VERSION_FROM'	=> 'Carp.pm',
);
