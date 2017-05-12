use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Language::Prolog::Yaswi',
    'VERSION_FROM'	=> 'Yaswi.pm',
    'PREREQ_PM'		=> { Language::Prolog::Types => '0.09',
			     Language::Prolog::Sugar => '0.03',
			     Test::More => 0, },
    'OPTIMIZE'          => '-g -O0',
    'ABSTRACT_FROM'     => 'Yaswi.pm',
    'AUTHOR'            => 'Salvador Fandiño <sfandino@yahoo.com>',
);
