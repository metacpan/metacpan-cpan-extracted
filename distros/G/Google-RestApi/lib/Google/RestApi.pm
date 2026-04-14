package Google::RestApi;

our $VERSION = '2.2.1';

use Google::RestApi::Setup;

use File::Basename qw( dirname );
use Furl ();
use JSON::MaybeXS qw( decode_json encode_json JSON );
use List::Util ();
use Module::Load qw( load );
use PerlX::Maybe qw( maybe provided );
use Retry::Backoff qw( retry );
use Scalar::Util qw( blessed );
use Storable qw( dclone );
use Try::Tiny qw( catch try );
use URI ();
use URI::QueryParam ();

sub new {
  my $class = shift;

  my $self = merge_config_file(@_);
  state $check = signature(
    bless => !!0,
    named => [
      config_file  => ReadableFile, { optional => 1 },          # specify any of the below in a yaml file instead.
      auth         => HashRef | HasMethods[qw(headers params)], # a string that will be used to construct an auth obj, or the obj itself.
      throttle     => PositiveOrZeroInt, { default => 0 },      # mostly used for integration testing, to ensure we don't blow our rate limit.
      timeout      => Int, { default => 120 },
      max_attempts => PositiveInt->where(sub { $_ < 10; }), { default => 4 },
    ],
  );
  $self = $check->(%$self);

  $self->{ua} = Furl->new(timeout => $self->{timeout});

  return bless $self, $class;
}

