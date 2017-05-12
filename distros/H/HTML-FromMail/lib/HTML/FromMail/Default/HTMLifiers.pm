# Copyrights 2003,2004,2007 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.00.

use strict;
use warnings;

package HTML::FromMail::Default::HTMLifiers;
use vars '$VERSION';
$VERSION = '0.11';

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
