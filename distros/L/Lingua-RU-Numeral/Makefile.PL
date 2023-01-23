use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Lingua::RU::Numeral',
    VERSION_FROM      => 'lib/Lingua/RU/Numeral.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    MIN_PERL_VERSION  => '5.010000',
    ABSTRACT_FROM     => 'lib/Lingua/RU/Numeral.pm', # retrieve abstract from module
    AUTHOR            => 'Alessandro Gorohovski <an.gorohovski@gmail.com>',
    LICENSE           => 'perl', #Value must be from legacy list of licenses here http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    PREREQ_PM         => {
		'Test::More'       => '0.98',
		'Test::More::UTF8' => '0.05',
		'Test::Pod'        => '1.52',
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lingua/RU/Numeral.pm',
       AUTHOR         => 'Alessandro Gorohovski <an.gorohovski@gmail.com>') : ()),
);
