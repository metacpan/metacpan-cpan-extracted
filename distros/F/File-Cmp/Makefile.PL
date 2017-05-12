#!perl

use 5.008000;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
  NAME         => 'File::Cmp',
  ABSTRACT     => 'compare two files character by character',
  VERSION_FROM => 'lib/File/Cmp.pm',
  PREREQ_PM    => {
    Carp           => 0,
    Exporter       => 0,
    'Scalar::Util' => 0,
    'Test::More'   => 0,
  },
  ( $] >= 5.005
    ? ( AUTHOR => 'Jeremy Mates <jmates@cpan.org>' )
    : ()
  ),
);

if ( $ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/ and $ExtUtils::MakeMaker::VERSION > 6.30 ) {
  $params{LICENSE} = 'artistic_2';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
  $params{META_MERGE} = {
    resources => {
      homepage   => 'http://github.com/thrig/File-Cmp',
      license    => 'http://dev.perl.org/licenses/',
      repository => 'http://github.com/thrig/File-Cmp',
    }
  };
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.48' ) {
  $params{MIN_PERL_VERSION} = 5.010000;
}

WriteMakefile((MM->can('signature_target') ? (SIGN => 1) : ()), %params);
