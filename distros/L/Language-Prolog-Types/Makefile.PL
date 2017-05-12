use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile( 'NAME' => 'Language::Prolog::Types',
	       'VERSION_FROM' => 'lib/Language/Prolog/Types.pm',
	       'PREREQ_PM' => { Test::More => 0 },
	       'ABSTRACT_FROM' => 'lib/Language/Prolog/Types.pm',
	       'AUTHOR' => 'Salvador Fandiño <sfandino@yahoo.com>' );
