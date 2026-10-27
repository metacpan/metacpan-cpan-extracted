# ABSTRACT: turn WGS84 coordinates into three word addresses and vice-versa using what3words.com HTTPS API

use strict;
use warnings;

package Geo::What3Words;
$Geo::What3Words::VERSION = '3.0.6';
use Cpanel::JSON::XS;
use Encode qw( decode_utf8 );
use HTTP::Tiny;
use Ref::Util qw( is_hashref is_coderef );
use utf8;

my $JSONXS = Cpanel::JSON::XS->new->utf8->allow_nonref(1);




sub new {
    my ($class, %params) = @_;

    my $self = {};
    $self->{api_endpoint} = $params{api_endpoint} || 'https://api.what3words.com/v3/';
    $self->{key}          = $params{key}          || die "API key not set";
    $self->{language}     = $params{language};
    $self->{logging}      = $params{logging};

    ## _ua is used for testing. But could also be used to
    ## set proxies or such
    $self->{ua} = $params{ua} || HTTP::Tiny->new;

    my $version = $Geo::What3Words::VERSION || '';
    $self->{ua}->agent("Perl Geo::What3Words $version");

    return bless($self, $class);
}


sub ping {
    my $self = shift;

    my $host = _host_from_url($self->{api_endpoint});

    $self->_log("pinging $host...");

    ## loaded here so the rest of the module works without them,
    ## Net::Ping loads Net::Ping::External itself
    require Net::Ping;
    my $netping = Net::Ping->new('external');
    my $res     = $netping->ping($host);

    $self->_log($res ? 'available' : 'unavailable');

    return $res;
}


sub words2pos {
    my ($self, @params) = @_;

    my $res = $self->words_to_position(@params);
    if ($res && is_hashref($res) && exists($res->{coordinates})) {
        return $res->{coordinates}->{lat} . ',' . $res->{coordinates}->{lng};
    }
    return;
}



sub pos2words {
    my ($self, @params) = @_;
    my $res = $self->position_to_words(@params);
    if ($res && is_hashref($res) && exists($res->{words})) {
        return $res->{words};
    }
    return;
}


sub valid_words_format {
    my $self  = shift;
    my $words = shift;

    ## Translating the PHP regular expression w3w uses in their
    ## documentation
    ## http://perldoc.perl.org/perlunicode.html#Unicode-Character-Properties
    ## http://php.net/manual/en/reference.pcre.pattern.differences.php
    return 0 unless $words;
    return 1 if ($words =~ m/^(\p{Lower}+)\.(\p{Lower}+)\.(\p{Lower}+)$/);
    return 0;
}


sub words_to_position {
    my $self  = shift;
    my $words = shift;

    ## save a round trip for input the API would reject anyway. More
    ## lenient than valid_words_format so we never reject something
    ## the API might accept
    if (!defined($words) || $words !~ m/^[^.\s]+\.[^.\s]+\.[^.\s]+$/) {
        return $self->_invalid_input('BadWords', '3 word address', $words);
    }

    return $self->_query_remote_api('convert-to-coordinates', {words => $words});

}


sub position_to_words {
    my $self     = shift;
    my $position = shift;
    my $language = shift || $self->{language};

    if (!_valid_position($position)) {
        return $self->_invalid_input('BadCoordinates', 'coordinates', $position);
    }

    # https://developer.what3words.com/public-api/docs#convert-to-3wa
    return $self->_query_remote_api(
        'convert-to-3wa',
        {   coordinates => $position,
            language    => $language
        }
    );
}


sub get_languages {
    my $self = shift;
    return $self->_query_remote_api('available-languages');
}


sub error {
    my $self = shift;
    return $self->{error};
}


sub oneword_available {
    warn 'deprecated method: oneword_available';
    return;
}

