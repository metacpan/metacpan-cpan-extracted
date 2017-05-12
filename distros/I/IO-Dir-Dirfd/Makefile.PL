# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42)
# <tobez@catpipe.net> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Anton Berezin
# ----------------------------------------------------------------------------
#
# $Id: Makefile.PL,v 1.1.1.1 2001/11/21 17:30:15 tobez Exp $
#
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'IO::Dir::Dirfd',
    'VERSION_FROM' => 'Dirfd.pm', # finds $VERSION
);
