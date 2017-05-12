##-*- Mode: CPerl -*-

## File: DiaColloDB::WWW::Handler.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description:
##  + abstract handler API class for DiaColloDB::WWW::Server
##  + adapted from DTA::CAB::Server::HTTP::Handler ( svn+ssh://odo.dwds.de/home/svn/dev/DTA-CAB/trunk/CAB/Server/HTTP/Handler.pm )
##======================================================================

package DiaColloDB::WWW::Handler;
use HTTP::Status;
use DiaColloDB::Logger;
use UNIVERSAL;
use strict;

BEGIN {
  *isa = \&UNIVERSAL::isa;
  *can = \&UNIVERSAL::can;
}

our @ISA = qw(DiaColloDB::Logger);

##======================================================================
## API
##======================================================================

## $h = $class_or_obj->new(%options)
sub new {
  my $that = shift;
  return bless { @_ }, ref($that)||$that;
}

## $bool = $h->prepare($server,$path)
sub prepare { return 1; }

## $rsp = $h->run($server, $clientConn, $httpRequest)
##  + perform local processing
##  + should return a HTTP::Response object to pass to the client
##  + if the call die()s or returns undef, an error response will be
##    sent to the client instead if it the connection is still open
##  + this method may return the data to the client itself; if so,
##    it should close the client connection ($csock->shutdown(2); $csock->close())
##    and return undef to prevent bogus error messages.
sub run {
  my ($h,$srv,$csock,$hreq) = @_;
  $h->logdie("run() method not implemented");
}

## undef = $h->finish($server, $clientConn)
##  + clean up handler state after run()
##  + default implementation does nothing
sub finish {
  return;
}

##======================================================================
## Generic Utilities

## $rsp = $h->headResponse()
## $rsp = $h->headResponse(\@headers)
## $rsp = $h->headResponse($httpHeaders)
## + rudimentary handling for HEAD requests
sub headResponse {
  my ($h,$hdr) = @_;
  return $h->response(RC_OK,undef,$hdr);
}

## $rsp = $CLASS_OR_OBJECT->response($code=RC_OK, $msg=status_message($code), $hdr, $content)
##  + $hdr may be a HTTP::Headers object, an array or hash-ref
##  + wrapper for HTTP::Response->new()
sub response {
  my $h = shift;
  my $code = shift;
  $code = RC_OK if (!defined($code));
  ##
  my $msg  = @_ ? shift : undef;
  $msg  = status_message($code) if (!defined($msg));
  ##
  my $hdr  = @_ ? shift : undef;
  $hdr  = [] if (!$hdr);
  ##
  return HTTP::Response->new($code,$msg,$hdr) if (!@_);
  return HTTP::Response->new($code,$msg,$hdr,@_);
}

## undef = $h->cerror($csock, $status=RC_INTERNAL_SERVER_ERROR, @msg)
##  + sends an error response and sends it to the client socket
##  + also logs the error at level ($c->{logError}||'warn') and shuts down the socket
sub cerror {
  my ($h,$c,$status,@msg) = @_;
  if (defined($c) && $c->opened) {
    $status   = RC_INTERNAL_SERVER_ERROR if (!defined($status));
    my $chost = $c->peerhost();
    my $msg   = @msg ? join('',@msg) : status_message($status);
    $h->vlog(($h->{logError}||'error'), "client=$chost: $msg");
    {
      my $_warn=$^W;
      $^W=0;
      $c->send_error($status, $msg);
      $^W=$_warn;
    }
    $c->shutdown(2);
    $c->close();
  }
  return undef;
}

## $rsp = $h->dumpResponse(\$contentRef, %opts)
##  + Create and return a new data-dump response.
##    Known %opts:
##    (
##     raw => $bool,      ##-- return raw data (text/plain) ; defualt=$h->{returnRaw}
##     type => $mimetype, ##-- mime type if not raw mode
##     charset => $enc,   ##-- character set, if not raw mode
##     filename => $file, ##-- attachment name, if not raw mode
##    )
sub dumpResponse {
  my ($h,$dataref,%vars) = @_;
  my $returnRaw   = defined($vars{raw}) ? $vars{raw} : $h->{returnRaw};
  my $contentType = ($returnRaw || !$vars{type} ? 'text/plain' : $vars{type});
  $contentType   .= "; charset=$vars{charset}" if ($vars{charset} && $contentType !~ m|application/octet-stream|);
  ##
  my $rsp = $h->response(RC_OK);
  $rsp->content_type($contentType);
  $rsp->content_ref($dataref) if (defined($dataref));
  $rsp->header('Content-Disposition' => "attachment; filename=\"$vars{filename}\"") if ($vars{filename} && !$returnRaw);
  return $rsp;
}


1; ##-- be happy

__END__
