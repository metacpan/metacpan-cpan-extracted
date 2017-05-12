####################################################################
## The little hampster grew humps, and wrote this....             ##
## Copyright (c) 2002 Theo Zourzouvillys <theo@crazygreek.co.uk>  ##
## Includes code from netfilter (netfilter.samba.org)             ##
####################################################################
#
#       .Copyright (C)  2000-2001 Theo Zourzouvillys
#       .Created:       26/09/2001
#       .Contactid:     <theo@crazygreek.co.uk>
#       .Url:           http://www.crazygreek.co.uk/perl/
#       .Authors:       Theo Zourzouvillys
#       .ID:            $Id: Makefile.PL,v 1.8 2002/04/05 19:57:40 theo Exp $

use ExtUtils::MakeMaker;
use strict;

print qq|\n -=*> WARNING!\n|;
print qq| -=*> THIS IS ALPHA QUALITY SOFTWARE, IT MAY WELL EAT YOUR COMPUTER\n|;

WriteMakefile (
	'NAME'          => 'IPTables',
	'VERSION_FROM'  => 'IPTables.pm',
	'PREREQ_PM'     => {},
	'LIBS'          => [''],
	'DEFINE'        => qq||,
	'INC'           => "",
	'OBJECT'        => '$(O_FILES) ' . "/usr/lib/libiptc.a",
);
