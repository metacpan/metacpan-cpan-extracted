use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
  license( 'perl' ),
  NAME          => 'Form::Sensible::Reflector::MySQL',
  AUTHOR        => 'Lee Goddard <lgoddard@cpan.org>',
  VERSION	    => 0.7,
  ABSTRACT_FROM => 'lib/Form/Sensible/Reflector/MySQL.pm',
  PL_FILES      => {},
  PREREQ_PM     => {
	'Math::BigInt'	=> 0.1,
	'Test::Most'	=> 0.23,
	'Form::Sensible'			=> '0.20012',
	'Form::Sensible::Reflector' => 0,
	DBI	=> 1,
	'DBD::mysql'	=> 1,
	'DateTime::Format::MySQL'	=> 0.04,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'ALPHA-Form-Sensible-Reflector-MySQL-ALPHA-*' },
);

sub license {
  my $lic = shift;
  local $^W = 0;    # Silence warning about non-numeric version
  return
   unless $ExtUtils::MakeMaker::VERSION >= '6.31';
  return ( LICENSE => $lic );
}


