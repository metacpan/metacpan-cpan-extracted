#
# $Id: Makefile.PL 4 2012-11-01 17:05:56Z gomor $
#
use ExtUtils::MakeMaker;

my $libs = ['-L/lib -L/usr/lib -L/usr/local/lib -lfurll'];

my $inc = '-I/include -I/usr/include -I/usr/local/include';

WriteMakefile(
   NAME             => 'Lib::Furl',
   VERSION_FROM     => 'lib/Lib/Furl.pm',
   LICENSE          => 'bsd',
   ABSTRACT_FROM    => 'lib/Lib/Furl.pm',
   AUTHOR           => 'GomoR <gomor-cpan_at_gomor.org>',
   LIBS             => $libs,
   INC              => $inc,
   DEFINE           => '',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM     => {
      Class::Gomor => 0,
   },
);
