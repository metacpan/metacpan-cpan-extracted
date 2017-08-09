#!/usr/bin/perl -cw

use strict;
use warnings;

package Mail::JMAPTalk;

use HTTP::Tiny;
use JSON::XS qw(decode_json encode_json);
use Convert::Base64;
use File::LibMagic;
use Carp qw(confess);
use Data::Dumper;

our $VERSION = '0.08';

our $CLIENT = "Net-JMAPTalk";
our $AGENT = "$CLIENT/$VERSION";

sub new {
  my ($Proto, %Args) = @_;
  my $Class = ref($Proto) || $Proto;

  my $Self = bless { %Args }, $Class;

  return $Self;
}

sub ua {
  my $Self = shift;
  unless ($Self->{ua}) {
    $Self->{ua} = HTTP::Tiny->new(agent => $AGENT);
  }
  return $Self->{ua};
}

sub auth_header {
  my $Self = shift;
  return 'Basic ' . encode_base64("$Self->{user}:$Self->{password}", '');
}

sub authuri {
  my $Self = shift;
  my $scheme = $Self->{scheme} // 'http';
  my $host = $Self->{host} // 'localhost';
  my $port = $Self->{port} // ($scheme eq 'http' ? 80 : 443);
  my $url = $Self->{authurl} // '/jmap/auth/';

  return $url if $url =~ m/^http/;

  return "$scheme://$host:$port$url";
}

sub uploaduri {
  my $Self = shift;
  my $scheme = $Self->{scheme} // 'http';
  my $host = $Self->{host} // 'localhost';
  my $port = $Self->{port} // ($scheme eq 'http' ? 80 : 443);
  my $url = $Self->{uploadurl} // '/jmap/upload/';

  return $url if $url =~ m/^http/;

  return "$scheme://$host:$port$url";
}

sub downloaduri {
  my $Self = shift;
  my ($accountId, $blobId, $name) = @_;
  die "need account and blob" unless ($accountId and $blobId);
  $name ||= "download";
  my $scheme = $Self->{scheme} // 'http';
  my $host = $Self->{host} // 'localhost';
  my $port = $Self->{port} // ($scheme eq 'http' ? 80 : 443);
  my $url = $Self->{downloadurl} // '/jmap/download/{accountId}/{blobId}/{name}';

  my %map = (
    accountId => $accountId,
    blobId => $blobId,
    name => $name,
  );

  $url =~ s/\{([a-zA-Z0-9_]+)\}/$map{$1}||''/ges;

  return $url if $url =~ m/^http/;

  return "$scheme://$host:$port$url";
}

sub uri {
  my $Self = shift;
  my $scheme = $Self->{scheme} // 'http';
  my $host = $Self->{host} // 'localhost';
  my $port = $Self->{port} // ($scheme eq 'http' ? 80 : 443);
  my $url = $Self->{url} // '/jmap/';

  return $url if $url =~ m/^http/;

  return "$scheme://$host:$port$url";
}

sub AuthRequest {
  my ($Self, $Requests, %Headers) = @_;

  $Headers{'Content-Type'} //= "application/json";
  $Headers{'Accept'} //= "application/json";

  my $uri = $Self->authuri();

  my $Response = $Self->ua->post($uri, {
    headers => \%Headers,
    content => encode_json($Requests),
  });

  my $jdata;
  $jdata = eval { decode_json($Response->{content}) } if $Response->{success};

  if ($ENV{DEBUGJMAP}) {
    warn "JMAP " . Dumper($Requests, $Response);
  }

  # check your own success on the Response object
  if (wantarray) {
    return ($Response, $jdata);
  }

  confess "JMAP request for $Self->{user} failed ($uri): $Response->{status} $Response->{reason}: $Response->{content}"
    unless $Response->{success};

  confess "INVALID JSON $Response->{content}" unless $jdata;

  return $jdata;
}

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
  $Self->{upload} = $data->{upload};
  $Self->{eventSource} = $data->{eventSource};

  return 1;
}

sub Request {
  my ($Self, $Requests, %Headers) = @_;

  $Headers{'Content-Type'} //= "application/json";

  if ($Self->{user}) {
    $Headers{'Authorization'} = $Self->auth_header();
  }
  if ($Self->{token}) {
    $Headers{'Authorization'} = "Bearer $Self->{token}";
  }

  my $uri = $Self->uri();

  my $Response = $Self->ua->post($uri, {
    headers => \%Headers,
    content => encode_json($Requests),
  });

  my $jdata;
  $jdata = eval { decode_json($Response->{content}) } if $Response->{success};

  if ($ENV{DEBUGJMAP}) {
    warn "JMAP " . Dumper($Requests, $Response);
  }

  # check your own success on the Response object
  if (wantarray) {
    return ($Response, $jdata);
  }

  confess "JMAP request for $Self->{user} failed ($uri): $Response->{status} $Response->{reason}: $Response->{content}"
    unless $Response->{success};

  confess "INVALID JSON $Response->{content}" unless $jdata;

  return $jdata;
}

sub _get_type {
  my $data = shift;
  # XXX - escape file names?
  my $magic = File::LibMagic->new();
  my $info = $magic->info_from_string($data);
  return $info->{mime_type};
}

sub Upload {
  my ($Self, $data, $type, $accountId) = @_;

  my %Headers;
  $Headers{'Content-Type'} = $type || _get_type($data);

  if (defined $accountId) {
      $Headers{'X-JMAP-AccountId'} = $accountId;
  }
  if ($Self->{user}) {
    $Headers{'Authorization'} = $Self->auth_header();
  }
  if ($Self->{token}) {
    $Headers{'Authorization'} = "Bearer $Self->{token}";
  }

  my $uri = $Self->uploaduri();

  my $Response = $Self->ua->post($uri, {
    headers => \%Headers,
    content => $data,
  });

  if ($ENV{DEBUGJMAP}) {
    warn "JMAP UPLOAD " . Dumper($Response);
  }

  my $jdata;
  $jdata = eval { decode_json($Response->{content}) } if $Response->{success};

  # check your own success on the Response object
  if (wantarray) {
    return ($Response, $jdata);
  }

  confess "JMAP request for $Self->{user} failed ($uri): $Response->{status} $Response->{reason}: $Response->{content}"
    unless $Response->{success};

  confess "INVALID JSON $Response->{content}" unless $jdata;

  return $jdata;
}

sub Download {
  my $Self = shift;
  my $cb;
  if (ref($_[0]) eq 'CODE') {
    $cb = shift;
  }
  my $uri = $Self->downloaduri(@_);

  my %Headers;
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

  die "Failed to download $uri" unless $Response->{success};
  return $Response;
}

1;
__END__

=head1 NAME

Mail::JMAPTalk - Perl client for the http://jmap.io/ protocol

=head1 SYNOPSIS

    use Mail::JMAPTalk;

    my $Talk = Mail::JMAPTalk->new(url => $url);

    my $res = $jmap->Request([['setContacts', {
       create => {
           "#1" => {firstName => "first", lastName => "last"},
           "#2" => {firstName => "second", lastName => "last"},
       }}, "R1"]]);
    # [["contactsSet", {created => { "#1" => {...}, "#2" => {...} } }, "R1"]]

=head1 DESCRIPTION

This is a really basic wrapper around the JMAP protocol.  It has a
rudimentary "Login" command as well, but it doesn't support the
entire protocol yet.


=head1 SEE ALSO

http://jmap.io/ - protocol documentation and client guide.

=head1 AUTHOR

Bron Gondwana, E<lt>brong@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by FastMail Pty Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
