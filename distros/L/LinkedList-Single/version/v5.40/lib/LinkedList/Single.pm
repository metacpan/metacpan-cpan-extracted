########################################################################
# housekeeping
########################################################################
package LinkedList::Single  v2.0.0;
use v5.40;

use Carp        qw( croak                   );
use Sub::Name   qw( subname                 );
use Symbol      qw( qualify qualify_to_ref  );

# drag in one of the two LinkedList::Single::v[12] mods
# to keep the syntax for v1 unchanged.

sub import( $, $vers='v1' )
{
    $vers =~ m{^ v[12] $}x
    or croak "Bogus version: '$vers' is not 'v1'/'v2'";

    our $pkg = qualify $vers;

    # neither has an import(), require works.

    eval "require $pkg" // croak "Failed require $pkg: $@";
}

1
__END__
