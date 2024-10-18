#!/usr/bin/perl -cw

use strict;
use warnings;

package Mail::JMAPTalk;

use HTTP::Tiny;
use JSON;
use Convert::Base64;
use File::LibMagic;
use Carp qw(confess);
use Data::Dumper;

our $VERSION = '0.16';

our $CLIENT = "Mail-JMAPTalk";
our $AGENT = "$CLIENT/$VERSION";

our $JSON = JSON->new->utf8->max_depth(2048);

=head1 NAME

Mail::JMAPTalk - Basic interface to talk to JMAP Servers

=head1 VERSION

Version 0.16

=head1 SYNOPSIS

Mail::JMAPTalk was originally written as a very small wrapper around HTTP::Tiny
to talk to a JMAP server and mapping between Perl hashes and JSON on the wire.

It doesn't do anything smart with specific JMAP objects.

Example:

    use Mail::JMAPTalk;
    use JSON;

    # using basic auth
    my $jtalk = Mail::JMAPTalk->new(
        url => "https://jmap.example.com/",
        user => "foo\@example.com",
        password => "letmein",
    );

    # using non-standard JMAPAuth token establishment
    my $jtalk = Mail::JMAPTalk->new(
        url => "https://jmap.example.com/",
    );
    $jtalk->Login("foo\@example.com", "letmein");

    my $res = $jtalk->Call('Mailbox/get');
    my %byname = map { $_->{name} -> $_->{id} } @{$res->{ids});

    my $data = $jtalk->Upload($emailbytes, 'message/rfc822');
    $res = $jtalk->CallMethods([['Email/import', {
        emails => {
            "1" => {
                blobId => $data->{blobId},
                keywords => { '$seen' => JSON::true },
                mailboxIds => { $byname{Inbox} => JSON::true },
            },
        },
    }, "R1"], ["Email/get", { ids => ["#1"] }, "R2" ]]);
    # all properties of the email in $res->[1][1]{list}[0]

    my $response = $jtalk->Download($res->[1][1]{accountId}, $data->{blobId});


=head1 SUBROUTINES/METHODS

=head2 $class->new(%Options)

Create a new Mail::JMAPTalk object.

Takes options for a variety of purposes:

Override the UserAgent used for all connections:

 * ua => HTTP::Tiny->new(...)

Host Options:

 * scheme => 'http' or 'https' (default 'http')
 * host => hostname (default 'localhost')
 * port => port number (default 443 for https, otherwise 80)

URI Options: (absolute URI, or use options above to set the scope)

 * authurl => auth endpoint (default '/jmap/auth/')
 * uploadurl => upload endpoint (default '/jmap/upload/{accountId}/')
 * downloadurl => download endpoint (default '/jmap/download/{accountId}/{blobId}/{name}')
 * url => JMAP API endpoint (default '/jmap/')

Authentication Options: (basic auth)

 * user => $username
 * password => $password

Request Defaults:

 * using => \@urns (default ['urn:ietf:params:jmap:core', 'urn:ietf:params:jmap:mail'])

=cut

sub new {
  my ($Proto, %Args) = @_;
  my $Class = ref($Proto) || $Proto;

  my $Self = bless { %Args }, $Class;

  $Self->{using} ||= ['urn:ietf:params:jmap:core', 'urn:ietf:params:jmap:mail'];

  return $Self;
}

=head2 my $ua = $Self->ua();

=head2 $Self->ua($setua);

Get or set the useragent (HTTP::Tiny or compatible) that will be used to make
the requests:

e.g.

    my $ua = $Self->ua();

    $Self->ua(HTTP::Tiny->new(agent => "MyAgent/1.0", timeout => 5));

=cut

sub ua {
  my $Self = shift;
  unless ($Self->{ua}) {
    $Self->{ua} = HTTP::Tiny->new(agent => $AGENT);
  }
  return $Self->{ua};
}

=head2 my $header = $Self->auth_header();

Returns the basic-auth value for the 'Authentication' header.

=cut

sub auth_header {
  my $Self = shift;
  return 'Basic ' . encode_base64("$Self->{user}:$Self->{password}", '');
}

=head2 my $uri = $Self->authuri();

Returns the URI for JMAPAuth authentication (non-standard).  Default depends
on the parameters passed to new.  Most simple would be:

    http://localhost/jmap/auth/

=cut

sub authuri {
  my $Self = shift;
  my $scheme = $Self->{scheme} // 'http';
  my $host = $Self->{host} // 'localhost';
  my $port = $Self->{port} // ($scheme eq 'http' ? 80 : 443);
  my $url = $Self->{authurl} // '/jmap/auth/';

  return $url if $url =~ m/^http/;

  return "$scheme://$host:$port$url";
}

