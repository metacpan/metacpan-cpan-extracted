use strict;
use warnings;

package MY;

use Module::Loaded qw( is_loaded );

# https://metacpan.org/pod/ExtUtils::MM_Any#postamble-(o)
sub postamble {
  my ( $self ) = @_;

  my $make_fragment = '';

  $make_fragment .= join "\n", '', File::ShareDir::Install::postamble( $self )
    if is_loaded 'File::ShareDir::Install';

  $make_fragment
}

1
