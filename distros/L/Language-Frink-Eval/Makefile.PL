use ExtUtils::MakeMaker;

WriteMakefile(
              NAME => 'Language::Frink::Eval',
              VERSION_FROM => 'lib/Language/Frink/Eval.pm',
              AUTHOR => "Clayton O'Neill <coneill\@oneill.net>",
              PREREQ_PM => { 'Params::Validate' => '0.74' },
              PREREQ_PRINT => 1,
              );
