use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
  NAME         => 'File::AtomicWrite',
  VERSION_FROM => 'lib/File/AtomicWrite.pm',
  PREREQ_PM    => {
    Carp           => 0,
    'File::Path'   => 0,
    'File::Temp'   => 0.18,
    'IO::Handle'   => 0,
    'Digest::SHA1' => 0,
    'Test::More'   => 0,
    'File::Spec'   => 0
  },
  ( $] >= 5.005
    ? (
      ABSTRACT_FROM => 'lib/File/AtomicWrite.pm',      # retrieve abstract from module
      AUTHOR        => 'Jeremy Mates <jmates@cpan.org>'
      )
    : ()
  ),
);

if ( $ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/ and $ExtUtils::MakeMaker::VERSION > 6.30 ) {
  $params{LICENSE} = 'artistic_2';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
  $params{META_MERGE} = {
    resources => {
      homepage   => 'https://github.com/thrig/File-AtomicWrite',
      license    => 'http://dev.perl.org/licenses/',
      repository => 'https://github.com/thrig/File-AtomicWrite',
    }
  };
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.48' ) {
  $params{MIN_PERL_VERSION} = 5.000000;
}

WriteMakefile( ( MM->can('signature_target') ? ( SIGN => 1 ) : () ), %params );
