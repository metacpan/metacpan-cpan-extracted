package Google::RestApi::DriveApi3;

our $VERSION = '2.1.1';

use Google::RestApi::Setup;

use Readonly;
use URI;

use aliased 'Google::RestApi::DriveApi3::File';
use aliased 'Google::RestApi::DriveApi3::About';
use aliased 'Google::RestApi::DriveApi3::Changes';
use aliased 'Google::RestApi::DriveApi3::Drive';

Readonly our $Drive_Endpoint => 'https://www.googleapis.com/drive/v3';
Readonly our $Drive_File_Id  => '[a-zA-Z0-9-_]+';
Readonly our $Drive_Id       => '[a-zA-Z0-9-_]+';

sub new {
  my $class = shift;
  state $check = signature(
    bless => !!0,
    named => [
      api      => HasApi,
      endpoint => Str, { default => $Drive_Endpoint },
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
  my $uri = "$self->{endpoint}/";
  $uri .= delete $p->{uri} if defined $p->{uri};
  return $self->{api}->api(%$p, uri => $uri);
}

sub list {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      filter        => Str,
      max_pages     => Int, { default => 0 },
      page_callback => CodeRef, { optional => 1 },
      params        => HashRef, { default => {} },
    ],
  );
  my $p = $check->(@_);

  $p->{params}->{q} = $p->{filter};

  return paginated_list(
    api            => $self,
    uri            => 'files',
    result_key     => 'files',
    default_fields => 'files(id, name)',
    max_pages      => $p->{max_pages},
    params         => $p->{params},
    ($p->{page_callback} ? (page_callback => $p->{page_callback}) : ()),
  );
}
# backward compatibility.
*filter_files = *list{CODE};

sub upload_endpoint {
  my $self = shift;
  my $upload = $self->{endpoint};
  $upload =~ s|googleapis.com/|googleapis.com/upload/|;
  return $upload;
}

sub file { File->new(drive => shift, @_); }

sub about { About->new(drive_api => shift); }

sub changes { Changes->new(drive_api => shift); }

sub shared_drive {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      id => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);
  return Drive->new(drive_api => $self, %$p);
}

sub list_drives {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      max_pages     => Int, { default => 0 },
      page_callback => CodeRef, { optional => 1 },
      params        => HashRef, { default => {} },
    ],
  );
  my $p = $check->(@_);

  return paginated_list(
    api            => $self,
    uri            => 'drives',
    result_key     => 'drives',
    default_fields => 'drives(id, name)',
    max_pages      => $p->{max_pages},
    params         => $p->{params},
    ($p->{page_callback} ? (page_callback => $p->{page_callback}) : ()),
  );
}

sub create_drive {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      name       => Str,
      request_id => Str,
      _extra_    => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  my $request_id = delete $p->{request_id};
  my $result = $self->api(
    uri     => 'drives',
    method  => 'post',
    params  => { requestId => $request_id },
    content => $p,
  );
  return Drive->new(drive_api => $self, id => $result->{id});
}

sub generate_ids {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      count => PositiveInt, { default => 10 },
      space => Str, { default => 'drive' },
    ],
  );
  my $p = $check->(@_);

  my $result = $self->api(
    uri    => 'files/generateIds',
    params => { count => $p->{count}, space => $p->{space} },
  );
  return $result->{ids} ? $result->{ids}->@* : ();
}

sub empty_trash {
  my $self = shift;
  return $self->api(
    uri    => 'files/trash',
    method => 'delete',
  );
}

sub rest_api { shift->{api}; }
sub transaction { shift->rest_api()->transaction(); }
sub stats { shift->rest_api()->stats(); }
sub reset_stats { shift->rest_api->reset_stats(); }

1;

__END__

=head1 NAME

Google::RestApi::DriveApi3 - API to Google Drive API V3.

=head1 SYNOPSIS

=head2 Basic Setup

 use Google::RestApi;
 use Google::RestApi::DriveApi3;

 # Create the REST API instance
 my $rest_api = Google::RestApi->new(
   config_file => '/path/to/config.yaml',
 );

 # Create the Drive API instance
 my $drive = Google::RestApi::DriveApi3->new(api => $rest_api);

