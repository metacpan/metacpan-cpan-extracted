###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'HDB' ,
    'VERSION_FROM'  => 'lib/HDB.pm' ,
    'PREREQ_PM'     => {'DBI' => 1.13} ,
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/HDB.pm',
        AUTHOR        => 'Graciliano M. P. <gm@virtuasites.com.br>'
       ) : ()
     ),
);

1;