=head2 my $uri = $Self->uploaduri($accountId);

Returns the URI for JMAP uploads.  Default depends
on the parameters passed to new.  Most simple would be:

    http://localhost/jmap/upload/${accountId}/

=cut

sub uploaduri {
  my $Self = shift;
  my $accountId = shift;
  die "need account" unless $accountId;
  my $scheme = $Self->{scheme} // 'http';
  my $host = $Self->{host} // 'localhost';
  my $port = $Self->{port} // ($scheme eq 'http' ? 80 : 443);
  my $url = $Self->{uploadurl} // '/jmap/upload/{accountId}/';

  my %map = (
    accountId => $accountId,
  );
  $url =~ s/\{([a-zA-Z0-9_]+)\}/$map{$1}||''/ges;

  return $url if $url =~ m/^http/;

  return "$scheme://$host:$port$url";
}

=head2 my $uri = $Self->downloaduri($accountId, $blobId, $name);

Returns the URI for JMAP downloads.  Default depends
on the parameters passed to new.  Most simple would be:

    http://localhost/jmap/download/${accountId}/${blobId}/{$name}

Where name is utf8 and uri encoded to be safe.

=cut

sub downloaduri {
  my $Self = shift;
  my ($accountId, $blobId, $name) = @_;
  die "need account and blob" unless ($accountId and $blobId);
  $name ||= "download";
  my $scheme = $Self->{scheme} // 'http';
  my $host = $Self->{host} // 'localhost';
  my $port = $Self->{port} // ($scheme eq 'http' ? 80 : 443);
  my $url = $Self->{downloadurl} // '/jmap/download/{accountId}/{blobId}/{name}';

  # needs to be encoded as bytes for URI encoding
  utf8::encode($name);

  my %map = (
    accountId => $accountId,
    blobId => $blobId,
    name => $name =~ s/([^a-zA-Z0-9])/sprintf('%%%02X', ord($1))/egr
  );

  $url =~ s/\{([a-zA-Z0-9_]+)\}/$map{$1}||''/ges;

  return $url if $url =~ m/^http/;

  return "$scheme://$host:$port$url";
}

=head2 my $uri = $Self->uri()

Returns the URI for JMAP API Calls.  Default depends
on the parameters passed to new.  Most simple would be:

    http://localhost/jmap/

=cut

sub uri {
  my $Self = shift;
  my $scheme = $Self->{scheme} // 'http';
  my $host = $Self->{host} // 'localhost';
  my $port = $Self->{port} // ($scheme eq 'http' ? 80 : 443);
  my $url = $Self->{url} // '/jmap/';

  return $url if $url =~ m/^http/;

  return "$scheme://$host:$port$url";
}

=head2 my $uri = $Self->JSONPOST($Uri, $Request, %Headers)

Makes a POST request to the given URI with the body being the
value of $Request (which must be a reference) encoded as JSON,
and with the Headers added.

Will set Content-Type and Accept headers to 'application/json'
unless overridden.

Generally you won't call this directly, but through one of the
helper methods.

This method will die if the response is not successful or does not
contain valid json.

=cut

sub JSONPOST {
  my ($Self, $Uri, $Request, %Headers) = @_;

  $Headers{'Content-Type'} //= "application/json";
  $Headers{'Accept'} //= "application/json";

  my $Response = $Self->ua->post($Uri, {
    headers => \%Headers,
    content => $JSON->encode($Request),
  });

  my $jdata;
  $jdata = eval { $JSON->decode($Response->{content}) } if $Response->{success};

  if ($ENV{DEBUGJMAP}) {
    warn "JMAP " . Dumper($Uri, \%Headers, $Request, $Response);
  }

  # check your own success on the Response object
  if (wantarray) {
    return ($Response, $jdata);
  }

  confess "JMAP request for $Self->{user} failed ($Uri): $Response->{status} $Response->{reason}: $Response->{content}"
    unless $Response->{success};

  confess "INVALID JSON $Response->{content}" unless $jdata;

  return $jdata;
}

=head2 $Self->AuthRequest($Request, %Headers)

Makes a JSONPOST request to the authurl.

=cut

sub AuthRequest {
  my ($Self, $Request, %Headers) = @_;

  return $Self->JSONPOST($Self->authuri(), $Request, %Headers);
}

=head2 $Self->Login($Username, $Password)

Uses the non-standard JMAPAuth protocol to login.

On success will set the upload, download and api urls as well as
a token which is used to authenticate all further requests.

On failure will die.

=cut

