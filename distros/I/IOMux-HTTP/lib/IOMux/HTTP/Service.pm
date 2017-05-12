# Copyrights 2011 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.07.
use warnings;
use strict;

package IOMux::HTTP::Service;
use vars '$VERSION';
$VERSION = '0.11';

use base 'IOMux::HTTP';

use Log::Report 'iomux-http';

use HTTP::Request  ();
use HTTP::Response ();
use HTTP::Status;
use Socket;


my $conn_id = 'C0000000';

sub init($)
{   my ($self, $args) = @_;
    $args->{name} ||= ++$conn_id;

    $self->SUPER::init($args);
    $self->{IMHS_requests} = [];
    $self->{IMHS_handler}  = $args->{handler}
        or error __x"service {name} is started without handler callback"
             , name => $self->name;
    $self->{IMHS_session}  = {};
    $self->{IMHS_sent}     = [];
    $self;
}

#---------------------

sub client()  {shift->{IMHS_client}}
sub session() {shift->{IMHS_session}}
sub msgsSent(){shift->{IMHS_sent}}

# called when this object gets connected to the mux
sub mux_init($)
{   my ($self, $mux) = @_;
    $self->SUPER::mux_init($mux);

    my $peername         = $self->socket->peername;
    my ($port, $addr)    = unpack_sockaddr_in $peername;
    my $ip               = inet_ntoa $addr;
    my $host; # would be nice to have a async dnslookup here
    my %client           = (port => $port, ip => $ip, host => $host);
    $self->{IMHS_client} = \%client;
}

sub headerArrived($)
{   my $self  = shift;
    HTTP::Request->parse(shift);
}

sub bodyComponentArrived($$)
{   my ($self, $req, $refdata) = @_;

    my $headers = $req->headers;
    my $te = lc($headers->header('Transfer-Encoding') || '8bit');
    return $self->SUPER::bodyComponentArrived($req, $refdata)
        if $te eq '8bit';

    if($te ne 'chunked')
    {   trace "Unsupported transfer encoding $te";
        return $self->errorResponse($req, RC_NOT_IMPLEMENTED);
    }

    my ($starter, $len) = $$refdata =~ m/^((\S+)\r?\n)/ or return;
    if($len !~ m/^[0-9a-fA-F]+$/)
    {   trace "Bad chunk header $len";
        return $self->errorResponse($req, RC_BAD_REQUEST);
    }

    my $need = hex $len;
    my $chunk_length = length($starter) + $need + 2;
    return  # need more data for chunck
        if length($$refdata) < $chunk_length;
 
    if($need!=0)
    {   $req->add_content(substr $$refdata, length($starter), $need, '');
        return;  # get more chunks
    }

    return if $$refdata !~ m/\n\r?\n/;  # need footer
    my ($footer) = $$refdata =~ s/^0+\r?\n(.*?\r?\n)\r?\n//;
    my $header   = $req->headers;
    HTTP::Message->parse($footer)->headers
        ->scan(sub { $header->push_header(@_)} );

    $header->_header('Content-Length' => length ${$req->content_ref});
    $header->remove_header('Transfer-Encoding');
    $req;
}

sub messageArrived($;$)
{   my ($self, $req, $resp) = @_;

    if(my $waiting = shift @{$self->{IMHS_sent}})
    {   # try to continue on track
        my ($resp, $cb, $session) = @$waiting;
        return $cb->($self, $resp, $resp->code, $req, $session);
    }

    $self->shutdown(0)      # shutdown on low-level errors
       if $resp;

    unless($resp)
    {   # Auto-reply to "Expect" requests
        my $headers = $req->headers;
        if(my $expect = $headers->header('Expect'))
        {   $resp = lc $expect ne '100-continue'
              ? $self->errorResponse($req, RC_EXPECTATION_FAILED)
              : $self->errorResponse($req, RC_CONTINUE);
        }
    }

    my $queue = $self->{IMHS_requests};
    push @$queue, [$req, $resp];
    # trace "new queued ".$req->uri.'; ql='.@$queue;

    # handler initiated by first request in queue, then auto-continues
    $self->nextRequest
        if @$queue==1;
}

# This is the most tricky part: each connection may have multiple
# requests queued.  If the handler returns a response object, the
# the response succeeded.  Otherwise, other IO will need to be performed:
# we simply stop.  When the other IO has completed, it will call this
# function again, to resolve the other requests.

sub nextRequest()
{   my $self    = shift;
    my $queue   = $self->{IMHS_requests};
    my $starter = $self->{IMHS_handler};

    #trace "nextRequest: ".join(',', map {$_->[0]->uri} @$queue);
    while(@$queue)
    {   my $first = $queue->[0];
        my ($req, $resp) = @$first;
        if($resp)
        {   info "response already prepared: ".$req->uri;
            $self->sendResponse($resp, sub {} );
        }
        else
        {   info "initiate new session: ".$req->uri;
            $starter->($self, $req, $self->{IMHS_session});
        }
        shift @$queue;
    }
}

#--------------

sub sendResponse($$;$)
{   my ($self, $resp, $user_cb, $session) = @_;
    $resp->protocol('HTTP/1.1');
    push @{$self->{IMHS_sent}}, [$resp, $user_cb, $session];
    $self->sendMessage($resp, sub {
        # message send completed
        });
}


sub makeResponse($$$;$)
{   my ($self, $req, $status, $header, $content) = @_;
    my $resp = HTTP::Response->new($status, status_message($status), $header);
    $resp->request($req);

    $content or return $resp;

       if(ref $content eq 'CODE')   { $resp->content($content) }
    elsif(ref $content eq 'SCALAR') { $resp->content_ref($content) }
    else                            { $resp->content_ref(\$content) }

    $resp;
}


sub errorResponse($$;$)
{   my ($self, $req, $status, $text) = @_;
    my $descr   = defined $text && length $text ? "\n<p>$text</p>" : '';
    my @headers = ('Content-Type' => 'text/html');
    my $message = status_message $status;

    $self->makeResponse($req, $status, \@headers, \<<__CONTENT);
<html><head><title>$status $message</title></head>
<body><h1>$status $message</h1>$descr
</body></html>
__CONTENT
}


sub redirectResponse($$$;$)
{   my ($self, $req, $status, $location, $content) = @_;
    is_redirect $status
        or panic "Status '$status' is not redirect";

    my @headers = (Location => $location);
    if(defined $content && length $content)
    {   my $ct  = $content =~ m/^\s*\</ ? 'text/html' : 'text/plain';
        push @headers, 'Content-Type' => $ct;
    }

    $self->makeResponse($req, $status, \@headers, $content);
}

#---------------------


1;
