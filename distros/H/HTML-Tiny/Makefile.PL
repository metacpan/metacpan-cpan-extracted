use strict;
#use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';
warn "Optional ExtUtils::MakeMaker::Coverage not available\n" if $@;

WriteMakefile(
  ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
  license( 'perl' ),
  NAME          => 'HTML::Tiny',
  AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
  VERSION_FROM  => 'lib/HTML/Tiny.pm',
  ABSTRACT_FROM => 'lib/HTML/Tiny.pm',
  PL_FILES      => {},
  PREREQ_PM     => { 'Test::More' => 0, },
  dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'HTML-Tiny-*' },
);

sub license {
  my $lic = shift;
  local $^W = 0;    # Silence warning about non-numeric version
  return
   unless $ExtUtils::MakeMaker::VERSION >= '6.31';
  return ( LICENSE => $lic );
}
