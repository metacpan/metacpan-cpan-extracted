# -*- Makefile -*-

#  Copyright 2005 Laurent Wacrenier
#
#  This file is part of Maildir-Quota
#
#  Maildir-Quota is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as
#  published by the Free Software Foundation; either version 2 of the
#  License, or (at your option) any later version.
#
#  Maildir-Quota is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with Maildir-Quota; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
#  USA

# $Id: Makefile.PL,v 1.4 2005/02/01 16:57:15 lwa Exp $


use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::postamble {
    return <<\END;
libmdq/mdq.h:
	cd libmdq && ./configure
libmdq/Makefile:
	cd libmdq && ./configure
libmdq/libmdq.a: libmdq/Makefile
	cd libmdq && ${MAKE}
clean::
	-test -f libmdq/Makefile && cd libmdq && ${MAKE} distclean
publish::
	./publish ${DISTVNAME}.tar${SUFFIX}
END
}

WriteMakefile(
    'NAME'	=> 'Maildir::Quota',
    'VERSION_FROM' => 'Quota.pm',
    'MYEXTLIB'  => 'libmdq/libmdq$(LIB_EXT)',
    'DEFINE'	=> '', 
    'INC'	=> '-Ilibmdq', 

    depend      => { "Quota.c" => "libmdq/mdq.h libmdq/mdq.c",
	             "Quota.xs" => "libmdq/libmdq.a"}

);

