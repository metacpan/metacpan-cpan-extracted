package Google::RestApi::GmailApi1;

our $VERSION = '2.2.1';

use Google::RestApi::Setup;

use Encode qw(encode);
use MIME::Base64 qw(encode_base64);
use MIME::Lite;
use Readonly;
use URI;

use aliased 'Google::RestApi::GmailApi1::Message';
use aliased 'Google::RestApi::GmailApi1::Thread';
use aliased 'Google::RestApi::GmailApi1::Draft';
use aliased 'Google::RestApi::GmailApi1::Label';

Readonly our $Gmail_Endpoint => 'https://gmail.googleapis.com/gmail/v1/users';

sub new {
  my $class = shift;
  state $check = signature(
    bless => !!0,
    named => [
      api      => HasApi,
      user_id  => Str, { default => 'me' },
      endpoint => Str, { default => $Gmail_Endpoint },
    ],
  );
  return bless $check->(@_), $class;
}

sub api {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      uri     => Str, { optional => 1 },
      _extra_ => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));
  my $uri = "$self->{endpoint}/$self->{user_id}/";
  $uri .= delete $p->{uri} if defined $p->{uri};
  return $self->{api}->api(%$p, uri => $uri);
}

sub message {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      id => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);
  return Message->new(gmail_api => $self, %$p);
}

sub thread {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      id => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);
  return Thread->new(gmail_api => $self, %$p);
}

sub draft {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      id => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);
  return Draft->new(gmail_api => $self, %$p);
}

sub label {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      id => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);
  return Label->new(gmail_api => $self, %$p);
}

sub profile {
  my $self = shift;
  return $self->api(uri => 'profile');
}

sub messages {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      max_pages     => Int, { default => 1 },
      page_callback => CodeRef, { optional => 1 },
      params        => HashRef, { default => {} },
    ],
  );
  my $p = $check->(@_);

  return paginated_list(
    api            => $self,
    uri            => 'messages',
    result_key     => 'messages',
    default_fields => 'messages(id, threadId)',
    fields_prefix  => 'nextPageToken, resultSizeEstimate',
    max_pages      => $p->{max_pages},
    params         => $p->{params},
    ($p->{page_callback} ? (page_callback => $p->{page_callback}) : ()),
  );
}

sub threads {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      max_pages     => Int, { default => 1 },
      page_callback => CodeRef, { optional => 1 },
      params        => HashRef, { default => {} },
    ],
  );
  my $p = $check->(@_);

  return paginated_list(
    api            => $self,
    uri            => 'threads',
    result_key     => 'threads',
    default_fields => 'threads(id, snippet)',
    fields_prefix  => 'nextPageToken, resultSizeEstimate',
    max_pages      => $p->{max_pages},
    params         => $p->{params},
    ($p->{page_callback} ? (page_callback => $p->{page_callback}) : ()),
  );
}

sub labels {
  my $self = shift;
  my $result = $self->api(uri => 'labels');
  return $result->{labels} ? $result->{labels}->@* : ();
}

sub send_message {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      to           => Str,
      subject      => Str,
      body         => Str,
      from         => Str, { optional => 1 },
      cc           => Str, { optional => 1 },
      bcc          => Str, { optional => 1 },
      content_type => Str, { default => 'text/plain' },
    ],
  );
  my $p = $check->(@_);

  my $raw = $self->_build_mime(%$p);

  DEBUG("Sending message to '$p->{to}'");
  my $result = $self->api(
    uri     => 'messages/send',
    method  => 'post',
    content => { raw => $raw },
  );
  return Message->new(gmail_api => $self, id => $result->{id});
}

sub send_raw_message {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      raw => Str,
    ],
  );
  my $p = $check->(@_);

  DEBUG("Sending raw message");
  my $result = $self->api(
    uri     => 'messages/send',
    method  => 'post',
    content => { raw => $p->{raw} },
  );
  return Message->new(gmail_api => $self, id => $result->{id});
}

sub batch_modify_messages {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      ids              => ArrayRef[Str],
      add_label_ids    => ArrayRef[Str], { default => [] },
      remove_label_ids => ArrayRef[Str], { default => [] },
    ],
  );
  my $p = $check->(@_);

  my %content = (
    ids => $p->{ids},
  );
  $content{addLabelIds} = $p->{add_label_ids} if $p->{add_label_ids}->@*;
  $content{removeLabelIds} = $p->{remove_label_ids} if $p->{remove_label_ids}->@*;

  DEBUG(sprintf("Batch modifying %d messages", scalar $p->{ids}->@*));
  return $self->api(
    uri     => 'messages/batchModify',
    method  => 'post',
    content => \%content,
  );
}

