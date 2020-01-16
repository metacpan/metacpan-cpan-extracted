# Copyrights 2011-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution IOMux.  Meta-POD processed with OODoc
# into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package IOMux::Net::TCP;
use vars '$VERSION';
$VERSION = '1.01';

use base 'IOMux::Handler::Read', 'IOMux::Handler::Write';

use warnings;
use strict;

use Log::Report 'iomux';
use Socket      'SOCK_STREAM';
use IO::Socket::INET;


sub init($)
{   my ($self, $args) = @_;

    $args->{Proto} ||= 'tcp';
    my $socket = $args->{fh}
      = (delete $args->{socket}) || $self->extractSocket($args);

    $args->{name}  ||= "tcp ".$socket->peerhost.':'.$socket->peerport;

    $self->IOMux::Handler::Read::init($args);
    $self->IOMux::Handler::Write::init($args);

    $self;
}

#-------------------

sub socket() {shift->fh}

#-------------------

sub shutdown($)
{   my($self, $which) = @_;
    my $socket = $self->socket;
    my $mux    = $self->mux;

    if($which!=1)
    {   # Shutdown for reading.  We can do this now.
        $socket->shutdown(0);
        $self->{IMNT_shutread} = 1;
        # The muxEOF hook must be run from the main loop to consume
        # the rest of the inbuffer if there is anything left.
        # It will also remove $fh from _readers.
        $self->fdset(0, 1, 0, 0);
    }
    if($which!=0)
    {   # Shutdown for writing.  Only do this now if there is no pending data.
        $self->{IMNT_shutwrite} = 1;
        unless($self->muxOutputWaiting)
        {   $socket->shutdown(1);
            $self->fdset(0, 0, 1, 0);
        }
    }

    $self->close
        if $self->{IMNT_shutread}
        && $self->{IMNT_shutwrite} && !$self->muxOutputWaiting;
}

sub close()
{   my $self = shift;

    warning __x"closing {name} with read buffer", name => $self->name
        if length $self->{ICMT_inbuf};

    warning __x"closing {name} with write buffer", name => $self->name
        if $self->{ICMT_outbuf};

    $self->socket->close;
    $self->SUPER::close;
}

#-------------------------

sub muxInit($)
{   my ($self, $mux) = @_;
    $self->SUPER::muxInit($mux);

    # we will not listen for write until we have something to write
    $self->fdset(1, 1, 0, 1);
}

sub muxOutbufferEmpty()
{   my $self = shift;
    $self->SUPER::muxOutbufferEmpty;

    if($self->{IMNT_shutwrite} && !$self->muxOutputWaiting)
    {   $self->socket->shutdown(1);
        $self->fdset(0, 0, 1, 0);
        $self->close if $self->{IMNT_shutread};
    }
}


1;
