# NAME

Google::RestApi - API to Google Drive API V3, Sheets API V4, Calendar API V3,
Gmail API V1, Tasks API V1, and Docs API V1.

# SYNOPSIS

>     # create a new RestApi object to be used by the apis.
>     use Google::RestApi;
>     $rest_api = Google::RestApi->new(
>       config_file   => <path_to_config_file>,
>       auth          => <object|hashref>,
>       timeout       => <int>,
>       throttle      => <int>,
>       api_callback  => <coderef>,
>     );
>
>     # you can call the raw api directly, but usually the apis will take care of
>     # forming the correct API calls for you.
>     $response = $rest_api->api(
>       uri     => <google_api_url>,
>       method  => get|head|put|patch|post|delete,
>       headers => [],
>       params  => <query_params>,
>       content => <data_for_body>,
>     );
>
>     # --- Drive API ---
>     use Google::RestApi::DriveApi3;
>     $drive = Google::RestApi::DriveApi3->new(api => $rest_api);
>     $file = $drive->file(id => 'xxxx');
>     $copy = $file->copy(name => 'my-copy-of-xxx');
>     @files = $drive->list(filter => "name contains 'report'");
>
>     # --- Sheets API ---
>     use Google::RestApi::SheetsApi4;
>     $sheets = Google::RestApi::SheetsApi4->new(api => $rest_api);
>     $spreadsheet = $sheets->open_spreadsheet(name => 'My Sheet');
>     $worksheet = $spreadsheet->open_worksheet(name => 'Sheet1');
>     @values = $worksheet->col('A');
>     $worksheet->row(1, ['Name', 'Email', 'Phone']);
>
>     # --- Calendar API ---
>     use Google::RestApi::CalendarApi3;
>     $calendar_api = Google::RestApi::CalendarApi3->new(api => $rest_api);
>     $calendar = $calendar_api->create_calendar(summary => 'Team Events');
>     $event = $calendar->event();
>     $event->create(
>       summary => 'Meeting',
>       start   => { dateTime => '2026-03-01T10:00:00-05:00' },
>       end     => { dateTime => '2026-03-01T11:00:00-05:00' },
>     );
>
>     # --- Gmail API ---
>     use Google::RestApi::GmailApi1;
>     $gmail = Google::RestApi::GmailApi1->new(api => $rest_api);
>     $gmail->send_message(
>       to => 'user@example.com', subject => 'Hello', body => 'Hi there',
>     );
>     @messages = $gmail->messages();
>
>     # --- Tasks API ---
>     use Google::RestApi::TasksApi1;
>     $tasks = Google::RestApi::TasksApi1->new(api => $rest_api);
>     $task_list = $tasks->create_task_list(title => 'My Tasks');
>     $task_list->create_task(title => 'Buy groceries', notes => 'Milk, eggs');
>
>     # --- Docs API ---
>     use Google::RestApi::DocsApi1;
>     $docs = Google::RestApi::DocsApi1->new(api => $rest_api);
>     $doc = $docs->create_document(title => 'My Document');
>     $doc->insert_text(text => 'Hello, world!');
>     $doc->submit_requests();
>
> See the individual PODs for the different apis for details on how to use each
> one.

# DESCRIPTION

Google::RestApi is a framework for interfacing with Google products, currently
Drive ([Google::RestApi::DriveApi3](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ADriveApi3)), Sheets ([Google::RestApi::SheetsApi4](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4)),
Calendar ([Google::RestApi::CalendarApi3](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ACalendarApi3)), Gmail ([Google::RestApi::GmailApi1](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3AGmailApi1)),
Tasks ([Google::RestApi::TasksApi1](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ATasksApi1)), and Docs ([Google::RestApi::DocsApi1](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ADocsApi1)).

The biggest hurdle to using this library is actually setting up the authorization
to access your Google account via a script. The Google development web space is
huge and complex. All that's required here is an OAuth2 token to authorize your
script that uses this library. See `bin/google_restapi_oauth_token_creator` for
instructions on how to do so. Once you've done it a couple of times it's
straight forward.

