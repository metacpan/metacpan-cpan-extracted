use strict;
use warnings;
use ExtUtils::MakeMaker;

our $LIBS;
our $DEFS;

my $skip_msvc  = 0;     # Will be reset to 1 for MS compiler builds of perl
$skip_msvc = 1 if ($Config::Config{'make'} eq 'nmake' && $Config::Config{'cc'} eq 'cl');

if(!$skip_msvc && $^O =~ /MSWin/i) {
  # Don't go in here if $skip_msvc is TRUE or OS is not MS Windows.
  # In https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/226
  # it is mentioned that the mpfr documentation stipulates the GMP library
  # should be built with CC="gcc -D__USE_MINGW_ANSI_STDIO" as one of the
  # arguments passed to configure.
  # We check here that such an argument was provided.
  # If that arg was not provided, then it's possible that mpfr will not
  # provide correct "%a" and "%A" formatting, so we provide a
  # workaround that protects against that bug.

  my($mycc, $mkinc) = ('', '') ;

  if(@ARGV) {
    for my $arg(@ARGV) {
      $mycc   = (split /=/, $arg)[1] if $arg =~ /^cc=/i;
      $mkinc  = (split /=/, $arg)[1] if $arg =~ /^inc=/i;
    }
  }

  $mycc = $Config{cc} unless($mycc);

  my $out = `$mycc -o checkinc.exe -x c checkinc.in $mkinc 2>&1`;

  if(-e 'checkinc.exe') {
    $out =  `checkinc.exe`;
    if($out !~ /\-D__USE_MINGW_ANSI_STDIO/) {
      $DEFS .= " -DWIN32_FMT_BUG";
    }
  }
  else {
    warn "Random/Makefile.PL: checkinc.exe not created";
    die "\$out: $out\n";
  }
}

my %options = %{
  {
  'TYPEMAPS' => [],
  'NAME'     => 'Math::MPFR::Random',
  'LIBS'     => $LIBS,
  'INC'      => $INC,
  'DEFINE'   => $DEFS,
  'VERSION_FROM' => 'Random.pm',
  'clean'        => { FILES => '*.exe' },
  }
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
# sub MY::makefile { '' }
