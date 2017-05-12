use strict;
use warnings;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'Fierce::Parser',
    AUTHOR              => 'Joshua D. Abraham < jabra@spl0it.org >',
    VERSION_FROM        => 'lib/Fierce/Parser.pm',
    ABSTRACT_FROM       => 'lib/Fierce/Parser.pod',
    PREREQ_PM           => {
                'Sub::Uplevel'       => '0.18',
                'XML::NamespaceSupport' => '1.07',
                'XML::SAX' => '0.11',
                'Test::More'        => '0',
                'Test::Class'        => '0',
                'Object::InsideOut' => '0',
                'XML::LibXML'	    => '0',
    },
    'INSTALLDIRS' => 'site',    
    'dist' => {
        'SUFFIX'       => ".gz",
        'DIST_DEFAULT' => 'all tardist',
        'COMPRESS'     => "gzip -9f"
    },
    'realclean' => { 'FILES' => '' },
    'clean'     => { 'FILES' => '' },

);

