#
# $Id$
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Metabrik',
   MIN_PERL_VERSION => '5.6.1',
   VERSION_FROM => 'lib/Metabrik.pm',
   LICENSE => 'bsd',
   ABSTRACT_FROM => 'lib/Metabrik.pm',
   AUTHOR => 'GomoR <gomor_at_metabrik.org>',
   PREREQ_PM => {
      'Class::Gomor' => 0,
      'Cwd' => 0,
      'Data::Dump' => 0,
      'File::Find' => 0,
      'File::HomeDir' => 0,
      'File::Path' => 0,
      'IO::All' => 0,
      'Lexical::Persistence' => 0,
      'Module::Reload' => 0,
      'PPI' => 0,
      'Term::ANSIColor' => 0,
      'Term::ReadLine::Gnu' => 0,
      'Term::Shell' => 0,
   },
);
