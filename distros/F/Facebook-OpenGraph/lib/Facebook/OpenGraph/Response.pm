package Facebook::OpenGraph::Response;
use strict;
use warnings;
use 5.008001;

use Carp qw(croak);
use JSON 2 ();

sub new {
    my $class = shift;
    my $args  = shift || +{};

    return bless +{
        json        => $args->{json} || JSON->new->utf8,
        headers     => $args->{headers},
        code        => $args->{code},
        message     => $args->{message},
        content     => $args->{content},
        req_headers => $args->{req_headers} || q{},
        req_content => $args->{req_content} || q{},
    }, $class;
}

# accessors
sub code        { shift->{code}         }
sub headers     { shift->{headers}      }
sub message     { shift->{message}      }
sub content     { shift->{content}      }
sub req_headers { shift->{req_headers}  }
sub req_content { shift->{req_content}  }
sub json        { shift->{json}         }
sub etag        { shift->header('etag') }

sub api_version {
    my $self = shift;
    return $self->header('facebook-api-version');
}

sub is_api_version_eq_or_later_than {
    my ($self, $comparing_version) = @_;
    croak 'comparing version is not given.' unless $comparing_version;

    (my $comp_major, my $comp_minor)
        = $comparing_version =~ m/ (\d+) \. (\d+ )/x;

    (my $response_major, my $response_minor)
        = $self->api_version =~ m/ (\d+) \. (\d+ )/x;

    return $comp_major < $response_major || ($comp_major == $response_major && $comp_minor <= $response_minor);
}

sub is_api_version_eq_or_older_than {
    my ($self, $comparing_version) = @_;
    croak 'comparing version is not given.' unless $comparing_version;

    (my $comp_major, my $comp_minor)
        = $comparing_version =~ m/ (\d+) \. (\d+ )/x;

    (my $response_major, my $response_minor)
        = $self->api_version =~ m/ (\d+) \. (\d+ )/x;

    return $response_major < $comp_major || ($response_major == $comp_major && $response_minor <= $comp_minor);
}

sub header {
    my ($self, $key) = @_;

    croak 'header field name is not given' unless $key;

    $self->{header} ||= do {
        my $ref = +{};

        while (my ($k, $v) = splice @{ $self->headers }, 0, 2) {
            $ref->{$k} = $v;
        }

        $ref;
    };

    return $self->{header}->{$key};
}

sub is_success {
    my $self = shift;
    # code 2XX or 304
    # 304 is returned when you use ETag and the data is not changed
    return substr($self->code, 0, 1) == 2 || $self->code == 304;
}

# Using the Graph API > Handling Errors
# https://developers.facebook.com/docs/graph-api/using-graph-api/
sub error_string {
    my $self = shift;

    # When error occurs, response should be given in a form of below:
    #{
    #  "error": {
    #    "message": "Message describing the error",
    #    "type": "OAuthException",
    #    "code": 190 ,
    #    "error_subcode": 460
    #  }
    #}
    my $error = eval { $self->as_hashref->{error}; };

    my $err_str = q{};
    if ($@ || !$error) {
        $err_str = $self->message;
    }
    else {
        # sometimes error_subcode is not given
        $err_str = sprintf(
                        '%s:%s %s:%s',
                        $error->{code},
                        $error->{error_subcode} || '-',
                        $error->{type},
                        $error->{message},
                   );
    }

    return $err_str;
}

sub as_json {
    my $self = shift;

    my $content = $self->content;
    if ($content =~ m{\A (true|false) \z}xms) {
        # On v2.0 and older version, some endpoints return plain text saying
        # 'true' or 'false' to indicate result, so make it JSON formatted for
        # our convinience. The key is named "success" so its format matches with
        # other endpoints that return {"success": "(true|false)"}.
        # From v2.1 they always return in form of {"success": "(true|false)"}.
        # See https://developers.facebook.com/docs/apps/changelog#v2_1_changes
        $content = sprintf('{"success" : "%s"}', $1);
    };

    return $content; # content is JSON formatted
}

