use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Lingua::EN::Numericalize',
	VERSION_FROM  => "Numericalize.pm",
    $] < 5.005 ? () : (
        AUTHOR => 'Erick Calder <ecalder@cpan.org>',
        ABSTRACT_FROM => 'Numericalize.pm',
        ),
    );
