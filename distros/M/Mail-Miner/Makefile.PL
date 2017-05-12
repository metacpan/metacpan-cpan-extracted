use ExtUtils::MakeMaker;
use ExtUtils::AutoInstall (
    -core =>  [
        Class::DBI::mysql => 0,
        Class::DBI => 0.90,
        Lingua::EN::Keywords => 0,
        Date::PeriodParser => 0,
        MIME::Parser => 0,
    ],
    'spamassassin' => [
        Mail::SpamAssassin => 0
    ],
    'entities' => [
        Lingua::EN::NamedEntity => 0
    ]
);
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Mail::Miner',
    'VERSION_FROM'	=> 'Miner.pm', # finds $VERSION
   'EXE_FILES'     => ['mm', 'mm_process'],
    'PMLIBDIRS'    => [ 'Miner', 'Audit' ],
    'PREREQ_PM'		=> { Class::DBI::mysql => 0, 
                         Class::DBI => 0.90,
                         Lingua::EN::Keywords => 0,
                         Date::PeriodParser => 0,
                         Mail::Address => 0,
                         MIME::Parser => 0
                       },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Miner.pm', # retrieve abstract from module
       AUTHOR     => 'Simon Cozens <simon@cpan.org>') : ()),
);
