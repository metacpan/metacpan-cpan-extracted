#
# Copyright (C) 2008 DMA.
#

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Document',
    'DISTNAME'  => 'Document',
    'ABSTRACT'  => 'Support for archival document files and directories.',
    'AUTHOR'    => 'Dale Amon',
    'VERSION_FROM' => 'Version',
    'PREREQ_PM' => {'Exporter' => 0, 'POSIX' => 0, 'Fault::Logger' => 0, 'DMA::FSM' => 0  },
    'dist'      => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
    'clean'     => {FILES => "*/*/*~ *~ .#* */*/.#*"},
);