sub batch_delete_messages {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      ids => ArrayRef[Str],
    ],
  );
  my $p = $check->(@_);

  DEBUG(sprintf("Batch deleting %d messages", scalar $p->{ids}->@*));
  return $self->api(
    uri     => 'messages/batchDelete',
    method  => 'post',
    content => { ids => $p->{ids} },
  );
}

sub _build_mime {
  my $self = shift;
  my %p = @_;

  my $mime = MIME::Lite->new(
    From    => $p{from} // '',
    To      => $p{to},
    Subject => $p{subject},
    Type    => $p{content_type},
    Data    => encode('UTF-8', $p{body}),
  );
  $mime->attr('content-type.charset' => 'UTF-8');
  $mime->add(Cc  => $p{cc})  if $p{cc};
  $mime->add(Bcc => $p{bcc}) if $p{bcc};

  my $raw = $mime->as_string;
  my $encoded = encode_base64($raw, '');
  $encoded =~ tr{+/}{-_};
  $encoded =~ s/=+$//;

  return $encoded;
}

sub rest_api { shift->{api}; }
sub transaction { shift->rest_api()->transaction(); }
sub stats { shift->rest_api()->stats(); }
sub reset_stats { shift->rest_api->reset_stats(); }

1;

__END__

=head1 NAME

Google::RestApi::GmailApi1 - API to Google Gmail API V1.

=head1 SYNOPSIS

=head2 Basic Setup

 use Google::RestApi;
 use Google::RestApi::GmailApi1;

 # Create the REST API instance
 my $rest_api = Google::RestApi->new(
   config_file => '/path/to/config.yaml',
 );

 # Create the Gmail API instance
 my $gmail_api = Google::RestApi::GmailApi1->new(api => $rest_api);

=head2 Profile and Labels

 # Get user profile
 my $profile = $gmail_api->profile();

 # List all labels
 my @labels = $gmail_api->labels();

 # Create a label
 my $label = $gmail_api->label()->create(name => 'My Label');

 # Delete a label
 $label->delete();

=head2 Messages

 # List messages
 my @messages = $gmail_api->messages();

 # Send a message
 my $msg = $gmail_api->send_message(
   to      => 'recipient@example.com',
   subject => 'Hello',
   body    => 'Message body',
 );

 # Get a specific message
 my $message = $gmail_api->message(id => 'msg_id');
 my $details = $message->get();

 # Modify message labels
 $message->modify(
   add_label_ids    => ['STARRED'],
   remove_label_ids => ['UNREAD'],
 );

 # Trash/untrash/delete
 $message->trash();
 $message->untrash();
 $message->delete();

=head2 Threads

 # List threads
 my @threads = $gmail_api->threads();

 # Get a thread
 my $thread = $gmail_api->thread(id => 'thread_id');
 my $details = $thread->get();

=head2 Drafts

 # Create a draft
 my $draft = $gmail_api->draft()->create(
   to      => 'recipient@example.com',
   subject => 'Draft subject',
   body    => 'Draft body',
 );

 # Send a draft
 $draft->send();

=head2 Batch Operations

 # Batch modify messages
 $gmail_api->batch_modify_messages(
   ids              => ['msg1', 'msg2'],
   add_label_ids    => ['STARRED'],
   remove_label_ids => ['UNREAD'],
 );

 # Batch delete messages
 $gmail_api->batch_delete_messages(ids => ['msg1', 'msg2']);

=head1 DESCRIPTION

Google::RestApi::GmailApi1 provides a Perl interface to the Google Gmail API V1.
It enables email management including:

=over 4

=item * Message operations (send, read, modify labels, trash, delete)

=item * Thread management (list, get, modify, trash, delete)

=item * Draft management (create, update, send, delete)

=item * Label management (create, get, update, delete)

=item * Batch operations (batch modify/delete messages)

=item * Attachment retrieval

=back

It is assumed that you are familiar with the Google Gmail API:
L<https://developers.google.com/gmail/api/reference/rest>

=head2 Architecture

The API uses a hierarchical object model where child objects delegate API calls
to their parent:

 GmailApi1 (top-level)
   |-- message(id => ...)       -> Message
   |     |-- attachment(id => ...) -> Attachment
   |-- thread(id => ...)        -> Thread
   |-- draft(id => ...)         -> Draft
   |-- label(id => ...)         -> Label

Each object provides CRUD operations appropriate to its resource type.

=head1 NAVIGATION

=over

=item * L<Google::RestApi::GmailApi1> - This module (top-level Gmail API)

=item * L<Google::RestApi::GmailApi1::Message> - Message operations

=item * L<Google::RestApi::GmailApi1::Attachment> - Attachment retrieval

=item * L<Google::RestApi::GmailApi1::Thread> - Thread management

=item * L<Google::RestApi::GmailApi1::Draft> - Draft management

=item * L<Google::RestApi::GmailApi1::Label> - Label management

=back

=head1 SUBROUTINES