=head2 Listing and Searching Files

 # List files matching a query (uses Google Drive query syntax)
 my @files = $drive->list(filter => "name contains 'report'");
 my @files = $drive->list(filter => "mimeType = 'application/vnd.google-apps.spreadsheet'");
 my @files = $drive->list(filter => "'folder_id' in parents and trashed = false");

 # With custom fields
 my @files = $drive->list(
   filter => "name contains 'doc'",
   params => { fields => 'files(id, name, mimeType, createdTime)' },
 );

=head2 Working with Files

 # Get a file object by ID
 my $file = $drive->file(id => 'file_id_here');

 # Get file metadata
 my $metadata = $file->get();
 my $metadata = $file->get(fields => 'id, name, mimeType, size, webViewLink');

 # Copy a file
 my $copy = $file->copy(name => 'Copy of Document');

 # Update file metadata
 $file->update(name => 'New Name', description => 'Updated description');

 # Delete a file (moves to trash)
 $file->delete();

 # Export Google Docs to other formats
 my $pdf_content = $file->export(mime_type => 'application/pdf');

=head2 File Permissions

 # List permissions on a file
 my @perms = $file->permissions();

 # Create a new permission
 my $perm = $file->permission()->create(
   type => 'user',
   role => 'reader',
   email_address => 'user@example.com',
 );

 # Or share with anyone
 $file->permission()->create(
   type => 'anyone',
   role => 'reader',
 );

 # Get a specific permission
 my $perm = $file->permission(id => 'permission_id');
 my $details = $perm->get();

 # Update permission
 $perm->update(role => 'writer');

 # Delete permission
 $perm->delete();

=head2 File Revisions

 # List revisions
 my @revisions = $file->revisions();

 # Get a specific revision
 my $rev = $file->revision(id => 'revision_id');
 my $details = $rev->get();

 # Update revision (keep forever)
 $rev->update(keep_forever => 1);

 # Delete a revision
 $rev->delete();

=head2 Comments and Replies

 # List comments on a file
 my @comments = $file->comments();

 # Create a comment
 my $comment = $file->comment()->create(
   content => 'Great work on this document!',
 );

 # Create a comment with quoted content
 $file->comment()->create(
   content        => 'This needs revision',
   quoted_content => 'The text being commented on',
 );

 # Get a comment
 my $comment = $file->comment(id => 'comment_id');
 my $details = $comment->get();

 # Update a comment
 $comment->update(content => 'Updated comment text');

 # Delete a comment
 $comment->delete();

 # Work with replies
 my @replies = $comment->replies();

 # Create a reply
 my $reply = $comment->reply()->create(
   content => 'Thanks for the feedback!',
 );

 # Create a reply that resolves the comment
 $comment->reply()->create(
   content => 'Fixed!',
   action  => 'resolve',
 );

=head2 User and Storage Information

 # Get About object
 my $about = $drive->about();

 # Get user information
 my $user = $about->user();
 say "Email: $user->{emailAddress}";
 say "Name: $user->{displayName}";

 # Get storage quota
 my $quota = $about->storage_quota();
 say "Used: $quota->{usage} bytes";
 say "Limit: $quota->{limit} bytes";

 # Get supported export formats
 my $formats = $about->export_formats();

 # Get supported import formats
 my $imports = $about->import_formats();

=head2 Change Tracking

 # Get a Changes object
 my $changes = $drive->changes();

 # Get starting page token for tracking changes
 my $token = $changes->get_start_page_token();

 # List changes since a token
 my $result = $changes->list(page_token => $token);
 for my $change ($result->{changes}->@*) {
   say "File: $change->{fileId}";
   say "Removed: $change->{removed}";
 }

 # The result includes the new token for next poll
 $token = $result->{newStartPageToken};

