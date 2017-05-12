###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Hash::NoRef' ,
    'VERSION_FROM'  => 'lib/Hash/NoRef.pm' ,
    #'PREREQ_PM'     => {'Foo'  => 0.01} ,
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/Hash/NoRef.pm',
        AUTHOR        => 'Graciliano M. P. <gm@virtuasites.com.br>'
       ) : ()
     ),
);

1;

