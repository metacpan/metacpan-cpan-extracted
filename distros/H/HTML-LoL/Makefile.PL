use ExtUtils::MakeMaker;

&WriteMakefile(NAME          => 'HTML::LoL',
               VERSION_FROM  => 'lib/HTML/LoL.pm',
               ABSTRACT_FROM => 'lib/HTML/LoL.pm',
               PREREQ_PM     => {'HTML::Entities' => '1.18',
                                 'HTML::Tagset'   => '3.02'});
