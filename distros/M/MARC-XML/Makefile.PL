use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'MARC-XML',
    'DISTNAME'      => 'MARC-XML',
    'VERSION_FROM'  => 'lib/MARC/File/XML.pm',
    'PMLIBDIRS'     => [ qw( lib/ ) ],
    'AUTHOR'        => [
                            'Ed Summers <ehs@pobox.com>',
                            'Galen Charlton <gmcharlt@gmail.com>',
                       ],
    'LICENSE'       => 'perl',
    'PREREQ_PM'     => {
                            'XML::LibXML'   => 1.66,
                            'MARC::Record'  => 2.0,
                            'MARC::Charset' => 0.98,
                       },
    'EXE_FILES'         => [ qw( bin/marc2xml bin/xml2marc ) ]
);
