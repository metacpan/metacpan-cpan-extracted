use strict;
use warnings;

package MY;

use File::Spec::Functions qw( catdir rel2abs );
use Module::Loaded        qw( is_loaded );

# https://metacpan.org/pod/ExtUtils::MM_Any#postamble-(o)
sub postamble {
  my ( $self ) = @_;

  my $make_fragment = '';

  $make_fragment .= join "\n", '', File::ShareDir::Install::postamble( $self )
    if is_loaded 'File::ShareDir::Install';

  $make_fragment
}

# https://metacpan.org/pod/ExtUtils::MM_Any#test_via_harness
sub test_via_harness {
  my ( $self, $perl, $tests ) = @_;

  my $tlib = rel2abs( catdir( qw( t lib ) ) );
  $perl .= " -I$tlib" if -d $tlib;

  $self->SUPER::test_via_harness( $perl, $tests )
}

1
