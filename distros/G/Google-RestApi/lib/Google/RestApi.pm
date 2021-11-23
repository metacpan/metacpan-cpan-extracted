package Google::RestApi;

our $VERSION = '0.9';

use Google::RestApi::Setup;

use File::Basename qw( dirname );
use Furl ();
use JSON::MaybeXS qw( decode_json encode_json JSON );
use List::Util ();
use Log::Log4perl qw( get_logger );
use Module::Load qw( load );
use Scalar::Util qw( blessed );
use Retry::Backoff qw( retry );
use Storable qw( dclone );
use Time::Out qw( timeout );
use Try::Tiny qw( catch try );
use URI ();
use URI::QueryParam ();

sub new {
  my $class = shift;

  my $self = merge_config_file(@_);
  state $check = compile_named(
    config_file  => ReadableFile, { optional => 1 },
    auth         => HashRef | Object,
    throttle     => PositiveOrZeroInt, { default => 0 },
    timeout      => Int, { default => 120 },
    max_attempts => PositiveInt->where(sub { $_ < 10; }), { default => 4 },
  );
  $self = $check->(%$self);

  $self->{ua} = Furl->new(timeout => $self->{timeout});

  return bless $self, $class;
}

sub api {
  my $self = shift;

  state $check = compile_named(
    uri     => StrMatch[qr(^https://)],
    method  => StrMatch[qr/^(get|head|put|patch|post|delete)$/i], { default => 'get' },
    params  => HashRef[Str|ArrayRef[Str]], { default => {} },
    headers => ArrayRef[Str], { default => [] },
    content => 0,
  );
  my $request = $check->(@_);

  # reset our transaction for this new one.
  $self->{transaction} = {};

  $self->_stat( $request->{method}, 'total' );
  $request->{method} = uc($request->{method});
  $request->{caller_internal} = _caller_internal();
  $request->{caller_external} = _caller_external();

  my $request_content = $request->{content};
  my $request_json = defined $request_content ? encode_json($request_content) : (),

  my @headers;
  push(@headers, 'Content-Type' => 'application/json') if $request_json;
  push(@headers, @{ $request->{headers} });
  push(@headers, @{ $self->auth()->headers() });

  # some (outdated) auth mechanisms may allow auth info in the params.
  my %params = (%{ $request->{params} }, %{ $self->auth()->params() });
  my $uri = URI->new($request->{uri});
  $uri->query_form_hash(\%params);
  $request->{uri} = $uri->as_string();
  DEBUG("Rest API request:\n", Dump($request));

  my $req = HTTP::Request->new(
    $request->{method}, $request->{uri}, \@headers, $request_json
  );
  my ($response, $tries, $last_error) = $self->_api($req);
  $self->{transaction} = {
    request => $request,
    tries   => $tries,
    ($response   ? (response => $response)   : ()),
    ($last_error ? (error    => $last_error) : ()),
  };

  if ($response) {
    my $decoded_response = $response->decoded_content();
    $decoded_response = $decoded_response ? decode_json($decoded_response) : 1;
    $self->{transaction}->{decoded_response} = $decoded_response;
    DEBUG("Rest API response:\n", Dump( $decoded_response ));
  }

  $self->_api_callback();

  # this is for capturing request/responses for unit tests. copy/paste the results
  # in the log into t/etc/uri_responses for unit testing. log appender 'UnitTestCapture'
  # is defined in t/etc/log4perl.conf. you can use this logger by pointing to it via
  # GOOGLE_RESTAPI_LOGGER env var.
  if ($response && Log::Log4perl::appenders->{'UnitTestCapture'}) {
    # special log category for this. it should be tied to the UnitTestCapture appender.
    # we want to dump this in the same format as what we need to store in
    # t/etc/uri_responses.
    my %request_response;
    my $json = JSON->new->ascii->pretty->canonical;
    my $pretty_request_json = $request_json ?
      $json->encode(decode_json($request_json)) : '';
    my $pretty_response_json = $response->content() ?
      $json->encode(decode_json($response->content())) : '';
    $request_response{ $request->{method} } = {
      $request->{uri} => {
        ($pretty_request_json) ? (content  => $pretty_request_json) : (),
        response => $pretty_response_json,
      },
    };
    get_logger('unit.test.capture')->info(Dump(\%request_response) . "\n\n");
  }

  if (!$response || !$response->is_success()) {
    $self->_stat('error');
    LOGDIE("Rest API failure:\n", Dump( $self->transaction() ));
  }

  # used for to avoid google 403's and 429's as with integration tests.
  sleep($self->{throttle}) if $self->{throttle};

  return $self->{transaction}->{decoded_response};
}

sub _api {
  my ($self, $req) = @_;

  # default is exponential backoff, initial delay 1.
  my $tries = 0;
  my $last_error;
  my $response = retry
    sub {
      # timeout is in the ua too, but i've seen requests to spreadsheets
      # completely hang if the request isn't constructed correctly.
      timeout $self->{timeout} => sub { $self->{ua}->request($req); };
    },
    retry_if => sub {
      my $h = shift;
      my $r = $h->{attempt_result};   # Furl::Response
      if (!$r) {
        $last_error = $@ || "Unknown error";
        WARN("API call error: $last_error");
        return 1;
      }
      $last_error = $r->status_line() if !$r->is_success();
      if ($r->code() =~ /^(403|429|50[0234])$/) {
        WARN("Retrying: $last_error");
        return 1;
      }
      return; # we're accepting the response.
    },
    on_success   => sub { $tries++; },
    on_failure   => sub { $tries++; },
    max_attempts => $self->max_attempts();   # override default max_attempts 10.
  return ($response, $tries, $last_error);
}

# convert a plain hash auth to an object if a hash was passed.
sub auth {
  my $self = shift;

  if (!blessed($self->{auth})) {
    # turn OAuth2Client into Google::RestApi::Auth::OAuth2Client etc.
    my $class = __PACKAGE__ . "::Auth::" . delete $self->{auth}->{class};
    load $class;
    # add the path to the base config file so auth hash doesn't have
    # to store the full path name for things like token_file etc.
    $self->{auth}->{config_dir} = dirname($self->{config_file})
      if $self->{config_file};
    $self->{auth} = $class->new(%{ $self->{auth} });
  }

  return $self->{auth};
}

sub _api_callback {
  my $self = shift;
  return if !$self->{api_callback};
  try {
    $self->{api_callback}->( $self->transaction() );
  } catch {
    my $err = $_;
    FATAL("Post process died: $err");
  };
  return;
}

sub api_callback {
  my $self = shift;
  state $check = compile(CodeRef, { optional => 1 });
  my ($api_callback) = $check->(@_);
  my $prev_api_callback = delete $self->{api_callback};
  $self->{api_callback} = $api_callback if $api_callback;
  return $prev_api_callback;
}

sub _stat {
  my $self = shift;
  my @stats = @_;
  foreach (@stats) {
    $_ = lc;
    $self->{stats}->{$_} //= 0;
    $self->{stats}->{$_}++;
  }
  return;
}

sub stats {
  my $self = shift;
  my $stats = dclone($self->{stats} || {});
  return $stats;
}

sub transaction { shift->{transaction} || {}; }

sub _caller_internal {
  my ($package, $subroutine, $line, $i) = ('', '', 0);
  do {
    ($package, undef, $line, $subroutine) = caller(++$i);
  } while($package &&
    ($package =~ m[^Cache::Memory] ||
     $subroutine =~ m[api$] ||
     $subroutine =~ m[^Cache|_cache])
  );
  # not usually going to happen, but during testing we call
  # RestApi::api directly, so have to backtrack.
  ($package, undef, $line, $subroutine) = caller(--$i)
    if !$package;
  return "$package:$line => $subroutine";
}

sub _caller_external {
  my ($package, $subroutine, $line, $i) = ('', '', 0);
  do {
    ($package, undef, $line, $subroutine) = caller(++$i);
  } while($package && $package =~ m[^(Google::RestApi|Cache|Try)]);
  return "$package:$line => $subroutine";
}

# undef returns current value. postitive int sets and returns new value.
# 0 sets and returns default value.
sub max_attempts {
  my $self = shift;
  state $check = compile(PositiveOrZeroInt->where(sub { $_ < 10; }), { optional => 1 });
  my ($max_attempts) = $check->(@_);
  $self->{max_attempts} = $max_attempts if $max_attempts;
  $self->{max_attempts} = 4 if defined $max_attempts && $max_attempts == 0;
  return $self->{max_attempts};
}

1;

__END__

=head1 NAME

Google::RestApi - Connection to Google REST APIs (currently Drive and Sheets).

=head1 SYNOPSIS

=over

  use Google::RestApi;
  $rest_api = Google::RestApi->new(
    config_file   => <path_to_config_file>,
    auth          => <object|hashref>,
    timeout       => <int>,
    throttle      => <int>,
    api_callback  => <coderef>,
  );

  $response = $rest_api->api(
    uri     => <google_api_url>,
    method  => get|head|put|patch|post|delete,
    headers => [],
    params  => <query_params>,
    content => <data_for_body>,
  );

  use Google::RestApi::SheetsApi4;
  $sheets_api = Google::RestApi::SheetsApi4->new(api => $rest_api);
  $sheet = $sheets_api->open_spreadsheet(title => "payroll");

  use Google::RestApi::DriveApi3;
  $drive = Google::RestApi::DriveApi3->new(api => $rest_api);
  $file = $drive->file(id => 'xxxx');
  $copy = $file->copy(title => 'my-copy-of-xxx');

  print YAML::Any::Dump($rest_api->stats());

=back

=head1 DESCRIPTION

Google Rest API is the foundation class used by the included Drive
and Sheets APIs. It is used to send API requests to the Google API
endpoint on behalf of the underlying API classes (Sheets and Drive).

=head1 SUBROUTINES

=over

=item new(config_file => <path_to_config_file>, auth => <object|hash>, api_callback => <coderef>, throttle => <int>);

 config_file: Optional YAML configuration file that can specify any
   or all of the following args:
 auth: A hashref to create the specified auth class, or (outside the config file) an instance of the blessed class itself.
 api_callback: A coderef to call after each API call.
 throttle: Used in development to sleep the number of seconds
   specified between API calls to avoid threshhold errors from Google.

You can specify any of the arguments in the optional YAML config file.
Any passed-in arguments will override what is in the config file.

The 'auth' arg can specify a pre-blessed class of one of the Google::RestApi::Auth::*
classes, or, for convenience sake, you can specify a hash of the required
arguments to create an instance of that class:
  auth:
    class: OAuth2Client
    client_id: xxxxxx
    client_secret: xxxxxx
    token_file: <path_to_token_file>

Note that the auth hash itself can also contain a config_file:
  auth:
    class: OAuth2Client
    config_file: <path_to_oauth_config_file>

This allows you the option to keep the auth file in a separate, more secure place.

=item api(uri => <uri_string>, method => <http_method_string>,
  headers => <headers_string_array>, params => <query_parameters_hash>,
  content => <body_hash>);

The ultimate Google API call for the underlying classes. Handles timeouts
and retries etc.

 uri: The Google API endpoint such as https://www.googleapis.com/drive/v3
   along with any path segments added.
 method: The http method being used get|head|put|patch|post|delete.
 headers: Array ref of http headers.
 params: Http query params to be added to the uri.
 content: The body being sent for post/put etc. Will be encoded to JSON.

You would not normally call this directly unless you were
making a Google API call not currently supported by this API
framework.

=item stats();

Shows some statistics on how many get/put/post etc calls were made.
Useful for performance tuning during development.

=back

=head1 SEE ALSO

For specific use of this class, see:

 Google::RestApi::DriveApi3
 Google::RestApi::SheetsApi4

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
