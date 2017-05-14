#
# Copyright (C) 1998 Ken MacLeod
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Makefile.PL,v 1.2 1999/04/13 19:43:46 kmacleod Exp $
#

$VERSION = '0.07b4';

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Frontier::RPC',
    'VERSION_FROM' => 'Makefile.PL',
    'PREREQ_PM' => { XML::Parser => '2.19' },
    'dist'     => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
);
