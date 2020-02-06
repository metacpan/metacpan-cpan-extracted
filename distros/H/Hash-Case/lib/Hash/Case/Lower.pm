# Copyrights 2002-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Hash::Case.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Hash::Case::Lower;
use vars '$VERSION';
$VERSION = '1.05';

use base 'Hash::Case';

use strict;
use warnings;
use Carp   qw(croak);


sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::native_init($args);

    croak "no options possible for ". __PACKAGE__
        if keys %$args;

    $self;
}

sub FETCH($)  { $_[0]->{lc $_[1]} }
sub STORE($$) { $_[0]->{lc $_[1]} = $_[2] }
sub EXISTS($) { exists $_[0]->{lc $_[1]} }
sub DELETE($) { delete $_[0]->{lc $_[1]} }

1;
