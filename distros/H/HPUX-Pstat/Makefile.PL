# $Id: Makefile.PL,v 1.1 2003/03/31 17:42:16 deschwen Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'AUTHOR'       => 'Axel Schwenke <axel.schwenke@gmx.net>',
    'NAME'	   => 'HPUX::Pstat',
    'VERSION_FROM' => 'Pstat.pm',
    'OBJECT'       => 'Pstat$(OBJ_EXT) pack$(OBJ_EXT)',
    'XSPROTOARG'   => '-noprototypes',
);

