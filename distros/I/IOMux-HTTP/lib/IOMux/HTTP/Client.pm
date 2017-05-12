# Copyrights 2011 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.07.
use warnings;
use strict;

package IOMux::HTTP::Client;
use vars '$VERSION';
$VERSION = '0.11';

use base 'IOMux::HTTP';

use Log::Report 'iomux-http';

use HTTP::Request ();
use HTTP::Response ();


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);
    $self->{IMHC_sent} = [];
    $self;
}

#--------------

sub msgsSent()   {shift->{IMHC_sent}}

#--------------

sub sendRequest($$$)
{   my ($self, $req, $cb, $session) = @_;
    $req->header(Accept_Transfer_Encoding => 'chunked, 8bit');
    $req->protocol('HTTP/1.1');

    push @{$self->{IMHC_sent}}, [$req, $cb, $session];
    $self->sendMessage($req, sub {
       # message sent completed
       });
}

sub headerArrived($)
{   my $self = shift;
    HTTP::Response->parse(shift);
}

sub messageArrived($)
{   my ($self, $resp) = @_;
    my $waiting = shift @{$self->{IMHC_sent}};
    unless($waiting)
    {   alert "message arrived, but there was no request";
        return;
    }
    my ($req, $cb, $session) = @$waiting;
    $cb->($self, $req, $resp->code, $resp, $session);
}


1;