=head2 Shared Drives

 # List all shared drives
 my @drives = $drive->list_drives();

 # Create a new shared drive (requires unique request ID)
 my $shared = $drive->create_drive(
   name       => 'Team Documents',
   request_id => 'unique-request-id-123',
 );

 # Get a shared drive object
 my $sd = $drive->shared_drive(id => 'drive_id');

 # Get shared drive metadata
 my $info = $sd->get();

 # Update shared drive
 $sd->update(name => 'New Team Name');

 # Hide/unhide shared drive
 $sd->hide();
 $sd->unhide();

 # Delete shared drive (must be empty)
 $sd->delete();

=head2 Utility Operations

 # Pre-generate file IDs for later use
 my @ids = $drive->generate_ids(count => 10);

 # Empty the trash (permanent deletion!)
 $drive->empty_trash();

=head1 DESCRIPTION

Google::RestApi::DriveApi3 provides a Perl interface to the Google Drive API V3.
It enables comprehensive file management including:

=over 4

=item * File operations (list, get, copy, update, delete, export)

=item * Permission management (share files with users, groups, domains, or anyone)

=item * Revision tracking (view and manage file version history)

=item * Comments and replies (collaborate with comments on files)

=item * Change tracking (monitor file changes over time)

=item * Shared drive management (team drives)

=item * User and storage information

=back

It is assumed that you are familiar with the Google Drive API:
L<https://developers.google.com/drive/api/v3/reference>

=head2 Architecture

The API uses a hierarchical object model where child objects delegate API calls
to their parent:

 DriveApi3 (top-level)
   |-- about()           -> About
   |-- changes()         -> Changes
   |-- shared_drive()    -> Drive (Shared Drives)
   |-- file(id => ...)   -> File
        |-- permission() -> Permission
        |-- revision()   -> Revision
        |-- comment()    -> Comment
             |-- reply() -> Reply

Each object provides CRUD operations appropriate to its resource type.

=head1 NAVIGATION

=over

=item * L<Google::RestApi::DriveApi3> - This module (top-level Drive API)

=item * L<Google::RestApi::DriveApi3::File> - File operations

=item * L<Google::RestApi::DriveApi3::Permission> - File permission management

=item * L<Google::RestApi::DriveApi3::Revision> - File revision management

=item * L<Google::RestApi::DriveApi3::Comment> - File comments

=item * L<Google::RestApi::DriveApi3::Reply> - Comment replies

=item * L<Google::RestApi::DriveApi3::About> - User and storage information

=item * L<Google::RestApi::DriveApi3::Changes> - Change tracking

=item * L<Google::RestApi::DriveApi3::Drive> - Shared drives

=back

=head1 SUBROUTINES

=head2 new(%args)

Creates a new DriveApi3 instance.

 my $drive = Google::RestApi::DriveApi3->new(api => $rest_api);

%args consists of:

=over

=item * C<api> L<Google::RestApi>: Required. A configured RestApi instance.

=item * C<endpoint> <string>: Optional. Override the default Drive API endpoint.

=back

=head2 api(%args)

Low-level method to make API calls. You would not normally call this directly
unless making a Google API call not currently supported by this framework.

%args consists of:

=over

=item * C<uri> <string>: Path segments to append to the Drive endpoint.

=item * C<%args>: Additional arguments passed to L<Google::RestApi>'s api() (content, params, method, etc).

=back

Returns the response hash from the Google API.

=head2 list(%args)

Lists files matching the given query filter.

 my @files = $drive->list(filter => "name contains 'report'");

 # With custom parameters
 my @files = $drive->list(
   filter => "mimeType = 'application/pdf'",
   params => { fields => 'files(id, name, size)', orderBy => 'modifiedTime desc' },
 );

 # Limit to 2 pages of results
 my @files = $drive->list(filter => "name contains 'report'", max_pages => 2);

%args consists of:

=over

=item * C<filter> <string>: Required. Google Drive query filter string.

=item * C<max_pages> <int>: Optional. Limits the number of pages fetched (default 0 = unlimited).

=item * C<page_callback> <coderef>: Optional. Called after each page with the API result hashref.
Return true to continue fetching, false to stop. See L<Google::RestApi/PAGE CALLBACKS>.

=item * C<params> <hashref>: Optional. Additional query parameters.

=back

See L<https://developers.google.com/drive/api/v3/search-files> for query syntax.

