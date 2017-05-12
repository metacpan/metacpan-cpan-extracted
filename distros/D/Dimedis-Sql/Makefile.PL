# $Id: Makefile.PL,v 1.4 2002/04/26 10:26:01 joern Exp $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Dimedis::Sql',
    'VERSION_FROM' => 'lib/Dimedis/Sql.pm', # finds $VERSION
    'EXE_FILES' => [ 'bin/dsql_import', 'bin/dsql_export' ],
    'dist' => {
        COMPRESS => "gzip",
        SUFFIX => "gz",
        POSTOP   => "test -d dist || mkdir dist; mv *.tar.gz dist",
    }
);
