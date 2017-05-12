# Copyrights 2003,2004,2007 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.00.

use strict;
use warnings;

package HTML::FromMail::Format;
use vars '$VERSION';
$VERSION = '0.11';
use base 'Mail::Reporter';


sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args) or return;

    $self;
}


sub containerText($) { shift->notImplemented }


sub processText($$) { shift->notImplemented }


sub lookup($$) { shift->notImplemented }


sub onFinalToken($) { 0 }

1;
