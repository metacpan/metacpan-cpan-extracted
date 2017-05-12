# Copyrights 2003,2004,2007 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.00.

use strict;
use warnings;

package HTML::FromMail::Page;
use vars '$VERSION';
$VERSION = '0.11';
use base 'HTML::FromMail::Object';



sub lookup($$)
{   my ($self, $label, $args) = @_;
    $args->{formatter}->lookup($label, $args);
}

1;
