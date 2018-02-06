# Copyrights 2003-2018 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution HTML-FromMail.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package HTML::FromMail::Page;
use vars '$VERSION';
$VERSION = '0.12';

use base 'HTML::FromMail::Object';

use strict;
use warnings;



sub lookup($$)
{   my ($self, $label, $args) = @_;
    $args->{formatter}->lookup($label, $args);
}

1;