sub _query_remote_api {
    my $self        = shift;
    my $method_name = shift;
    my $rh_params   = shift || {};

    $self->{error} = undef;

    my $rh_fields = {
        #a      => 1,
        key    => $self->{key},
        format => 'json',
        %$rh_params
    };

    foreach my $key (keys %$rh_fields) {
        delete $rh_fields->{$key} if (!defined($rh_fields->{$key}));
    }

    ## class method, $self->{ua} might not be an HTTP::Tiny
    my $url = $self->{api_endpoint} . $method_name . '?' . HTTP::Tiny->www_form_urlencode($rh_fields);

    ## never show the API key in warnings or logs
    (my $safe_url = $url) =~ s/([?&]key=)[^&]*/${1}XXXX/;

    $self->_log("GET $safe_url");
    my $response = $self->{ua}->get($url);

    if (!$response->{success}) {
        warn "got failed response from $safe_url: " . $response->{status};
        $self->_log("got failed response from $safe_url: " . $response->{status});
        $self->{error} = _error_from_response($response);
        return;
    }

    ## the JSON decoder expects UTF-8 bytes, only decode for logging
    my $json = $response->{content};
    $self->_log(decode_utf8($json)) if $self->{logging};

    return $JSONXS->decode($json);
}

## 'lat,lng' with lat in -90..90 and lng in -180..180
sub _valid_position {
    my $position = shift;
    return 0 unless defined $position;

    my $num = qr/[-+]?(?:\d+(?:\.\d*)?|\.\d+)/;
    return 0 unless ($position =~ m/^\s*($num)\s*,\s*($num)\s*$/);
    my ($lat, $lng) = ($1, $2);
    return 0 if ($lat < -90 || $lat > 90 || $lng < -180 || $lng > 180);
    return 1;
}

## the API sends errors as {"error":{"code":...,"message":...}}, but
## e.g. connection failures (status 599) come from HTTP::Tiny as text
sub _error_from_response {
    my $response = shift;

    my $error = {status => $response->{status}, code => undef, message => $response->{reason}};

    my $body = eval { $JSONXS->decode($response->{content}) };
    if (is_hashref($body) && is_hashref($body->{error})) {
        $error->{code}    = $body->{error}->{code};
        $error->{message} = $body->{error}->{message};
    } elsif ($response->{status} == 599 && defined($response->{content})) {
        $error->{message} = $response->{content};
    }
    return $error;
}

sub _invalid_input {
    my $self  = shift;
    my $code  = shift;
    my $what  = shift;
    my $input = shift;

    my $msg = "invalid $what: " . (defined($input) ? "'$input'" : 'undef') . ', not calling API';
    $self->{error} = {status => undef, code => $code, message => $msg};
    warn $msg;
    $self->_log($msg);
    return;
}

