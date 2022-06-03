use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'HTML::Obj2HTML',
  VERSION_FROM     => 'lib/HTML/Obj2HTML.pm',
  ABSTRACT_FROM    => 'lib/HTML/Obj2HTML.pm',
  AUTHOR           => 'Pero Moretti',
  LICENSE          => 'freebsd',
  MIN_PERL_VERSION => '5.008004',
  EXE_FILES        => [],
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'Carp' => 0,
    'HTML::Entities' => 0,
    'Text::Markdown' => 0,
    'Text::Pluralize' => 0,
    'Locale::Currency::Format' => 0,
    'List::MoreUtils' => 0,
    'Module::Pluggable' => 0
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/Pero-Moretti/Perl-Obj2HTML.git',
              web  => 'https://github.com/Pero-Moretti/Perl-Obj2HTML',
          },
      }})
   : ()
  ),
);
