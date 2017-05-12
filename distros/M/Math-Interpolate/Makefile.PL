# This -*- perl -*- script writes the Makefile for this package.

use strict;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'		=> 'Math::Interpolate',
  'ABSTRACT'		=> 'Interpolate the value Y from X using a list of (X, Y) pairs',
  'AUTHOR'		=> 'Blair Zajac <blair@orcaware.com>',
  'LICENSE'		=> 'perl',
  'MIN_PERL_VERSION'	=> '5.004_01',
  'VERSION_FROM'	=> 'lib/Math/Interpolate.pm', # finds $VERSION
);

sub MY::postamble {
  return <<'POSTAMBLE';

mydist: distmeta distsignature tardist

POSTAMBLE
}
