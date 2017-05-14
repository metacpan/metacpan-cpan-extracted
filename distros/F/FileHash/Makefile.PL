#
# Copyright (C) 2008 DMA.
#

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'FileHash',
    'DISTNAME'  => 'FileHash',
    'ABSTRACT'  => 'Perl classes for generating and saving hashes of file metadata by name and by md5sum.',
    'AUTHOR'    => 'Dale Amon',
    'VERSION_FROM' => 'Version',
    'PREREQ_PM' => {'Exporter' => 0, 'Fault::Logger' => 0 , 'Cwd' => 0, 'Digest::MD5' => 0, 'File::Spec' => 0 },
    'dist'      => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
    'clean'     => {FILES => "*/*/*~ *~ .#* */*/.#*"},
);
