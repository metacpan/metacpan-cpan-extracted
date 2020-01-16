# Copyrights 2011-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution IOMux.  Meta-POD processed with OODoc
# into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package IOMux::Service::TCP;
use vars '$VERSION';
$VERSION = '1.01';

use base 'IOMux::Handler::Service';

use warnings;
use strict;

use Log::Report 'iomux';
use IOMux::Net::TCP ();

use Socket 'SOCK_STREAM';


sub init($)
{   my ($self, $args) = @_;

    $args->{Proto} ||= 'tcp';
    my $socket = delete $args->{socket} || $self->extractSocket($args);
    $socket->socktype eq SOCK_STREAM
        or error __x"{pkg} needs STREAM protocol socket", pkg => ref $self;
    $args->{fh}     = $socket;

    my $sockaddr    = $socket->sockhost.':'.$socket->sockport;
    $args->{name} ||= "listen tcp $sockaddr";

    $self->SUPER::init($args);

    my $ct = $self->{IMST_conn_type} = $args->{conn_type}
        or error __x"a conn_type for incoming request is need by {name}"
          , name => $self->name;

    $self->{IMST_conn_opts} = $args->{conn_opts} || [];
    $self->{IMST_hostname}  = $args->{hostname}  || $sockaddr;
    $self;
}

#------------------------

sub clientType() {shift->{IMST_conn_type}}
sub socket()     {shift->fh}
sub hostname()   {shift->{IMST_hostname}}

#-------------------------

# The read flag is set on the socket, which means that a new connection
# attempt is made.


sub muxReadFlagged()
{   my $self = shift;

    my $client = $self->socket->accept;
    unless($client)
    {   alert __x"accept for socket {name} failed", name => $self->name;
        return;
    }

    # create an object which handles this connection
    my $ct      = $self->clientType;
    my $opts    = $self->{IMST_conn_opts};
    my $handler = ref $ct eq 'CODE'
      ? $ct->   (socket => $client, Proto => 'tcp', @$opts)
      : $ct->new(socket => $client, Proto => 'tcp', @$opts);

    # add the new socket to the mux, to be watched
    $self->mux->add($handler);

    $self->muxConnection($client);
}

1;
