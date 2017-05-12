use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => "E::Mail::Acme",
    AUTHOR              => 'Ricardo SIGNES <rjbs@cpan.org >',
    VERSION_FROM        => 'lib/E/Mail/Acme.pm',
    (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'E-Mail-Acme-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) }
     ? (META_MERGE => {
         resources => {
           repository => 'http://github.com/rjbs/E-Mail-Acme',
           bugtracker => 'http://github.com/rjbs/E-Mail-Acme/issues',
         }
       })
     : ()
    ),
);
