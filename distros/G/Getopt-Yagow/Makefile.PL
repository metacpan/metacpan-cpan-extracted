
# MakeMaker for Getopt::Yagow module.
#
# Author: Enrique Castilla Contreras <ecastillacontreras@yahoo.es>. Jan-2003.
#
# $Id: Makefile.PL,v 1.4 2004/02/10 13:09:45 ecastilla Exp $

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
(
    'NAME' => 'Getopt::Yagow',
    'VERSION_FROM' => 'Yagow.pm', # finds $VERSION

    ($] >= 5.005 ?    ## new keywords supported since 5.005
      (ABSTRACT_FROM => 'Yagow.pm', # retrieve abstract from module
       AUTHOR     => 'Enrique Castilla <ecastillacontreras@yahoo.es>') : ()),

    'PM' => {
               'Yagow.pm' => '$(INST_LIBDIR)/Yagow.pm'
            },

    # Que ficheos hay que borrar ademas de los de por defecto, cuando se ejecuta
    # el target 'make clean' o 'make realclean'.
    clean => { FILES => 'options.out pod2htmd.x~~ pod2htmi.x~~ #*#' },
    realclean => { FILES => 'options.out pod2htmd.x~~ pod2htmi.x~~ .exists #*# *.tar.gz *.ppd' },

); 