sub Login {
  my ($Self, $Username, $Password) = @_;

  my $data = $Self->AuthRequest({
    username => $Username,
    clientName => $CLIENT,
    clientVersion => $VERSION,
    deviceName => $Self->{deviceName} || 'api',
  });

  while ($data->{loginId}) {
    die "Unknown method" unless grep { $_->{type} eq 'password' } @{$data->{methods}};
    $data = $Self->AuthRequest({
      loginId => $data->{loginId},
      type => 'password',
      password => $Password,
    });
  }

  die "Failed to get a token" unless $data->{accessToken};

  $Self->{token} = $data->{accessToken};
  $Self->{url} = $data->{apiUrl};
  $Self->{uploaduri} = $data->{uploadUrl};
  $Self->{downloaduri} = $data->{downloadUrl};
  $Self->{eventSource} = $data->{eventSource};

  return 1;
}

=head2 $Self->Request($Request, %Headers)

Makes a JSONPOST request to the API url, authenticated with either
the basic auth parameters given at creation, or the token obtained
via Login.

=cut

sub Request {
  my ($Self, $Request, %Headers) = @_;

  if ($Self->{user}) {
    $Headers{'Authorization'} = $Self->auth_header();
  }
  if ($Self->{token}) {
    $Headers{'Authorization'} = "Bearer $Self->{token}";
  }

  return $Self->JSONPOST($Self->uri(), $Request, %Headers);
}

=head2 my $using = $Self->DefaultUsing()

=head2 $Self->DefaultUsing(\@urns)

Returns or replaces the default 'using' value for method calls.

=cut

sub DefaultUsing {
  my ($Self, $Using) = @_;
  return $Self->{using} unless $Using;
  $Self->{using} = $Using;
}

=head2 $Self->AddUsing(@urns)

Appends any urns given to the default 'using'
if they aren't already registered.

=cut

sub AddUsing {
  my $Self = shift;
  foreach my $Using (@_) {
    next if grep { $_ eq $Using } @{$Self->{using}};
    push @{$Self->{using}}, $Using;
  }
}

=head2 $Self->CallMethods($MethodCalls, $Using, %Headers)

Generates a JMAP request from the given method calls,
optionally overriding the using and header values.

MethodCalls is an array of arrays, each of the sub arrays
is a single "Invocation" per RFC8620 as follows:

   3.2.  The Invocation Data Type

   Method calls and responses are represented by the *Invocation* data
   type.  This is a tuple, represented as a JSON array containing three
   elements:

   1.  A "String" *name* of the method to call or of the response.

   2.  A "String[*]" object containing named *arguments* for that method
       or response.

   3.  A "String" *method call id*: an arbitrary string from the client
       to be echoed back with the responses emitted by that method call
       (a method may return 1 or more responses, as it may make implicit
       calls to other methods; all responses initiated by this method
       call get the same method call id in the response).

In perl, this is [string, hashref, string].

Example:

    my $res = $jtalk->CallMethods([
        ['Email/query', { }, 'R1'],
        ['Email/get', {
            '#ids' => {
                resultOf => 'R1',
                name => 'Email/query',
                path => '/ids'
            },
            properties => [ 'subject', 'header:x-mood:asText', 'from', 'to' ],
        }, 'R2'],
    ]);

The response is an arrayref containing the value of methodResponses from the
JSON reply defined in JMAP.

This method will die if the server returns an error or invalid JSON.

=cut

sub CallMethods {
  my ($Self, $MethodCalls, $Using, %Headers) = @_;

  $Using ||= $Self->{using};

  my $Request = {
    using => $Using,
    methodCalls => $MethodCalls,
    createdIds => $Self->{CreatedIds} || {},
  };

  my $Response = $Self->Request($Request, %Headers);

  $Self->{CreatedIds} = $Response->{createdIds};
  $Self->{SessionState} = $Response->{sessionState};

  return $Response->{methodResponses};
}

=head2 $Self->Call($Method, $Params, $Using, %Headers)

A convenience method to call a single method.  This method
generates a single invocation with call id 'c1' and will
return undef unless the first response from the server has
the same method name (i.e. is not an error) and the same
call id.

The return value is the response section (middle field) of
the first methodResponse Invocation object.

Example:

    my $res = $jtalk->Call('Calendar/get', { properties => ['name'] });
    my %byname = map { $_->{name} => $_->{id} } @{$res->{list}};

=cut

sub Call {
  my ($Self, $Method, $Params, @Args) = @_;
  $Params ||= {};
  my $Res = $Self->CallMethods([[$Method, $Params, "c1"]], @Args);
  return undef unless ref $Res;
  return undef unless ref $Res->[0];
  return undef unless $Res->[0][0] eq $Method;
  return undef unless $Res->[0][2] eq 'c1';
  return $Res->[0]->[1];
}

