package HTTP::API::Core::Auth;

use strict;
use warnings;
use Exporter 'import';
use MIME::Base64 qw(encode_base64);

our @EXPORT_OK = qw(bearer_auth basic_auth api_key_auth);

sub bearer_auth {
    my ($token) = @_;
    die "bearer token must be a non-empty scalar\n"
        if !defined($token) || ref($token) || $token eq '';

    return sub {
        my ($ctx) = @_;
        _set_header_if_absent($ctx->{headers}, 'Authorization', "Bearer $token");
    };
}

sub basic_auth {
    my ($username, $password) = @_;
    die "basic auth username is required\n" if !defined($username) || ref($username);
    die "basic auth password is required\n" if !defined($password) || ref($password);

    my $credentials = encode_base64("$username:$password", '');
    return sub {
        my ($ctx) = @_;
        _set_header_if_absent($ctx->{headers}, 'Authorization', "Basic $credentials");
    };
}

sub api_key_auth {
    my (%args) = @_;
    my $in = delete($args{in}) // 'header';
    my $name = delete $args{name};
    my $value = delete $args{value};
    die "unknown api_key auth option: $_\n" for sort keys %args;

    die "api_key in must be header or query\n" if $in ne 'header' && $in ne 'query';
    die "api_key name must be a non-empty scalar\n"
        if !defined($name) || ref($name) || $name eq '';
    die "api_key value must be a scalar\n" if !defined($value) || ref($value);

    if ($in eq 'header') {
        return sub {
            my ($ctx) = @_;
            _set_header_if_absent($ctx->{headers}, $name, "$value");
        };
    }

    return sub {
        my ($ctx) = @_;
        my $url = $ctx->{url};
        return if $url =~ /(?:[?&])\Q$name\E=/;
        my $separator = index($url, '?') >= 0 ? '&' : '?';
        $ctx->{url} = $url . $separator . _uri_escape($name) . '=' . _uri_escape($value);
    };
}

sub _set_header_if_absent {
    my ($headers, $name, $value) = @_;
    my $wanted = lc $name;
    return if grep { lc($_) eq $wanted } keys %$headers;
    $headers->{$name} = $value;
}

sub _uri_escape {
    my ($value) = @_;
    my $bytes = "$value";
    utf8::encode($bytes) if utf8::is_utf8($bytes);
    $bytes =~ s/([^A-Za-z0-9\-._~])/sprintf('%%%02X', ord($1))/ge;
    return $bytes;
}

1;

__END__

=head1 NAME

HTTP::API::Core::Auth - Small authentication helpers for HTTP::API::Core

=head1 SYNOPSIS

  use HTTP::API::Core;
  use HTTP::API::Core::Auth qw(bearer_auth);

  my $api = HTTP::API::Core->new(
      base_url => 'https://api.example.com',
      hooks => {
          before_request => bearer_auth($token),
      },
  );

=head1 DESCRIPTION

This module provides small lifecycle-hook helpers for common API authentication
schemes. It deliberately builds on HTTP::API::Core's existing hook mechanism
instead of adding OAuth flows or service-specific authentication behavior to
the client core.

=head1 FUNCTIONS

=head2 bearer_auth($token)

Returns a C<before_request> hook that adds an Authorization Bearer header unless
an Authorization header is already present.

=head2 basic_auth($username, $password)

Returns a C<before_request> hook that adds an HTTP Basic Authorization header.

=head2 api_key_auth(name => ..., value => ..., in => 'header'|'query')

Returns a C<before_request> hook for API-key authentication. C<in> defaults to
C<header>. Explicit request headers or an existing query parameter take
precedence over the helper.

OAuth token acquisition and refresh are intentionally outside this module's
scope.

=cut
