package Google::RestApi;

use strict;
use warnings;

our $VERSION = '0.4';

use 5.010_000;

use autodie;
use Furl;
use JSON;
use Scalar::Util qw(blessed);
use Sub::Retry;
use Storable qw(dclone);
use Time::Out qw(timeout);
use Type::Params qw(compile compile_named);
use Types::Standard qw(Str StrMatch Int ArrayRef HashRef CodeRef);
use URI;
use URI::QueryParam;
use YAML::Any qw(Dump);

use Google::RestApi::Utils qw(config_file);

no autovivification;

do 'Google/RestApi/logger_init.pl';

sub new {
  my $class = shift;

  my $self = config_file(@_);
  state $check = compile_named(
    config_file  => Str, { optional => 1 },
    auth         => 1,
    post_process => CodeRef, { optional => 1 },
    throttle     => Int->where('$_ > -1'), { default => 0 },
    timeout      => Int, { default => 120 },
  );
  $self = $check->(%$self);

  return bless $self, $class;
}

sub api {
  my $self = shift;

  state $check = compile_named(
    uri     => Str,
    method  => StrMatch[qr/^(get|head|put|patch|post|delete)$/i], { default => 'get' },
    headers => ArrayRef[Str], { default => [] },
    params  => HashRef, { default => {} },
    content => 1, { optional => 1 },
  );
  my $p = $check->(@_);

  $self->_stat( $p->{method}, 'total' );
  $p->{method} = uc($p->{method});

  my ($package, $line, $i) = ('', '', 0);
  do {
    ($package, undef, $line) = caller(++$i);
  } while($package && $package =~ m|Google::RestApi|);
  $p->{caller} = {
    package => $package,
    line    => $line,
  };
  DEBUG("Rest API request:\n", Dump($p));

  my $uri = $p->{uri};
  my $content = $p->{content};

  my @headers;
  push(@headers, 'Content-Type' => 'application/json') if $content;
  push(@headers, @{ $p->{headers} });

  # some (outdated) auth mechanisms may allow auth info in the params.
  my %params = (%{ $p->{params} }, %{ $self->auth()->params() });
  $uri = URI->new($uri);
  $uri->query_form_hash(\%params);
  DEBUG("Rest API URI: $p->{method} ", $uri->as_string());
  my $req = HTTP::Request->new(
    $p->{method}, $uri->as_string(), \@headers,
    $content ? encode_json($content) : (),
  );

  my $api_response = $self->_api($req);
  if (!$api_response) {
    $self->_stat('error');
    LOGDIE("Rest API failure: Nothing returned from request:\n", Dump({called => $p}));
  }
  if (!$api_response->is_success()) {
    $self->_stat('error');
    my $error = {
      code    => $api_response->code(),
      message => $api_response->message(),
      status  => $api_response->status_line(),
      called  => $p,
    };
    $error->{response} = eval { decode_json($api_response->decoded_content()); };
    LOGDIE("Rest API failure:\n", Dump($error));
  }

  my $api_content = $api_response->decoded_content();
  $api_content = $api_content ? decode_json($api_content) : 1;

  $self->{post_process}->(
    content  => $api_content,
    response => $api_response,
    called   => $p,
  ) if $self->{post_process};
  DEBUG("Rest API response:\n", Dump($api_content));

  # used for integration tests to avoid google 403's.
  sleep($self->{throttle}) if $self->{throttle};

  return wantarray ? ($api_content, $api_response, $p) : $api_content;
}

sub post_process {
  my $self = shift;
  state $check = compile(CodeRef, { optional => 1 });
  my ($process) = $check->(@_);
  if (!$process) {
    delete $self->{post_process};
    return;
  }
  $self->{post_process} = $process;
  return;
}

sub _stat {
  my $self = shift;
  my @stats = @_;
  $_ = lc for @stats;
  foreach (@stats) {
    $self->{stats}->{$_} //= 0;
    $self->{stats}->{$_}++;
  }
  return;
}

sub _api {
  my ($self, $req) = @_;

  my $res = retry 3, 1.0,
    sub {
      # timeout is in the ua too, but i've seen requests to spreadsheets
      # completely hang if the request isn't constructed correctly.
      timeout $self->{timeout} => sub {
        $self->ua()->request($req);
      };
    },
    sub {
      my $r = shift;
      if (!$r) {
        WARN("Not an HTTP::Response: $@");
        return 1;      # 1 = do retry
      } elsif ($r->status_line() =~ /^500\s+Internal Response/i or $r->code =~ /^50[234]$/) {
        WARN('Retrying: %s', $r->status_line());
        return 1;
      }
      return;
    };

  return $res;
}

sub ua {
  my $self = shift;
  if (!$self->{ua}) {
    $self->{ua} = Furl->new(
      headers => $self->auth()->headers(),
      timeout => $self->{timeout},
    );
  }
  return $self->{ua};
}

sub auth {
  my $self = shift;

  if (!blessed($self->{auth})) {
    # turn OAuth2Client into Google::RestApi::Auth::OAuth2Client etc.
    my $class = __PACKAGE__ . "::Auth::" . delete $self->{auth}->{class};
    eval "require $class";
    die "Unable to require '$class': $@" if $@;
    $self->{auth}->{parent_config_file} = $self->{config_file}
      if $self->{config_file};
    $self->{auth} = $class->new(%{ $self->{auth} });
  }

  return $self->{auth};
}

sub stats {
  my $self = shift;
  my $stats = $self->{stats} || {};
  $stats = dclone($stats);
  return $stats;
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
    post_process  => <coderef>,
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

=item new(config_file => <path_to_config_file>, auth => <object|hash>, post_process => <coderef>, throttle => <int>);

 config_file: Optional YAML configuration file that can specify any
   or all of the following args:
 auth: A hashref to create the specified auth class, or (outside the config file) an instance of the blessed class itself.
 post_process: A coderef to call after each API call.
 throttle: Used in development to sleep the number of seconds
   specified between API calls to avoid threshhold errors from Google.

You can specify any of the arguments in the optional YAML config file.
Any passed in arguments will override what is in the config file.

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

 Google::RestApi::SheetsApi4
 Google::RestApi::DriveApi3

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
