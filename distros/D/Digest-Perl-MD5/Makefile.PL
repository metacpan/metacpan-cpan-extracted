# $Id$
#

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'         => 'Digest::Perl::MD5',
    'VERSION_FROM' => './lib/Digest/Perl/MD5.pm', # finds $VERSION
    'AUTHOR'       => 'Christian Lackas <delta@lackas.net>',
    'ABSTRACT'     => 'Perl Implementation of Rivest\'s MD5 algorithm',
    'PREREQ_PM'    => {
                         'Exporter' => 0
                      },
    'dist'         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', }
);