# this is the actual call to the google api endpoint. handles retries, error checking etc.
# this would normally be called via Drive or Sheets objects.
sub api {
  my $self = shift;

  state $check = signature(
    bless => !!0,
    named => [
      uri     => StrMatch[qr(^https://)],
      method  => StrMatch[qr/^(get|head|put|patch|post|delete)$/i], { default => 'get' },
      params  => HashRef[Str|ArrayRef[Str]], { default => {} },   # uri param string.
      headers => ArrayRef[Str], { default => [] },                # http headers.
      content => 0,                                               # rest payload.
    ],
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

  my $http_req = HTTP::Request->new(
    $request->{method}, $request->{uri}, \@headers, $request_json
  );

  # this is where the action is.
  my ($response, $tries, $last_error) = $self->_api($http_req);

  # save the api call details so that the user can examine it in detail if necessary.
  # further information is also recorded below in this routine.
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

  # calls the callback when an api call is made, if any.
  $self->_api_callback();

  if (!$response || !$response->is_success()) {
    $self->_stat('error');
    my $activation_url = _activation_url($self->transaction());
    LOGDIE(
      ($activation_url ? "API not enabled in Google Cloud Console. Visit:\n  $activation_url\n" : ()),
      "Rest API failure:\n", Dump( $self->transaction() ),
    );
  }

  # used for to avoid google 403's and 429's as with integration tests.
  sleep($self->{throttle}) if $self->{throttle};

  return $self->{transaction}->{decoded_response};
}

# this wraps the http api call around retries.
sub _api {
  my ($self, $req) = @_;

  # default is exponential backoff, initial delay 1.
  my $tries = 0;
  my $last_error;
  my $refreshed_auth = 0;
  my $response = retry sub { $self->{ua}->request($req); },
    retry_if => sub {
      my $h = shift;
      my $r = $h->{attempt_result};   # Furl::Response
      if (!$r) {
        $last_error = $@ || "Unknown error";
        WARN("API call error: $last_error");
        return 1;
      }
      $last_error = $r->status_line() if !$r->is_success();
      if ($r->code() == 401 && !$refreshed_auth) {
        $refreshed_auth = 1;
        WARN("Got 401, refreshing auth token and retrying");
        my @new_auth = @{ $self->auth()->refresh_headers() };
        while (my ($name, $val) = splice(@new_auth, 0, 2)) {
          $req->header($name => $val);
        }
        return 1;
      }
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

# convert a plain hash auth to an object if a hash was passed in new() above.
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

# if user registered a callback, notify them of an api call.
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

# sets the api callback code.
sub api_callback {
  my $self = shift;
  state $check = signature(positional => [CodeRef, { optional => 1 }]);
  my ($api_callback) = $check->(@_);
  my $prev_api_callback = delete $self->{api_callback};
  $self->{api_callback} = $api_callback if $api_callback;
  return $prev_api_callback;
}

# a simple record of how many gets, posts, deletes etc were completed.
# useful for tuning network calls.
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

# returns the stats recorded above.
sub stats {
  my $self = shift;
  my $stats = dclone($self->{stats} || {});
  return $stats;
}

sub reset_stats {
  my $self = shift;
  delete $self->{stats};
  return;
}

# this is built for every api call so the entire api call can be examined,
# params, body content, http codes, etc etc.
sub transaction { shift->{transaction} || {}; }

# used for debugging/logging purposes. tries to dig out a useful caller
# so api calls can be traced back. skips some stuff that we use internally
# like cache.
sub _caller_internal {
  my ($package, $subroutine, $line, $i) = ('', '', 0);
  do {
    ($package, undef, $line, $subroutine) = caller(++$i);
  } while($package &&
    (
      $package    =~ m|^Cache::Memory| ||
      $subroutine =~ m[^Cache|_cache] ||
      $subroutine =~ m|api$|
    )
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

# extract the activation URL from a 403 "API not enabled" error response, if present.
sub _activation_url {
  my ($transaction) = @_;
  my $details = eval { $transaction->{decoded_response}{error}{details} };
  return unless ref $details eq 'ARRAY';
  for my $detail (@$details) {
    my $url = eval { $detail->{metadata}{activationUrl} };
    return $url if $url;
  }
  return;
}

# the maximum number of attempts to call the google api endpoint before giving up.
# undef returns current value. postitive int sets and returns new value.
# 0 sets and returns default value.
sub max_attempts {
  my $self = shift;
  state $check = signature(positional => [PositiveOrZeroInt->where(sub { $_ < 10; }), { optional => 1 }]);
  my ($max_attempts) = $check->(@_);
  $self->{max_attempts} = $max_attempts if $max_attempts;
  $self->{max_attempts} = 4 if defined $max_attempts && $max_attempts == 0;
  return $self->{max_attempts};
}

1;

__END__

=head1 NAME

Google::RestApi - API to Google Drive API V3, Sheets API V4, Calendar API V3,
Gmail API V1, Tasks API V1, and Docs API V1.

=head1 SYNOPSIS

=over

  # create a new RestApi object to be used by the apis.
  use Google::RestApi;
  $rest_api = Google::RestApi->new(
    config_file   => <path_to_config_file>,
    auth          => <object|hashref>,
    timeout       => <int>,
    throttle      => <int>,
    api_callback  => <coderef>,
  );

  # you can call the raw api directly, but usually the apis will take care of
  # forming the correct API calls for you.
  $response = $rest_api->api(
    uri     => <google_api_url>,
    method  => get|head|put|patch|post|delete,
    headers => [],
    params  => <query_params>,
    content => <data_for_body>,
  );

  # --- Drive API ---
  use Google::RestApi::DriveApi3;
  $drive = Google::RestApi::DriveApi3->new(api => $rest_api);
  $file = $drive->file(id => 'xxxx');
  $copy = $file->copy(name => 'my-copy-of-xxx');
  @files = $drive->list(filter => "name contains 'report'");

  # --- Sheets API ---
  use Google::RestApi::SheetsApi4;
  $sheets = Google::RestApi::SheetsApi4->new(api => $rest_api);
  $spreadsheet = $sheets->open_spreadsheet(name => 'My Sheet');
  $worksheet = $spreadsheet->open_worksheet(name => 'Sheet1');
  @values = $worksheet->col('A');
  $worksheet->row(1, ['Name', 'Email', 'Phone']);

  # --- Calendar API ---
  use Google::RestApi::CalendarApi3;
  $calendar_api = Google::RestApi::CalendarApi3->new(api => $rest_api);
  $calendar = $calendar_api->create_calendar(summary => 'Team Events');
  $event = $calendar->event();
  $event->create(
    summary => 'Meeting',
    start   => { dateTime => '2026-03-01T10:00:00-05:00' },
    end     => { dateTime => '2026-03-01T11:00:00-05:00' },
  );

  # --- Gmail API ---
  use Google::RestApi::GmailApi1;
  $gmail = Google::RestApi::GmailApi1->new(api => $rest_api);
  $gmail->send_message(
    to => 'user@example.com', subject => 'Hello', body => 'Hi there',
  );
  @messages = $gmail->messages();

  # --- Tasks API ---
  use Google::RestApi::TasksApi1;
  $tasks = Google::RestApi::TasksApi1->new(api => $rest_api);
  $task_list = $tasks->create_task_list(title => 'My Tasks');
  $task_list->create_task(title => 'Buy groceries', notes => 'Milk, eggs');

  # --- Docs API ---
  use Google::RestApi::DocsApi1;
  $docs = Google::RestApi::DocsApi1->new(api => $rest_api);
  $doc = $docs->create_document(title => 'My Document');
  $doc->insert_text(text => 'Hello, world!');
  $doc->submit_requests();

See the individual PODs for the different apis for details on how to use each
one.

=back

=head1 DESCRIPTION

Google::RestApi is a framework for interfacing with Google products, currently
Drive (L<Google::RestApi::DriveApi3>), Sheets (L<Google::RestApi::SheetsApi4>),
Calendar (L<Google::RestApi::CalendarApi3>), Gmail (L<Google::RestApi::GmailApi1>),
Tasks (L<Google::RestApi::TasksApi1>), and Docs (L<Google::RestApi::DocsApi1>).

The biggest hurdle to using this library is actually setting up the authorization
to access your Google account via a script. The Google development web space is
huge and complex. All that's required here is an OAuth2 token to authorize your
script that uses this library. See C<bin/google_restapi_oauth_token_creator> for
instructions on how to do so. Once you've done it a couple of times it's
straight forward.

The synopsis above is a quick reference. For more detailed information, see the
pods listed in the L</NAVIGATION> section below.

Once you have successfully created your OAuth2 token, you can run the tutorials
to ensure everything is working correctly. Set the environment variable
C<GOOGLE_RESTAPI_CONFIG> to the path to your auth config file. See the
C<tutorial/> directory for step-by-step tutorials covering Sheets, Drive,
Calendar, Documents, Gmail, and Tasks. These will help you understand how the
API interacts with Google.

=head2 Chained API Calls

Every Google API module has an C<api()> method. Sub-resource objects
(see L<Google::RestApi::SubResource>) don't call the Google endpoint
directly; instead, each C<api()> prepends its own URI segment and
delegates to its parent's C<api()>. The calls chain upward until they
reach the top-level API module (e.g. DriveApi3), which prepends the
endpoint base URL and hands the fully-assembled URI to
C<Google::RestApi> for the actual HTTP request.

For example, deleting a reply on a comment on a file produces this chain:

 $reply->api(method => 'delete')
   # Reply prepends "replies/$reply_id"
   -> $comment->api(uri => "replies/$reply_id", method => 'delete')
     # Comment prepends "comments/$comment_id"
     -> $file->api(uri => "comments/$comment_id/replies/$reply_id", ...)
       # File prepends "files/$file_id"
       -> $drive->api(uri => "files/$file_id/comments/$comment_id/replies/$reply_id", ...)
         # DriveApi3 prepends "https://www.googleapis.com/drive/v3/"
         -> $rest_api->api(uri => "https://...drive/v3/files/$file_id/comments/$comment_id/replies/$reply_id", method => 'delete')

Each layer only knows about its own URI segment and its parent accessor.
This pattern applies uniformly across all six APIs (Drive, Sheets,
Calendar, Gmail, Tasks, Docs).

=head2 Page Callbacks

Many list methods across the API support a C<page_callback> parameter for
processing paginated results. The callback is called with the raw API result
hashref after each page is fetched. Return a true value to continue fetching,
or false to stop early.

 # print progress while listing files:
 my @files = $drive->list(
   filter        => "name contains 'report'",
   page_callback => sub {
     my ($result) = @_;
     print "Fetched a page of results...\n";
     return 1;  # continue fetching
   },
 );

 # stop after finding what you need:
 my $target;
 my @messages = $gmail_api->messages(
   max_pages     => 0,       # allow unlimited pages
   page_callback => sub {
     my ($result) = @_;
     foreach my $msg (@{ $result->{messages} || [] }) {
       if ($msg->{id} eq $some_id) {
         $target = $msg;
         return 0;  # stop pagination
       }
     }
     return 1;  # keep going
   },
 );

=head1 SUBROUTINES

=over

=item new(%args); %args consists of:

=over

=item * C<config_file> <path_to_config_file>: Optional YAML configuration file that can specify any or all of the following args...

=item * C<auth> <hash|object>: A hashref to create the specified auth class, or (outside the config file) an instance of the blessed class itself.
If this is an object, it must provide the 'params' and 'headers' subroutines to provide the appropriate Google authentication/authorization.
See below for more details.

=item * C<api_callback> <coderef>: A coderef to call after each API call. 

=item * C<throttle> <int>: Used in development to sleep the number of seconds specified between API calls to avoid rate limit violations from Google.

=back

You can specify any of the arguments in the optional YAML config file. Any passed-in arguments will override what is in the config file.

If the config file is shared with other applications, place the Google::RestApi
configuration under a C<google_restapi> top-level key. That section takes
precedence; if absent, the root of the file is used as before.

The 'auth' arg can specify a pre-blessed class of one of the Google::RestApi::Auth::* classes (e.g. 'OAuth2Client'), or, for convenience sake,
you may specify a hash of the required arguments to create an instance of that class:

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

=item api(%args);

The ultimate Google API call for the underlying classes. Handles timeouts and retries etc. %args consists of:

=over

=item * C<uri> <uri_string>: The Google API endpoint such as https://www.googleapis.com/drive/v3 along with any path segments added.

=item * C<method> <http_method_string>: The http method being used get|head|put|patch|post|delete.

=item * C<headers> <headers_string_array>: Array ref of http headers.

=item * C<params> <query_parameters_hash>: Http query params to be added to the uri.

=item * C<content> <payload hash>: The body being sent for post/put etc. Will be encoded to JSON.

=back

You would not normally call this directly unless you were making a Google API call not currently supported by this API framework.

Returns the response hash from Google API.

=item api_callback(<coderef>);

=over

=item C<coderef> is user code that will be called back after each call to the Google API.

=back

The last transaction details are passed to the callback. What you do with this information is up to you. For an example of how this is used, see the
C<tutorial/sheets/*> and C<tutorial/drive/*> scripts.

Returns the previous callback, if any.

=item transaction();

Returns the transaction information from the last Google API call. This is the same information that is provided by the callback
above, but can be accessed directly if you have no need to provide a callback.

=item stats();

Returns some statistics on how many get/put/post etc calls were made. Useful for performance tuning during development.

=back

=head1 NAVIGATION

=over

=item * L<Google::RestApi::DriveApi3>

=item * L<Google::RestApi::DriveApi3::File>

=item * L<Google::RestApi::DriveApi3::About>

=item * L<Google::RestApi::DriveApi3::Changes>

=item * L<Google::RestApi::DriveApi3::Drive>

=item * L<Google::RestApi::DriveApi3::Permission>

=item * L<Google::RestApi::DriveApi3::Comment>

=item * L<Google::RestApi::DriveApi3::Reply>

=item * L<Google::RestApi::DriveApi3::Revision>

=item * L<Google::RestApi::SubResource>

=item * L<Google::RestApi::SheetsApi4>

=item * L<Google::RestApi::SheetsApi4::Spreadsheet>

=item * L<Google::RestApi::SheetsApi4::Worksheet>

=item * L<Google::RestApi::SheetsApi4::Range>

=item * L<Google::RestApi::SheetsApi4::Range::All>

=item * L<Google::RestApi::SheetsApi4::Range::Col>

=item * L<Google::RestApi::SheetsApi4::Range::Row>

=item * L<Google::RestApi::SheetsApi4::Range::Cell>

=item * L<Google::RestApi::SheetsApi4::Range::Iterator>

=item * L<Google::RestApi::SheetsApi4::RangeGroup>

=item * L<Google::RestApi::SheetsApi4::RangeGroup::Iterator>

=item * L<Google::RestApi::SheetsApi4::RangeGroup::Tie>

=item * L<Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator>

=item * L<Google::RestApi::SheetsApi4::Request::Spreadsheet>

=item * L<Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet>

=item * L<Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet::Range>

=item * L<Google::RestApi::CalendarApi3>

=item * L<Google::RestApi::CalendarApi3::Calendar>

=item * L<Google::RestApi::CalendarApi3::Event>

=item * L<Google::RestApi::CalendarApi3::Acl>

=item * L<Google::RestApi::CalendarApi3::CalendarList>

=item * L<Google::RestApi::CalendarApi3::Colors>

=item * L<Google::RestApi::CalendarApi3::Settings>

=item * L<Google::RestApi::GmailApi1>

=item * L<Google::RestApi::GmailApi1::Message>

=item * L<Google::RestApi::GmailApi1::Attachment>

=item * L<Google::RestApi::GmailApi1::Thread>

=item * L<Google::RestApi::GmailApi1::Draft>

=item * L<Google::RestApi::GmailApi1::Label>

=item * L<Google::RestApi::TasksApi1>

=item * L<Google::RestApi::TasksApi1::TaskList>

=item * L<Google::RestApi::TasksApi1::Task>

=item * L<Google::RestApi::DocsApi1>

=item * L<Google::RestApi::DocsApi1::Document>

=back

=head1 STATUS

Partial sheets and drive apis were hand-written by the author. Anthropic
Claude was used to generate the missing api calls for these, and the rest of
the google apis were added using Claude, based on the original hand-wrieetn
patterns. If all works for you, it will be due to the author's stunning
intellect. If it doesn't, or you see strange and wild code, it's all Claude's
fault, nothing to do with the author.

All mock exchanges were generated by running the unit tests and opening the
live api to save the requests/responses for later playback. This process is
used as an integration test. Because all the tests pass using this process,
it's a pretty good indicator that the calls work.

=head1 BUGS

Please report a bug or missing api call by creating an issue at the git repo.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 CONTRIBUTORS

=over

=item

Dimitrios Kechagias

=item

Mohammad S Anwar

=item

qorron

=item

rocketgithub

=item

Todd Wade

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
