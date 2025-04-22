# Copyrights 2007-2025 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Log-Report-Lexicon. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Log::Report::Lexicon;{
our $VERSION = '1.12';
}


use warnings;
use strict;

use Log::Report 'log-report-lexicon';


sub new(@)
{   my $class = shift;
    (bless {}, $class)->init( {@_} );
}

sub init($) { shift }   # $self, $args

#--------------

#--------------

1;
