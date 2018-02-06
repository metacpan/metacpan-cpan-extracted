# Copyrights 2003-2018 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution HTML-FromMail.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package HTML::FromMail::Default::HTMLifiers;
use vars '$VERSION';
$VERSION = '0.12';


use strict;
use warnings;

use HTML::FromText;
use Carp;


our @htmlifiers =
 ( 'text/plain' => \&htmlifyText
#, 'text/html'  => \&htmlifyHtml
 );


sub htmlifyText($$$$)
{   my ($page, $message, $part, $args) = @_;
    my $main     = $args->{main} or confess;
    my $settings = $main->settings('HTML::FromText')
     || { pre => 1, urls => 1, email => 1, bold => 1, underline => 1};

    my $f = HTML::FromText->new($settings)
       or croak "Cannot create an HTML::FromText object";

    { image => ''            # this is not an image
    , html  => { text => $f->parse($part->decoded->string)
               }
    }
}


1;
