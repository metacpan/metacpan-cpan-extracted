use 5.008_000;
use Config;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Math::Random::MTwist',
  AUTHOR        => 'Carsten Gaebler',
  ABSTRACT_FROM => 'lib/Math/Random/MTwist.pm',
  VERSION_FROM  => 'lib/Math/Random/MTwist.pm',
  MIN_PERL_VERSION => '5.008000',
  PREREQ_PM     => { 'Time::HiRes' => 0 },
  TEST_REQUIRES => { 'Test::More' => 0 },
  INC           => '-I.',
  OBJECT        => '$(O_FILES)',
  dist          => { TARFLAGS => '--numeric-owner -cvpf' },
);

open my $TMAP, '>', 'typemap';

print $TMAP q[
uint32_t   T_UV
mt_state*  O_OBJECT

OUTPUT
O_OBJECT
  sv_setref_pv($arg, CLASS, (void*)$var);

INPUT
O_OBJECT
  if ( !sv_isobject($arg) || (SvTYPE(SvRV($arg)) != SVt_PVMG) ) {
    warn(\"${Package}::$func_name() -- $var is not a blessed SV reference\");
    XSRETURN_UNDEF;
  }
];

my $to_u32 = $Config{ptrsize} == 4 ? '(uint32_t)' : '';
print $TMAP '  $var = ($type)'.$to_u32.'SvUV((SV*)SvRV($arg));'."\n";
print $TMAP '  *$var = *$var; /* tell the compiler that $var is not NULL */'."\n";
