=head1 NAME

HTTP::Parser - parse HTTP/1.1 request into HTTP::Request/Response object

=head1 SYNOPSIS

 my $parser = HTTP::Parser->new();

 ...

 my $status = $parser->add($text);

 if(0 == $status) {
   print "request: ".$parser->request()->as_string();  # HTTP::Request
 } elsif(-3 == $status) {
   print "no content length header!\n";
 } elsif(-2 == $status) {
   print "need a line of data\n";
 } elsif(-1 == $status) {
   print "need more data\n";
 } else {  # $status > 0
   print "need $status byte(s)\n";
 }

=head1 DESCRIPTION

This is an HTTP request parser.  It takes chunks of text as received and
returns a 'hint' as to what is required, or returns the HTTP::Request when
a complete request has been read.  HTTP/1.1 chunking is supported.  It dies
if it finds an error.

=cut
use 5.006_001;
use strict;

package HTTP::Parser;

our $VERSION = '0.06';

use HTTP::Request;
use HTTP::Response;
use URI;

# token is (RFC 2616, ASCII)
my $Token =
 qr/[\x21\x23-\x27\x2a\x2b\x2d\x2e\x30-\x39\x41-\x5a\x5e-\x7a\x7c\x7e]+/;


=head2 new ( named params... )

Create a new HTTP::Parser object.  Takes named parameters, e.g.:

 my $parser = HTTP::Parser->new(request => 1);

=over 4

=item request

Allows or denies parsing an HTTP request and returning an C<HTTP::Request>
object.

=item response

Allows or denies parsing an HTTP response and returning an C<HTTP::Response>
object.

=back

If you pass neither C<request> nor C<response>, only requests are parsed (for
backwards compatibility); if you pass either, the other defaults to false
(disallowing both requests and responses is a fatal error).

=cut
sub new {
  my ($class, %p) = @_;
  $p{request} = 1 unless exists $p{response} or exists $p{request};
  die 'must allow request or response to be parsed'
   unless $p{request} or $p{response};
  @p{qw(state data)} = ('blank', '');
  my $self = bless \%p, ref $class || $class;
  return $self;
}


=head2 add ( string )

Parse request.  Returns:

=over 8

=item  0

if finished (call C<object> to get an HTTP::Request or Response object)

=item -1

if not finished but not sure how many bytes remain

=item -2

if waiting for a line (like 0 with a hint)

=item -3

if there was no content-length header, so we can't tell whether we are 
waiting for more data or not.

If you are reading from a TCP stream, you can keep adding data until 
the connection closes gracefully (the HTTP RFC allows this).

If you are reading from a file, you should keep adding until you have 
all the data.  

Once you have added all data, you may call C<object>.  if you are not 
sure whether you have all the data, the HTTP::Response object might be 
incomplete.

=item count

if waiting for that many bytes

=back

Dies on error.

This method of parsing makes it easier to parse a request from an event-based
system, on the other hand, it's quite alright to pass in the whole request.
Ideally, the first chunk passed in is the header (up to the double newline),
then whatever byte counts are requested.

When a request object is returned, the X-HTTP-Version header has the HTTP
version, the uri() method will always return a URI object, not a string.

Note that a nonzero return is just a hint, and any amount of data can be
passed in to a subsequent add() call.

=cut
sub add {
  my ($self,$s) = @_;
  $s = '' if not defined $s;

  $self->{data} .= $s;

  # pre-header blank lines are allowed (RFC 2616 4.1)
  if($self->{state} eq 'blank') {
    $self->{data} =~ s/^(\x0d?\x0a)+//;
    return -2 unless length $self->{data};
    $self->{state} = 'header';  # done with blank lines; fall through
  }

  # still waiting for the header
  if($self->{state} eq 'header') {
    # double line break indicates end of header; parse it
    if($self->{data} =~ /^(.*?)\x0d?\x0a\x0d?\x0a/s) {
      return $self->_parse_header(length $1);
    }
    return -2;  # still waiting for unknown amount of header lines

  # waiting for main body of request
  } elsif($self->{state} eq 'body') {
    return $self->_parse_body();

  # chunked data
  } elsif($self->{state} eq 'chunked') {
    return $self->_parse_chunk();

  # trailers
  } elsif($self->{state} eq 'trailer') {
    # double line break indicates end of trailer; parse it
    return $self->_parse_header(length $1,1)
     if $self->{data} =~ /^(.*?)\x0d?\x0a\x0d?\x0a/s;
    return -1;  # still waiting for unknown amount of trailer data
  }

  die "unknown state '$self->{state}'";
}


