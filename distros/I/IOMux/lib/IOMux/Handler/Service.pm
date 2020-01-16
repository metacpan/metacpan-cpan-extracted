# Copyrights 2011-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution IOMux.  Meta-POD processed with OODoc
# into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package IOMux::Handler::Service;
use vars '$VERSION';
$VERSION = '1.01';

use base 'IOMux::Handler';

use warnings;
use strict;

use Log::Report       'iomux';


sub muxInit($)
{   my ($self, $mux) = @_;
    $self->SUPER::muxInit($mux);
    $self->fdset(1, 1, 0, 0);  # 'read' new connections
}

sub muxRemove()
{   my $self = shift;
    $self->SUPER::muxRemove;
    $self->fdset(0, 1, 0, 0);
}

#----------

sub muxConnection($) {shift}

1;
