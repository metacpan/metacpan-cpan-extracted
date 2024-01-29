# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message;
use vars '$VERSION';
$VERSION = '3.015';


use strict;
use warnings;


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