## http://example.com/some/path => example.com
## also works with IP addresses, [::1] => ::1
sub _host_from_url {
    my $url = shift;
    return unless defined $url;
    if ($url =~ m{^[a-z][a-z0-9+.-]*://(?:[^@/?#]*@)?(?:\[([^\]]+)\]|([^:/?#]+))}i) {
        return defined($1) ? $1 : $2;
    }
    return;
}

sub _log {
    my $self    = shift;
    my $message = shift;
    return unless $self->{logging};

    if (is_coderef($self->{logging})) {
        my $lc = $self->{logging};
        &$lc("Geo::What3Words -- " . $message);
    } else {
        print "Geo::What3Words -- " . $message . "\n";
    }
    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geo::What3Words - turn WGS84 coordinates into three word addresses and vice-versa using what3words.com HTTPS API

=head1 VERSION

version 3.0.6

=head1 SYNOPSIS

  my $w3w = Geo::What3Words->new( key => 'your-api-key' );

  $w3w->pos2words('51.484463,-0.195405');
  # returns 'prom.cape.pump'

  $w3w->pos2words('51.484463,-0.195405', 'ru');
  # returns 'питомец.шутить.намеренно'

  $w3w->words2pos('prom.cape.pump');
  # returns '51.484463,-0.195405' (latitude,longitude)

=head1 DESCRIPTION

what3words (L<https://what3words.com/>) divides the world into 57 trillion
squares of 3 metres x 3 metres. Each square has been given a 3 word address
comprised of 3 words from the dictionary.

This module calls API version 3 (L<https://docs.what3words.com/public-api/>)
to convert coordinates into 3 word addresses (forward) and 3
words into coordinates (reverse).

Versions 1 and 2 are deprecated and are no longer supported.

You need to sign up at L<https://what3words.com/login> and then register for
an API key at L<https://developer.what3words.com>

=head1 METHODS

=head2 new

Creates a new instance. The C<key> parameter is required.

  my $w3w = Geo::What3Words->new( key => 'your-api-key' );
  my $w3w = Geo::What3Words->new( key => 'your-api-key', language => 'ru' );

Options:

=over 4

=item key (required)

Your what3words API key.

=item language

Default language for 3 word addresses (e.g. C<'ru'>, C<'de'>). Can be
overridden per request.

=item api_endpoint

Override the API URL. Defaults to C<https://api.what3words.com/v3/>.
Useful when testing self-hosted installations.

Warning: Set the value carefully, and not from user-supplied data,
otherwise all data including the API key could be sent to an untrusted
endpoint.

=item ua

Provide your own L<HTTP::Tiny> instance, e.g. for proxy configuration
or testing.

=item logging

For debugging you can either set logging to a true value or provide a
callback.

  my $w3w = Geo::What3Words->new( key => 'your-api-key', logging => 1 );
  # will print debugging output to STDOUT

  my $callback = sub { my $msg = shift; $my_log4perl_logger->info($msg) };
  my $w3w = Geo::What3Words->new( key => 'your-api-key', logging => $callback );
  # will log with log4perl

=back

Create one instance and reuse it for all your requests. L<HTTP::Tiny>
keeps the connection to the API open between requests, so only the
first request pays for the TLS handshake. Creating a new instance per
request loses that.

=head2 ping

Check if the remote server is available. This is helpful for debugging or
testing, but too slow to run for every conversion.

  $w3w->ping();

=head2 words2pos

Convenience wrapper around C<words_to_position>. Takes a 3 word address
string, returns a string C<'latitude,longitude'> or C<undef> on failure.

  $w3w->words2pos('prom.cape.pump');
  # returns '51.484463,-0.195405'

  $w3w->words2pos('does.not.exist');
  # returns undef

=head2 pos2words

Convenience wrapper around C<position_to_words>. Takes a string
C<'latitude,longitude'> and an optional language code. Returns a 3 word
address string or C<undef> on failure.

  $w3w->pos2words('51.484463,-0.195405');
  # returns 'prom.cape.pump'

  $w3w->pos2words('51.484463,-0.195405', 'ru');
  # returns 'питомец.шутить.намеренно'

  $w3w->pos2words('invalid,coords');
  # returns undef

=head2 valid_words_format

Returns 1 if the string looks like three dot-separated words, 0 otherwise.
Supports Unicode (e.g. Cyrillic, Turkish). Does not call the remote API.

  $w3w->valid_words_format('prom.cape.pump');
  # returns 1

  $w3w->valid_words_format('диета.новшество.компаньон');
  # returns 1

  $w3w->valid_words_format('Not.Valid.Format');
  # returns 0 (uppercase letters)

=head2 words_to_position

Takes a 3 word address string and returns a hashref with coordinates,
country, language, map link, nearest place, and bounding square.
Returns C<undef> on failure.

  $w3w->words_to_position('prom.cape.pump');
  # {
  #        'coordinates' => {
  #                           'lat' => '51.484463',
  #                           'lng' => '-0.195405'
  #                         },
  #        'country' => 'GB',
  #        'language' => 'en',
  #        'map' => 'https://w3w.co/prom.cape.pump',
  #        'nearestPlace' => 'Kensington, London',
  #        'square' => {
  #                      'northeast' => {
  #                                       'lat' => '51.484476',
  #                                       'lng' => '-0.195383'
  #                                     },
  #                      'southwest' => {
  #                                       'lat' => '51.484449',
  #                                       'lng' => '-0.195426'
  #                                     }
  #                    },
  #        'words' => 'prom.cape.pump'
  #      };

=head2 position_to_words

Takes a string C<'latitude,longitude'> and an optional language code.
Returns a hashref with coordinates, country, language, map link, nearest
place, and bounding square. Returns C<undef> on failure.

  $w3w->position_to_words('51.484463,-0.195405');
  $w3w->position_to_words('51.484463,-0.195405', 'ru');

  # {
  #        'coordinates' => {
  #                           'lat' => '51.484463',
  #                           'lng' => '-0.195405'
  #                         },
  #        'country' => 'GB',
  #        'language' => 'en',
  #        'map' => 'https://w3w.co/prom.cape.pump',
  #        'nearestPlace' => 'Kensington, London',
  #        'square' => {
  #                      'northeast' => {
  #                                       'lat' => '51.484476',
  #                                       'lng' => '-0.195383'
  #                                     },
  #                      'southwest' => {
  #                                       'lat' => '51.484449',
  #                                       'lng' => '-0.195426'
  #                                     }
  #                    },
  #        'words' => 'prom.cape.pump'
  #      };

=head2 get_languages

Returns a hashref containing a list of supported language codes and names.

  $w3w->get_languages();
  # {
  #     'languages' => [
  #                      {
  #                        'name' => 'German',
  #                        'nativeName' => 'Deutsch',
  #                        'code' => 'de'
  #                      },
  #                      {
  #                        'name' => 'English',
  #                        'nativeName' => 'English',
  #                        'code' => 'en'
  #                      },
  #                      {
  #                        'name' => "Spanish",
  #                        'nativeName' => "Español",
  #                        'code' => 'es'
  #                      },
  # ...

=head2 error

Returns details about why the last conversion or C<get_languages> call
failed, or C<undef> if it succeeded.

  my $words = $w3w->pos2words('51.484463,-0.195405');
  if (!defined($words)) {
      my $error = $w3w->error;
      # {
      #   status  => 401,
      #   code    => 'InvalidKey',
      #   message => 'Authentication failed; invalid API key'
      # }
  }

C<status> is the HTTP status code. C<code> and C<message> come from the
API, see L<https://developer.what3words.com/public-api/docs>.

If the input was rejected before calling the API C<status> is C<undef>
and C<code> is C<BadWords> or C<BadCoordinates>. If the API could not be
reached C<status> is C<599>, C<code> is C<undef> and C<message> is the
error from L<HTTP::Tiny>.

=head2 oneword_available

Deprecated. Calling this method will emit a warning and return C<undef>.

=head1 ERROR HANDLING

On HTTP errors or invalid input the convenience methods (C<pos2words>,
C<words2pos>) return C<undef>. The verbose methods (C<position_to_words>,
C<words_to_position>, C<get_languages>) also return C<undef> on failure.

In all cases a warning is emitted via C<warn> with the HTTP status code.
You can catch these with C<$SIG{__WARN__}> or L<Test::Warn> in tests.

C<error> returns the details of the last failure, including the error
code and message from the API.

Input that is clearly invalid is rejected before calling the API, also
with a warning: a 3 word address that isn't three dot-separated words,
or coordinates that aren't C<'latitude,longitude'> with latitude between
-90 and 90 and longitude between -180 and 180.

=head1 TESTING

The test suite uses pre-recorded API responses. If you suspect something
changed in the API you can force the test suite to use live requests with
your API key:

    W3W_API_KEY=<your key> prove -l t/base.t

The recorded responses are in F<t/data/responses>. To update them, run
the tests against the live API with recording switched on. Your API key
is not saved in the recorded responses.

    W3W_API_KEY=<your key> W3W_RECORD=1 prove -l t/base.t

Set C<W3W_API_ENDPOINT> to run the live or recording tests against
another server, e.g. a self-hosted installation.

The code style tests only run with C<AUTHOR_TESTING> set, as
C<dzil test --author> does.

=head1 SEE ALSO

L<https://what3words.com/> - what3words website

L<https://developer.what3words.com> - API documentation and key registration

L<https://developer.what3words.com/public-api/docs> - API v3 reference

=head1 AUTHOR

mtmail <mtmail-cpan@gmx.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by OpenCage GmbH.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
