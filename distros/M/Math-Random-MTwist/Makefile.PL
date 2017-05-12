use 5.010_000;  # see README
use Config;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Math::Random::MTwist',
  AUTHOR        => 'Carsten Gaebler',
  ABSTRACT_FROM => 'lib/Math/Random/MTwist.pm',
  VERSION_FROM  => 'lib/Math/Random/MTwist.pm',
  MIN_PERL_VERSION => '5.010000',
  PREREQ_PM     => { 'Time::HiRes' => 0 },
  TEST_REQUIRES => { 'Test::More' => 0 },
  INC           => '-I.',
  OBJECT        => '$(O_FILES)',
  dist          => { TARFLAGS => '--numeric-owner -cvpf' },
);

my $uint64_type = $Config{ivsize} >= 8 ? 'T_UV' : 'T_NV';
open my $TMAP, '>', 'typemap';
print $TMAP <<EOTM;
mt_state*  O_OBJECT
uint32_t   T_UV
uint64_t   $uint64_type
EOTM

print $TMAP q[
OUTPUT
O_OBJECT
  sv_setref_pv($arg, CLASS, (void*)$var);

INPUT
O_OBJECT
  if ( !sv_isobject($arg) || (SvTYPE(SvRV($arg)) != SVt_PVMG) ) {
    warn(\"${Package}::$func_name() -- $var is not a blessed SV reference\");
    XSRETURN_UNDEF;
  }
  $var = ($type)SvIV((SV*)SvRV($arg));
  *$var = *$var; /* tell the compiler that $var is not NULL */
];
