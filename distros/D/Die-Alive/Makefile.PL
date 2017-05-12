###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Die::Alive' ,
    'VERSION_FROM'  => 'lib/Die/Alive.pm' ,
    #'PREREQ_PM'     => {'Foo'  => 0.01} ,
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/Die/Alive.pm',
        AUTHOR        => 'Graciliano M. P. <gm@virtuasites.com.br>'
       ) : ()
     ),
);

1;

