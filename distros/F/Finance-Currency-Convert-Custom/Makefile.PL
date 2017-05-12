
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Finance::Currency::Convert::Custom',
    VERSION_FROM      => 'lib/Finance/Currency/Convert/Custom.pm',
    PREREQ_PM         => {'Finance::Currency::Convert' => 0,
                          'LWP::UserAgent' => 0},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Finance/Currency/Convert/Custom.pm',
       AUTHOR         => 'Dmitry Nikolayev <dmitry@cpan.org>') : ()),
);