sub _get_type {
  my $data = shift;
  # XXX - escape file names?
  my $magic = File::LibMagic->new();
  my $info = $magic->info_from_string($data);
  return $info->{mime_type};
}

=head2 $Self->Upload($Headers?, $data, $mimetype, $accountId)

If the first argument is a hash reference, it will be shifted
and used as additional headers.

Uploads the bytes in $data with either the given mimetype or
if the mimetype is not given, the type picked by File::LibMagic.

The POST request is authenticated with either the basic auth
parameters given at creation, or the token obtained via Login.

If called in scalar context, will die unless the request was
successful - and returns a hashref with the content returned
by the server as defined in RFC8620:

   A successful request MUST return a single JSON object with the
   following properties as the response:

   o  accountId: "Id"

      The id of the account used for the call.

   o  blobId: "Id"

      The id representing the binary data uploaded.  The data for this
      id is immutable.  The id *only* refers to the binary data, not any
      metadata.

   o  type: "String"

      The media type of the file (as specified in [RFC6838],
      Section 4.2) as set in the Content-Type header of the upload HTTP
      request.

   o  size: "UnsignedInt"

      The size of the file in octets.

If called in array context, returns two values - the first is the raw
HTTP::Tiny response hash, and the second is the JSON as above.

Example:

    my ($Response, $data) = $jtalk->Upload($bytes);
    if ($Response->{success}) {
        say "Uploaded $data->{size} bytes as $data->{blobId}";
        ...
    }

=cut

sub Upload {
  my $Self = shift;
  my %Headers;
  if (ref($_[0]) eq 'HASH') {
      %Headers = %{ (shift) };
  }
  my ($data, $type, $accountId) = @_;

  $Headers{'Content-Type'} = $type || _get_type($data);
  $accountId = $accountId || $Self->{user};

  if ($Self->{user}) {
    $Headers{'Authorization'} = $Self->auth_header();
  }
  if ($Self->{token}) {
    $Headers{'Authorization'} = "Bearer $Self->{token}";
  }

  my $uri = $Self->uploaduri($accountId);

  my $Response = $Self->ua->post($uri, {
    headers => \%Headers,
    content => $data,
  });

  if ($ENV{DEBUGJMAP}) {
    warn "JMAP UPLOAD " . Dumper($Response);
  }

  my $jdata;
  $jdata = eval { $JSON->decode($Response->{content}) } if $Response->{success};

  # check your own success on the Response object
  if (wantarray) {
    return ($Response, $jdata);
  }

  confess "JMAP request for $Self->{user} failed ($uri): $Response->{status} $Response->{reason}: $Response->{content}"
    unless $Response->{success};

  confess "INVALID JSON $Response->{content}" unless $jdata;

  return $jdata;
}

=head2 $Self->Download($cb?, $Headers?, $accountId, $blobId, $name)

Makes a GET request authenticated with either the basic auth parameters
given at creation, or the token obtained via Login.

If the first argument is a code reference, it will be shifted and used
as the data_callback (see HTTP::Tiny).

Then - if the first argument is a hash reference, it will be shifted
and used as additional headers.

Then - the remaining parameters are passed to $Self->downloadurl() to
generate the link to download.

The response is a HTTP::Tiny Response object.

Example:

    my $res = $jtalk->Download($accountId, $data->{blobId}, "image.gif");
    if ($res->{success}) {
        open(FH, ">image.gif");
        print FH $res->{content};
        close(FH);
    }

=cut

sub Download {
  my $Self = shift;
  my $cb;
  if (ref($_[0]) eq 'CODE') {
    $cb = shift;
  }
  my %Headers;
  if (ref($_[0]) eq 'HASH') {
      %Headers = %{ (shift) };
  }
  my $uri = $Self->downloaduri(@_);

  if ($Self->{user}) {
    $Headers{'Authorization'} = $Self->auth_header();
  }
  if ($Self->{token}) {
    $Headers{'Authorization'} = "Bearer $Self->{token}";
  }

  my %getopts = (headers => \%Headers);
  $getopts{data_callback} = $cb if $cb;
  my $Response = $Self->ua->get($uri, \%getopts);

  if ($ENV{DEBUGJMAP}) {
    warn "JMAP DOWNLOAD @_ " . Dumper($Response);
  }

  return $Response;
}

1;
__END__

=head1 ENVIRONMENT

If the environment variable DEBUGJMAP is set to a true value, all API requests
and responses plus Upload responses will be warn()ed.

=head1 SEE ALSO

https://jmap.io/ - protocol documentation and client guide.

=head1 AUTHOR

Bron Gondwana, E<lt>brong@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2020 by Fastmail Pty Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
