# Copyrights 2011-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package IOMux::Service::TCP;
use vars '$VERSION';
$VERSION = '1.00';

use base 'IOMux::Handler::Service';

use Log::Report 'iomux';
use IOMux::Net::TCP ();

use Socket 'SOCK_STREAM';


sub init($)
{   my ($self, $args) = @_;

    $args->{Proto} ||= 'tcp';
    my $socket = $args->{fh}
      = (delete $args->{socket}) || $self->extractSocket($args);

    my $proto = $socket->socktype;
    $proto eq SOCK_STREAM
         or error __x"{pkg} needs STREAM protocol socket", pkg => ref $self;

    $args->{name} ||= "listen tcp ".$socket->sockhost.':'.$socket->sockport;

    $self->SUPER::init($args);

    my $ct = $self->{IMST_conn_type} = $args->{conn_type}
        or error __x"a conn_type for incoming request is need by {name}"
          , name => $self->name;

    $self->{IMST_conn_opts} = $args->{conn_opts} || [];
    $self;
}

#------------------------

sub clientType() {shift->{IMST_conn_type}}
sub socket()     {shift->fh}

#-------------------------

# The read flag is set on the socket, which means that a new connection
# attempt is made.

sub muxReadFlagged()
{   my $self = shift;

    my $client = $self->socket->accept;
    unless($client)
    {   alert __x"accept for {name} failed", name => $self->name;
        return;
    }

    # create an object which handles this connection
    my $ct      = $self->{IMST_conn_type};
    my $opts    = $self->{IMST_conn_opts};
    my $handler = ref $ct eq 'CODE'
      ? $ct->(   socket => $client, Proto => 'tcp', @$opts)
      : $ct->new(socket => $client, Proto => 'tcp', @$opts);

    # add the new socket to the mux, to be watched
    $self->mux->add($handler);

    $self->muxConnection($client);
}

1;
