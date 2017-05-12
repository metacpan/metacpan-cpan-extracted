use 5.006;
use Inline::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Language::XSB::Base',
    'VERSION_FROM'	=> 'Base.pm',
    'PREREQ_PM'		=> { 'Inline::C' => 0,
			     'Language::Prolog::Types' => 0, },
    'ABSTRACT_FROM'     => 'Base.pm',
    'AUTHOR'            => 'Salvador Fandiño <sfandino@yahoo.com>',
);