Returns a list of file hashrefs with id and name (or custom fields).

=head2 filter_files(%args)

Alias for list(). Provided for backward compatibility.

=head2 file(%args)

Returns a File object for the given file ID.

 my $file = $drive->file(id => 'file_id');

%args consists of:

=over

=item * C<id> <string>: Optional. The file ID. Required for most operations.

=item * C<name> <string>: Optional. File name (for informational purposes).

=back

=head2 about()

Returns an About object for accessing user and storage information.

 my $about = $drive->about();
 my $user = $about->user();
 my $quota = $about->storage_quota();

=head2 changes()

Returns a Changes object for tracking file changes.

 my $changes = $drive->changes();
 my $token = $changes->get_start_page_token();
 my $result = $changes->list(page_token => $token);

=head2 shared_drive(%args)

Returns a Drive object for working with shared drives.

 my $sd = $drive->shared_drive(id => 'drive_id');

%args consists of:

=over

=item * C<id> <string>: Optional. The shared drive ID. Required for get/update/delete.

=back

=head2 list_drives(%args)

Lists all shared drives accessible to the user.

 my @drives = $drive->list_drives();

 # With custom parameters and page limit
 my @drives = $drive->list_drives(
   max_pages => 2,
   params    => { fields => 'drives(id, name, createdTime)' },
 );

C<max_pages> limits the number of pages fetched (default 0 = unlimited).
Supports C<page_callback>, see L<Google::RestApi/PAGE CALLBACKS>.

Returns a list of drive hashrefs.

=head2 create_drive(%args)

Creates a new shared drive.

 my $sd = $drive->create_drive(
   name       => 'Team Documents',
   request_id => 'unique-request-id-123',
 );

%args consists of:

=over

=item * C<name> <string>: Required. The name for the shared drive.

=item * C<request_id> <string>: Required. An idempotency key. Using the same
request_id will return the same drive rather than creating a duplicate.

=item * Additional args are passed as drive metadata.

=back

Returns a Drive object for the created shared drive.

=head2 generate_ids(%args)

Generates a set of file IDs that can be used for later file creation.

 my @ids = $drive->generate_ids(count => 10);

%args consists of:

=over

=item * C<count> <integer>: Number of IDs to generate. Default: 10. Max: 1000.

=item * C<space> <string>: The space for the IDs. Default: 'drive'.
Can be 'drive' or 'appDataFolder'.

=back

Returns a list of generated file ID strings.

=head2 empty_trash()

Permanently deletes all files in the user's trash. Use with caution!

 $drive->empty_trash();

Returns the API response (empty on success).

=head2 upload_endpoint()

Returns the upload endpoint URL for file uploads. Used internally.

=head2 rest_api()

Returns the underlying L<Google::RestApi> instance.

=head1 QUERY SYNTAX

The list() method accepts Google Drive query syntax. Common examples:

 # By name
 "name = 'Exact Name'"
 "name contains 'partial'"

 # By MIME type
 "mimeType = 'application/vnd.google-apps.spreadsheet'"
 "mimeType = 'application/pdf'"

 # By parent folder
 "'folder_id' in parents"

 # Exclude trashed files
 "trashed = false"

 # Combine conditions
 "name contains 'report' and mimeType = 'application/pdf' and trashed = false"

 # By owner
 "'user@example.com' in owners"

 # Modified time
 "modifiedTime > '2024-01-01T00:00:00'"

See L<https://developers.google.com/drive/api/v3/search-files> for full documentation.

=head1 SEE ALSO

=over

=item * L<Google::RestApi> - The underlying REST API client

=item * L<Google::RestApi::SheetsApi4> - Google Sheets API (related module)

=item * L<Google::RestApi::CalendarApi3> - Google Calendar API (related module)

=item * L<Google::RestApi::GmailApi1> - Google Gmail API (related module)

=item * L<Google::RestApi::TasksApi1> - Google Tasks API (related module)

=item * L<Google::RestApi::DocsApi1> - Google Docs API (related module)

=item * L<https://developers.google.com/drive/api/v3/reference> - Google Drive API Reference

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
