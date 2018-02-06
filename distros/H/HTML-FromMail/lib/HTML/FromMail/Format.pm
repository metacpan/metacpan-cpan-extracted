# Copyrights 2003-2018 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution HTML-FromMail.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package HTML::FromMail::Format;
use vars '$VERSION';
$VERSION = '0.12';

use base 'Mail::Reporter';

use strict;
use warnings;


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
