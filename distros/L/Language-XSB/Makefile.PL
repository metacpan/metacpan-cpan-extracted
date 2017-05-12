use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Language::XSB',
    'VERSION_FROM'	=> 'XSB.pm',
    'PREREQ_PM'		=> { 'Inline::C' => 0,
			     'Language::Prolog::Types' => 0,
			     'Test::More' => 0 },
    'ABSTRACT_FROM'     => 'XSB.pm',
    'AUTHOR'            => 'Salvador Fandiño <sfandino@yahoo.com>',
    'DIR'               => [qw(Config Base Register xsblib)],
);
