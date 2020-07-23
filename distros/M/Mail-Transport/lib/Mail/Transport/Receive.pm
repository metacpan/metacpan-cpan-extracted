# Copyrights 2001-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Transport.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Transport::Receive;
use vars '$VERSION';
$VERSION = '3.005';

use base 'Mail::Transport';

use strict;
use warnings;


sub receive(@) {shift->notImplemented}

#------------------------------------------


1;
