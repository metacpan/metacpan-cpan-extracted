# Copyrights 2001-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.

use strict;

package Mail::Message;
use vars '$VERSION';
$VERSION = '3.000';


use Mail::Message::Head::Complete;
use Mail::Message::Body::Lines;
use Mail::Message::Body::Multipart;

use Mail::Address;
use Carp;
use Scalar::Util 'blessed';
use IO::Lines;


our %locations =
(
  bounce             => 'Bounce'

, build              => 'Build'
, buildFromBody      => 'Build'

, forward            => 'Forward'
, forwardNo          => 'Forward'
, forwardInline      => 'Forward'
, forwardAttach      => 'Forward'
, forwardEncapsulate => 'Forward'
, forwardSubject     => 'Forward'
, forwardPrelude     => 'Forward'
, forwardPostlude    => 'Forward'

, read               => 'Read'

, rebuild            => 'Rebuild'

, reply              => 'Reply'
, replySubject       => 'Reply'
, replyPrelude       => 'Reply'

, string             => 'Text'
, lines              => 'Text'
, file               => 'Text'
, printStructure     => 'Text'
);

sub AUTOLOAD(@)
{   my $self  = shift;
    our $AUTOLOAD;
    (my $call = $AUTOLOAD) =~ s/.*\:\://g;

    if(my $mod = $locations{$call})
    {   eval "require Mail::Message::Construct::$mod";
        die $@ if $@;
        return $self->$call(@_);
    }

    our @ISA;                    # produce error via Mail::Reporter
    $call = "${ISA[0]}::$call";
    $self->$call(@_);
}

1;
