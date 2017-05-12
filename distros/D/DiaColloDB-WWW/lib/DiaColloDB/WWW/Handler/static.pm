##-*- Mode: CPerl -*-

## File: DiaColloDB::WWW::Handler::static.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description:
##  + DiaColloDB::WWW::Server URI handler for static files
##  + adapted from DTA::CAB::Server::HTTP::Handler::File ( svn+ssh://odo.dwds.de/home/svn/dev/DTA-CAB/trunk/CAB/Server/HTTP/Handler/File.pm )
##======================================================================

package DiaColloDB::WWW::Handler::static;
use DiaColloDB::WWW::Handler;
use HTTP::Status;
use Carp;
use strict;

our @ISA = qw(DiaColloDB::WWW::Handler);

##--------------------------------------------------------------
## $h = $class_or_obj->new(%options)
##  + options:
##     contentType => $mimeType,    ##-- override MIME type e.g. 'text/plain; charset=utf8'; default via MIME::Types::mimeTypeOf()
##     charset => $charset,         ##-- default charset for text types (default='utf8')
##     file => $filename,           ##-- filename to return
sub new {
  my $that = shift;
  return bless { file=>'', contentType=>undef, charset=>'utf8', @_ }, ref($that)||$that;
}

## $rsp = $h->run($server, $clientConn, $httpRequest)
sub run {
  my ($h,$srv,$csock,$hreq) = @_;
  return $h->error($csock,(-e $h->{file} ? RC_FORBIDDEN : RC_NOT_FOUND)) if (!-r $h->{file});

  open(my $fh, "<:raw", $h->{file});
  return $h->error($csock,RC_NOT_FOUND) if (!defined($fh));
  local $/=undef;
  my $data = <$fh>;
  close($fh);
  my $rsp = HTTP::Response->new(RC_OK, status_message(RC_OK), ['Content-Type' => $h->contentType($srv)]);
  $rsp->content_ref(\$data);
  return $rsp;
}

##--------------------------------------------------------------
## local utilities

## $contentType = $h->contentType($srv)
## $contentType = $h->contentType($srv,$file)
sub contentType {
  my ($h,$srv,$file) = @_;
  $file //= $h->{file};
  my $ctype = $h->{contentType} // $srv->mimetype($file);
  $ctype .= "; charset=$h->{charset}" if ($ctype =~ /^text/ && $ctype !~ /\bcharset\b/ && defined($h->{charset}));
  return $ctype;
}

1; ##-- be happy

__END__
