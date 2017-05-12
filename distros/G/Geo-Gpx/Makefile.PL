use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';
warn "Optional ExtUtils::MakeMaker::Coverage not available\n" if $@;

WriteMakefile(
  ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
  license( 'perl' ),
  NAME          => 'Geo::Gpx',
  AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
  VERSION_FROM  => 'lib/Geo/Gpx.pm',
  ABSTRACT_FROM => 'lib/Geo/Gpx.pm',
  PL_FILES      => {},
  PREREQ_PM     => {
    'DateTime'                  => 0,
    'DateTime::Format::ISO8601' => 0,
    'HTML::Entities'            => 0,
    'Scalar::Util'              => 0,
    'Test::More'                => 0,
    'Time::Local'               => 0,
    'XML::Descent'              => '1.01',
    'version'                   => 0,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'Geo-Gpx-*' },
);

sub license {
  my $lic = shift;
  local $^W = 0;    # Silence warning about non-numeric version
  return
   unless $ExtUtils::MakeMaker::VERSION >= '6.31';
  return ( LICENSE => $lic );
}

