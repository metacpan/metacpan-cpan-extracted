# Copyrights 2002-2003,2007-2012 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.
use strict;
use warnings;

package Hash::Case::Upper;
use vars '$VERSION';
$VERSION = '1.02';

use base 'Hash::Case';

use Log::Report 'hash-case';


sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::native_init($args);

    error __x"no options available for {pkg}", pkg => __PACKAGE__
        if keys %$args;

    $self;
}

sub FETCH($)  { $_[0]->{uc $_[1]} }
sub STORE($$) { $_[0]->{uc $_[1]} = $_[2] }
sub EXISTS($) { exists $_[0]->{uc $_[1]} }
sub DELETE($) { delete $_[0]->{uc $_[1]} }

1;
