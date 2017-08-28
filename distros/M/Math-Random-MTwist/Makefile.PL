use 5.008_000;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Math::Random::MTwist',
  AUTHOR        => 'Carsten Gaebler',
  ABSTRACT_FROM => 'lib/Math/Random/MTwist.pod',
  VERSION_FROM  => 'lib/Math/Random/MTwist.pm',
  MIN_PERL_VERSION => '5.008000',
  PREREQ_PM     => { 'Time::HiRes' => 0 },
  TEST_REQUIRES => { 'Test::More' => 0 },
  LIBS          => ['-lm -lrt'],
  INC           => '-I.',
  OBJECT        => '$(O_FILES)',
  dist          => { TARFLAGS => '--numeric-owner -cvpf' },
);

unlink 'typemap';
open my $TMAP, '>', 'typemap';
print $TMAP q[
uint32_t   T_UV
mt_state*  O_OBJECT

OUTPUT
O_OBJECT
  sv_setref_pv($arg, CLASS, (void*)$var);

INPUT
O_OBJECT
  SV* sv = $arg;
  if (sv_isobject(sv)) {
    $var = INT2PTR( $type, SvUV((SV*)SvRV(sv)) );
    *$var = *$var; /* tell the compiler that $var is not NULL */
  }
  else
    $var = NULL;
];
