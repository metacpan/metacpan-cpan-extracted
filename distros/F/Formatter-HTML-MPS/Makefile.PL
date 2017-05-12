use ExtUtils::MakeMaker;

WriteMakefile( NAME            => 'Formatter::HTML::MPS',
               VERSION_FROM    => 'lib/Formatter/HTML/MPS.pm',
               EXE_FILES       => [ 'bin/mpslidemaker.pl' ],
               PREREQ_PM       => { 'Text::Markdown'	=> '1.0.3',
                                    'HTML::LinkExtor'   => '1.33',
                                }
               );