The synopsis above is a quick reference. For more detailed information, see the
pods listed in the ["NAVIGATION"](#navigation) section below.

Once you have successfully created your OAuth2 token, you can run the tutorials
to ensure everything is working correctly. Set the environment variable
`GOOGLE_RESTAPI_CONFIG` to the path to your auth config file. See the
`tutorial/` directory for step-by-step tutorials covering Sheets, Drive,
Calendar, Documents, Gmail, and Tasks. These will help you understand how the
API interacts with Google.

## Chained API Calls

Every Google API module has an `api()` method. Sub-resource objects
(see [Google::RestApi::SubResource](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASubResource)) don't call the Google endpoint
directly; instead, each `api()` prepends its own URI segment and
delegates to its parent's `api()`. The calls chain upward until they
reach the top-level API module (e.g. DriveApi3), which prepends the
endpoint base URL and hands the fully-assembled URI to
`Google::RestApi` for the actual HTTP request.

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

## Page Callbacks

Many list methods across the API support a `page_callback` parameter for
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

# SUBROUTINES

- new(%args); %args consists of:

    - `config_file` &lt;path\_to\_config\_file>: Optional YAML configuration file that can specify any or all of the following args...
    - `log4perl_config` &lt;path\_to\_log4perl\_config>: Optional path to a Log4perl configuration file. Initializes Log4perl logging if it has not already been initialized. A relative path is resolved relative to the directory of `config_file`. This is an alternative to setting the `GOOGLE_RESTAPI_LOGGER` environment variable.
    - `auth` &lt;hash|object>: A hashref to create the specified auth class, or (outside the config file) an instance of the blessed class itself.
    If this is an object, it must provide the 'params' and 'headers' subroutines to provide the appropriate Google authentication/authorization.
    See below for more details.
    - `api_callback` &lt;coderef>: A coderef to call after each API call.
    - `throttle` &lt;int>: Used in development to sleep the number of seconds specified between API calls to avoid rate limit violations from Google.

    You can specify any of the arguments in the optional YAML config file. Any passed-in arguments will override what is in the config file.

    If the config file is shared with other applications, place the Google::RestApi
    configuration under a `google_restapi` top-level key. That section takes
    precedence; if absent, the root of the file is used as before.

    The 'auth' arg can specify a pre-blessed class of one of the Google::RestApi::Auth::\* classes (e.g. 'OAuth2Client'), or, for convenience sake,
    you may specify a hash of the required arguments to create an instance of that class:

        auth:
          class: OAuth2Client
          client_id: xxxxxx
          client_secret: xxxxxx
          token_file: <path_to_token_file>

    Note that the auth hash itself can also contain a config\_file:

        auth:
          class: OAuth2Client
          config_file: <path_to_oauth_config_file>

    This allows you the option to keep the auth file in a separate, more secure place.

- api(%args);

    The ultimate Google API call for the underlying classes. Handles timeouts and retries etc. %args consists of:

    - `uri` &lt;uri\_string>: The Google API endpoint such as https://www.googleapis.com/drive/v3 along with any path segments added.
    - `method` &lt;http\_method\_string>: The http method being used get|head|put|patch|post|delete.
    - `headers` &lt;headers\_string\_array>: Array ref of http headers.
    - `params` &lt;query\_parameters\_hash>: Http query params to be added to the uri.
    - `content` &lt;payload hash>: The body being sent for post/put etc. Will be encoded to JSON.

    You would not normally call this directly unless you were making a Google API call not currently supported by this API framework.

    Returns the response hash from Google API.

- api\_callback(&lt;coderef>);

    - `coderef` is user code that will be called back after each call to the Google API.

    The last transaction details are passed to the callback. What you do with this information is up to you. For an example of how this is used, see the
    `tutorial/sheets/*` and `tutorial/drive/*` scripts.

    Returns the previous callback, if any.

- transaction();

    Returns the transaction information from the last Google API call. This is the same information that is provided by the callback
    above, but can be accessed directly if you have no need to provide a callback.

- stats();

    Returns some statistics on how many get/put/post etc calls were made. Useful for performance tuning during development.

# NAVIGATION

- [Google::RestApi::DriveApi3](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ADriveApi3)
- [Google::RestApi::DriveApi3::File](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ADriveApi3%3A%3AFile)
- [Google::RestApi::DriveApi3::About](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ADriveApi3%3A%3AAbout)
- [Google::RestApi::DriveApi3::Changes](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ADriveApi3%3A%3AChanges)
- [Google::RestApi::DriveApi3::Drive](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ADriveApi3%3A%3ADrive)
- [Google::RestApi::DriveApi3::Permission](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ADriveApi3%3A%3APermission)
- [Google::RestApi::DriveApi3::Comment](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ADriveApi3%3A%3AComment)
- [Google::RestApi::DriveApi3::Reply](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ADriveApi3%3A%3AReply)
- [Google::RestApi::DriveApi3::Revision](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ADriveApi3%3A%3ARevision)
- [Google::RestApi::SubResource](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASubResource)
- [Google::RestApi::SheetsApi4](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4)
- [Google::RestApi::SheetsApi4::Spreadsheet](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4%3A%3ASpreadsheet)
- [Google::RestApi::SheetsApi4::Worksheet](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4%3A%3AWorksheet)
- [Google::RestApi::SheetsApi4::Range](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4%3A%3ARange)
- [Google::RestApi::SheetsApi4::Range::All](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4%3A%3ARange%3A%3AAll)
- [Google::RestApi::SheetsApi4::Range::Col](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4%3A%3ARange%3A%3ACol)
- [Google::RestApi::SheetsApi4::Range::Row](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4%3A%3ARange%3A%3ARow)
- [Google::RestApi::SheetsApi4::Range::Cell](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4%3A%3ARange%3A%3ACell)
- [Google::RestApi::SheetsApi4::Range::Iterator](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4%3A%3ARange%3A%3AIterator)
- [Google::RestApi::SheetsApi4::RangeGroup](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4%3A%3ARangeGroup)
- [Google::RestApi::SheetsApi4::RangeGroup::Iterator](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4%3A%3ARangeGroup%3A%3AIterator)
- [Google::RestApi::SheetsApi4::RangeGroup::Tie](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4%3A%3ARangeGroup%3A%3ATie)
- [Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4%3A%3ARangeGroup%3A%3ATie%3A%3AIterator)
- [Google::RestApi::SheetsApi4::Request::Spreadsheet](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4%3A%3ARequest%3A%3ASpreadsheet)
- [Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4%3A%3ARequest%3A%3ASpreadsheet%3A%3AWorksheet)
- [Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet::Range](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ASheetsApi4%3A%3ARequest%3A%3ASpreadsheet%3A%3AWorksheet%3A%3ARange)
- [Google::RestApi::CalendarApi3](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ACalendarApi3)
- [Google::RestApi::CalendarApi3::Calendar](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ACalendarApi3%3A%3ACalendar)
- [Google::RestApi::CalendarApi3::Event](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ACalendarApi3%3A%3AEvent)
- [Google::RestApi::CalendarApi3::Acl](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ACalendarApi3%3A%3AAcl)
- [Google::RestApi::CalendarApi3::CalendarList](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ACalendarApi3%3A%3ACalendarList)
- [Google::RestApi::CalendarApi3::Colors](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ACalendarApi3%3A%3AColors)
- [Google::RestApi::CalendarApi3::Settings](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ACalendarApi3%3A%3ASettings)
- [Google::RestApi::GmailApi1](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3AGmailApi1)
- [Google::RestApi::GmailApi1::Message](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3AGmailApi1%3A%3AMessage)
- [Google::RestApi::GmailApi1::Attachment](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3AGmailApi1%3A%3AAttachment)
- [Google::RestApi::GmailApi1::Thread](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3AGmailApi1%3A%3AThread)
- [Google::RestApi::GmailApi1::Draft](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3AGmailApi1%3A%3ADraft)
- [Google::RestApi::GmailApi1::Label](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3AGmailApi1%3A%3ALabel)
- [Google::RestApi::TasksApi1](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ATasksApi1)
- [Google::RestApi::TasksApi1::TaskList](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ATasksApi1%3A%3ATaskList)
- [Google::RestApi::TasksApi1::Task](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ATasksApi1%3A%3ATask)
- [Google::RestApi::DocsApi1](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ADocsApi1)
- [Google::RestApi::DocsApi1::Document](https://metacpan.org/pod/Google%3A%3ARestApi%3A%3ADocsApi1%3A%3ADocument)

# STATUS

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

# BUGS

Please report a bug or missing api call by creating an issue at the git repo.

# AUTHORS

- Robin Murray mvsjes@cpan.org

# CONTRIBUTORS

- Dimitrios Kechagias
- Mohammad S Anwar
- qorron
- rocketgithub
- Todd Wade

# COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
