use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
#  ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
  license( 'perl' ),
  NAME          => 'HTML::TagCloud::Centred',
  AUTHOR        => 'Lee Goddard <lgoddard@cpan.org>',
  VERSION	=> 10,
  # VERSION_FROM  => 'lib/HTML/TagCloud/Centred.pm',
  ABSTRACT_FROM => 'lib/HTML/TagCloud/Centred.pm',
  PL_FILES      => {},
  PREREQ_PM     => {
    'Test::More' => 0,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'HTML-TagCloud-Centred-*' },
);

sub license {
  my $lic = shift;
  local $^W = 0;    # Silence warning about non-numeric version
  return
   unless $ExtUtils::MakeMaker::VERSION >= '6.31';
  return ( LICENSE => $lic );
}