=head2 new(%args)

Creates a new GmailApi1 instance.

 my $gmail_api = Google::RestApi::GmailApi1->new(api => $rest_api);

%args consists of:

=over

=item * C<api> L<Google::RestApi>: Required. A configured RestApi instance.

=item * C<user_id> <string>: Optional. The user ID (default 'me' for authenticated user).

=item * C<endpoint> <string>: Optional. Override the default Gmail API endpoint.

=back

=head2 api(%args)

Low-level method to make API calls. You would not normally call this directly
unless making a Google API call not currently supported by this framework.

%args consists of:

=over

=item * C<uri> <string>: Path segments to append to the Gmail endpoint.

=item * C<%args>: Additional arguments passed to L<Google::RestApi>'s api() (content, params, method, etc).

=back

Returns the response hash from the Google API.

=head2 message(%args)

Returns a Message object for the given message ID.

 my $msg = $gmail_api->message(id => 'msg_id');

=head2 thread(%args)

Returns a Thread object for the given thread ID.

 my $thread = $gmail_api->thread(id => 'thread_id');

=head2 draft(%args)

Returns a Draft object for the given draft ID.

 my $draft = $gmail_api->draft(id => 'draft_id');

=head2 label(%args)

Returns a Label object for the given label ID.

 my $label = $gmail_api->label(id => 'label_id');

=head2 profile()

Gets the authenticated user's Gmail profile.

 my $profile = $gmail_api->profile();

Returns a hashref with emailAddress, messagesTotal, threadsTotal, historyId.

=head2 messages(%args)

Lists messages in the user's mailbox.

 my @messages = $gmail_api->messages();
 my @filtered = $gmail_api->messages(params => { q => 'from:user@example.com' });
 my @paged = $gmail_api->messages(max_pages => 2, params => { maxResults => 10 });

%args consists of:

=over

=item * C<max_pages> <int>: Optional. Maximum number of pages to fetch (default 1). Set to 0 for unlimited.

=item * C<page_callback> <coderef>: Optional. See L<Google::RestApi/PAGE CALLBACKS>.

=item * C<params> <hashref>: Optional. Query parameters (q, maxResults, labelIds, etc).

=back

Returns a list of message hashrefs with id and threadId.

=head2 threads(%args)

Lists threads in the user's mailbox.

 my @threads = $gmail_api->threads();
 my @paged = $gmail_api->threads(max_pages => 2, params => { maxResults => 10 });

%args consists of:

=over

=item * C<max_pages> <int>: Optional. Maximum number of pages to fetch (default 1). Set to 0 for unlimited.

=item * C<page_callback> <coderef>: Optional. See L<Google::RestApi/PAGE CALLBACKS>.

=item * C<params> <hashref>: Optional. Query parameters (q, maxResults, etc).

=back

Returns a list of thread hashrefs with id and snippet.

=head2 labels()

Lists all labels in the user's mailbox.

 my @labels = $gmail_api->labels();

Returns a list of label hashrefs.

=head2 send_message(%args)

Sends an email message.

 my $msg = $gmail_api->send_message(
   to      => 'recipient@example.com',
   subject => 'Hello',
   body    => 'Message body',
 );

%args consists of:

=over

=item * C<to> <string>: Required. Recipient email address.

=item * C<subject> <string>: Required. Message subject.

=item * C<body> <string>: Required. Message body.

=item * C<from> <string>: Optional. Sender address.

=item * C<cc> <string>: Optional. CC recipients.

=item * C<bcc> <string>: Optional. BCC recipients.

=item * C<content_type> <string>: Optional. MIME content type (default 'text/plain').

=back

Returns a Message object for the sent message.

=head2 send_raw_message(raw => $base64url)

Sends a pre-encoded raw message.

=head2 batch_modify_messages(%args)

Batch modifies labels on multiple messages.

 $gmail_api->batch_modify_messages(
   ids              => ['msg1', 'msg2'],
   add_label_ids    => ['STARRED'],
   remove_label_ids => ['UNREAD'],
 );

=head2 batch_delete_messages(ids => \@ids)

Permanently batch deletes multiple messages.

=head2 rest_api()

Returns the underlying L<Google::RestApi> instance.

=head1 SEE ALSO

=over

=item * L<Google::RestApi> - The underlying REST API client

=item * L<Google::RestApi::DriveApi3> - Google Drive API (related module)

=item * L<Google::RestApi::SheetsApi4> - Google Sheets API (related module)

=item * L<Google::RestApi::CalendarApi3> - Google Calendar API (related module)

=item * L<Google::RestApi::TasksApi1> - Google Tasks API (related module)

=item * L<Google::RestApi::DocsApi1> - Google Docs API (related module)

=item * L<https://developers.google.com/gmail/api/reference/rest> - Google Gmail API Reference

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
