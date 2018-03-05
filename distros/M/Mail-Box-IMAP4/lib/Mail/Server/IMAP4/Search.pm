# Copyrights 2001-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box-IMAP4.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Server::IMAP4::Search;
use vars '$VERSION';
$VERSION = '3.003';

use base 'Mail::Box::Search';

use strict;
use warnings;


sub init($)
{   my ($self, $args) = @_;
    $self->notImplemented;
}

#-------------------------------------------

1;
