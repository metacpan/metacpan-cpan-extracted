use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'Lingua::PT::PLN',
    'VERSION_FROM' => 'lib/Lingua/PT/PLN.pm',
    'ABSTRACT_FROM' => 'lib/Lingua/PT/PLN.pm',
    'PREREQ_PM'	   => {
		       'Lingua::PT::PLNbase' => '0.17',
               'Text::RewriteRules' => '0.23',
		      },
    'EXE_FILES'    => ['bin/pt-tokenizer','bin/occurrences'],
);
