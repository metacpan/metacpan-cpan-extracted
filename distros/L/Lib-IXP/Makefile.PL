#
# $Id: Makefile.PL 21 2015-01-20 18:26:46Z gomor $
#
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Lib::IXP',
   VERSION_FROM => 'lib/Lib/IXP.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Lib/IXP.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   LIBS => ['-L/lib -L/usr/lib -L/usr/local/lib -lixp'],
   INC => '-I/include -I/usr/include -I/usr/local/include',
   MIN_PERL_VERSION => '5.6.1',
);
