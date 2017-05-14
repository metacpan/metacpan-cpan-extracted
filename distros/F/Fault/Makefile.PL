#
# Copyright (C) 2008 DMA.
#

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Fault',
    'DISTNAME'  => 'Fault',
    'ABSTRACT'  => 'Useful perl modules including sophisticated diagnostic, fault and log handling and printing classes',
    'AUTHOR'    => 'Dale Amon',
    'VERSION_FROM' => 'Version',
    'PREREQ_PM' => {'Exporter' => 0, 'POSIX' => 0, 'DBI' => 0, 'Net::HTTP' => 0 },
    'dist'      => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
    'clean'     => {FILES => "*/*/*~ *~ .#* */*/.#*"},
);