sub as_hashref {
    my $self = shift;
    # just in case content is not properly formatted
    my $hash_ref = eval { $self->json->decode( $self->as_json ); };
    croak $@ if $@;
    return $hash_ref;
}

# Indicates whether the data is modified.
# It should be used when you request with ETag.
# https://developers.facebook.com/docs/reference/ads-api/etags-reference/
sub is_modified {
    my $self = shift;
    my $not_modified = $self->code == 304  &&  $self->message eq 'Not Modified';
    return !$not_modified;
}

1;
__END__

=head1 NAME

Facebook::OpenGraph::Response - Response object for Facebook::OpenGraph.

=head1 SYNOPSIS

  my $res = Facebook::OpenGraph::Response->new(+{
      code        => $http_status_code,
      message     => $http_status_message,
      headers     => $response_headers,
      content     => $response_content,
      req_headers => $req_headers,
      req_content => $req_content,
      json        => JSON->new->utf8,
  });

=head1 DESCRIPTION

This handles response object for Facebook::OpenGraph.

=head1 METHODS

=head2 Class Methods

=head3 C<< Facebook::OpenGraph::Response->new(\%args) >>

Creates and returns a new Facebook::OpenGraph::Response object.

I<%args> can contain...

=over 4

=item * code

HTTP status code

=item * message

HTTP status message

=item * headers

Response headers

=item * content

Response body

=item * req_headers

Stringified request headers

=item * req_content

Request content

=item * json

JSON object

=back

=head2 Instance Methods

=head3 C<< $res->code >>

Returns HTTP status code

=head3 C<< $res->message >>

Returns HTTP status message

=head3 C<< $res->content >>

Returns response body

=head3 C<< $res->req_headers >>

Returns request header. This is especially useful for debugging. You must
install later version of Furl to enable this or otherwise empty string will be
returned. Also you have to specify Furl::HTTP->new(capture_request => 1) option.

=head3 C<< $res->req_content >>

Returns request body. This is especially useful for debugging. You must install
later version of Furl to enable this or otherwise empty string will be returned.
Also you have to specify Furl::HTTP->new(capture_request => 1) option.

=head3 C<< $res->etag >>

Returns ETag value that is given as a part of response headers.

=head3 C<< $res->header($field_name) >>

Returns specified header field value.

  my $res  = $fb->request('GET', 'go.hagiwara');
  my $etag = $res->header('etag'); # "a376a57cb3a4bd3a3c6a53fca06b0fd5badee50b"

=head3 C<< $res->api_version >>

By checking facebook-api-version header value, it returns API version that
current API call actually experienced. This may differ from the one you
specified. See
L<https://developers.facebook.com/docs/apps/changelog#v2_1>

=head3 C<< $res->is_api_version_eq_or_older_than($comparing_version) >>

Compare $comparing_version with the facebook-api-version header value and
returns TRUE when facebook-api-version is older than the given version.

=head3 C<< $res->is_api_version_eq_or_later_than($comparing_version) >>

Compare $comparing_version with the facebook-api-version header value and
returns TRUE when facebook-api-version is newer than the given version.

=head3 C<< $res->is_success >>

Returns if status is 2XX or 304. 304 is added to handle $fb->fetch_with_etag();

=head3 C<< $res->error_string >>

Returns error string.

=head3 C<< $res->as_json >>

Returns response content as JSON string. Most of the time the response content
itself is JSON formatted so it basically returns response content without doing
anything. When Graph API returns plain text just saying 'true' or 'false,' it
turns the content into JSON format like '{"success" : "(true|false)"}' so you
can handle it in the same way as other cases.

=head3 C<< $res->as_hashref >>

Returns response content in hash reference.

=head3 C<< $res->is_modified >>

Returns if target object is modified. This method is called in
$fb->fetch_with_etag().
