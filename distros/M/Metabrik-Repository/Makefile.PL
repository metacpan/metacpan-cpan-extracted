#
# $Id: Makefile.PL,v ecface00b50a 2016/01/02 17:50:23 gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Metabrik::Repository',
   VERSION_FROM => 'lib/Metabrik/Repository.pm',
   LICENSE => 'bsd',
   ABSTRACT_FROM => 'lib/Metabrik/Repository.pm',
   AUTHOR => 'GomoR <gomor_at_metabrik.org>',
   PREREQ_PM => {
      'Metabrik' => '1.20',
      'Cwd' => 0,
      'IPC::Run3' => 0,
      'File::Copy' => 0,
      'File::Path' => 0,
      'File::Spec' => 0,
      'POSIX' => 0,
   },
   MIN_PERL_VERSION => '5.6.1',
);