=head2 data

Returns current data not parsed.  Mainly useful after a request has been
parsed.  The data is not removed from the object's buffer, and will be
seen before the data next passed to add().

=cut
sub data {
  shift->{data}
}


=head2 extra

Returns the count of extra bytes (length of data()) after a request.

=cut
sub extra {
  length shift->{data}
}


=head2 object

Returns the object request.  Only useful after the parse has completed.

=cut
sub object {
  shift->{obj}
}

# keep this for compatibility with 0.02
sub request {
  shift->{obj}
}


# _parse_header ( position of double newline in data [, trailer flag] )
#
# helper for parse that parses an HTTP header
# prerequisite: we have data up to a double newline in $self->{data}
# if the trailer flag is set, we're parsing trailers
#
sub _parse_header {
  my ($self,$eoh,$trailer) = @_;
  my $header = substr($self->{data},0,$eoh,'');
  $self->{data} =~ s/^\x0d?\x0a\x0d?\x0a//;

  # parse into lines
  my @header = split /\x0d?\x0a/,$header;
  my $request = shift @header unless $trailer;

  # join folded lines
  my @out;
  for(@header) {
    if(s/^[ \t]+//) {
      die 'LWS on first header line' unless @out;
      $out[-1] .= $_;
    } else {
      push @out, $_;
    }
  }

  # parse request or response line
  my $obj;
  unless($trailer) {
    my ($major, $minor);

    # is it an HTTP response?
    if ($request =~ /^HTTP\/(\d+)\.(\d+)/i) {
      die 'HTTP responses not allowed' unless $self->{response};
      ($major,$minor) = ($1,$2);
      $request =~ /^HTTP\/\d+\.\d+ (\d+) (.+)$/;
      my $state = $1;
      my $msg = $2;
      $obj = $self->{obj} = HTTP::Response->new($state, $msg);

    # perhaps a request?
    } else {
      my ($method,$uri,$http) = split / /,$request;
      die "'$request' is not the start of a valid HTTP request or response"
       unless $http and $http =~ /^HTTP\/(\d+)\.(\d+)$/i;
      ($major,$minor) = ($1,$2);
      die 'HTTP requests not allowed' unless $self->{request};

      # If the Request-URI is an abs_path, we need to tell URI that we don't
      # know the scheme, otherwise it will misinterpret paths that start with
      # // as being scheme-relative uris, and will interpret the first
      # component after // as the host (see rfc 2616)
      $uri = "//$uri" if $uri =~ m(^/);
      $obj = $self->{obj} = HTTP::Request->new($method, URI->new($uri));
    }

    $obj->header(X_HTTP_Version => "$major.$minor");  # pseudo-header

  # we've already seen the initial line and created the object
  } else {
    $obj = $self->{obj};
  }

  # import headers
  my $token = qr/[^][\x00-\x1f\x7f()<>@,;:\\"\/?={} \t]+/;
  for $header(@header) {
    die "bad header name in '$header'" unless $header =~ s/^($token):[\t ]*//;
    $obj->push_header($1 => $header);
  }

  # if we're parsing trailers we don't need to look at content
  return 0 if $trailer;

  # see what sort of content we have, if any
  if(my $length = $obj->header('content_length')) {
    s/^\s+//, s/\s+$// for $length;
    die "bad content-length '$length'" unless $length =~ /^(\d+)$/;
    $self->{state} = 'body';
    return $self->_parse_body();
  }

  # check for transfer-encoding, and handle chunking
  if(my @te = $obj->header('transfer_encoding')) {
    if(grep { lc $_ eq 'chunked' } @te) {
      $self->{state} = 'chunked';
      return $self->_parse_chunk();
    }
  }

  # section 14.13 of the spec says an HTTP response "SHOULD" return a 
  # content-length header unless there are reasons not to
  # however, the same RFC does allow "end of connection" as a valid marker
  # of the end of data and means the server does not need to set a content
  # length header.  the only status codes that "MAY NOT" return data are
  # 1xx, 204 and 304.
  # therefore if there is no content length header, return -3 to the caller
  # so they can decide whether to keep feeding data.  if using HTTP::Parser
  # with data from tcp, you could assume that the end of a connection is
  # the end of the response data
  if($self->{response}) {
    if (!defined $obj->header('content_length') &&
     $self->object->code ne '204' &&
     $self->object->code ne '304' &&
     $self->object->code !~ /1\d\d/) {

      # Assume headers are finished and we are moving into body mode
      $self->{state} = 'body';
      $self->{no_content_length} = 1;

      # Parse any data that might be left
      return $self->_parse_body() if length $self->data;
      return -3;
    }
  }

  # else we have no content so return success
  return 0;
}


# _parse_body
#
# helper for parse, returns request object with content if done, else
# count of bytes remaining
#
sub _parse_body {
  my $self = shift;
  my $length = $self->{obj}->header('content_length');

  # if the server didn't include a content length header, inform the
  # caller.  they may choose to ignore this response or wait for
  # the end of connection (which is a valid reason to assume that
  # the response is finished)
  if($self->{no_content_length}) {
    $self->{obj}->content($self->{data});
    return -3;
  }

  if(length $self->{data} >= $length) {
    $self->{obj}->content(substr($self->{data},0,$length,''));
    return 0;
  }
  return $length-length $self->{data};
}


# _parse_chunk
#
# helper for parse, parse chunked transfer-encoded message; returns like parse
#
sub _parse_chunk {
  my $self = shift;

CHUNK:

  # need beginning of chunk with size
  if(not $self->{chunk}) {
    if($self->{data} =~ s/^([0-9a-fA-F]+)[^\x0d\x0a]*?\x0d?\x0a//) {

      # a zero-size chunk marks the end
      unless($self->{chunk} = hex $1) {
        $self->{state} = 'trailer';

        # double line break indicates end of trailer; parse it
        $self->{data} = "\x0d\x0a".$self->{data};  # count previous line break
        return $self->_parse_header(length $1,1)
         if $self->{data} =~ /^(.*?)\x0d?\x0a\x0d?\x0a/s;
        return -1;  # still waiting for unknown amount of trailer data
      }

    } else {
      die "expected chunked encoding, got '".substr($self->{data},0,40)."...'"
       if $self->{data} =~ /\x0d?\x0a/;
      return -2;  # waiting for a line with chunk information
    }
  }

  # do we have a current chunk size?
  if($self->{chunk}) {

    # do we have enough data to fill it, plus a CR LF?
    if(length $self->{data} > $self->{chunk} and
     substr($self->{data},$self->{chunk},2) =~ /^(\x0d?\x0a)/) {
      my $crlf = $1;
      $self->{obj}->add_content(substr($self->{data},0,$self->{chunk}));
      substr($self->{data},0,length $crlf) = '';

      # remove data from the buffer that we've already parsed
      $self->{data} = substr($self->{data},delete $self->{chunk});

      # got chunks?
      goto CHUNK;
    }

    return $self->{chunk}-length($self->{data})+2;  # extra CR LF
  }
}


=head1 AUTHOR

David Robins E<lt>dbrobins@davidrobins.netE<gt>
Fixes for 0.05 by David Cannings E<lt>david@edeca.netE<gt>

=head1 SEE ALSO

L<HTTP::Request>, L<HTTP::Response>.

=cut


1;
