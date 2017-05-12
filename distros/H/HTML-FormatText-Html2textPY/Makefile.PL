use ExtUtils::MakeMaker;

WriteMakefile(
  NAME      => 'HTML::FormatText::Html2textPY',
  AUTHOR    => 'Alex Pavlovic (alex.pavlovic@taskforce-1.com)',
  PREREQ_PM => {
    'HTML::FormatExternal' => 0,
    'MRO::Compat'          => 0,
    'mro'                  => 0
  },
  VERSION_FROM => 'lib/HTML/FormatText/Html2textPY.pm'
);

