package Google::RestApi::DocsApi1;

our $VERSION = '2.2.2';

use Google::RestApi::Setup;

use Readonly;

use aliased 'Google::RestApi::DriveApi3';
use aliased 'Google::RestApi::DocsApi1::Document';

Readonly our $Docs_Endpoint    => 'https://docs.googleapis.com/v1/documents';
Readonly our $Document_Id      => $Google::RestApi::DriveApi3::Drive_File_Id;
Readonly our $Document_Filter  => "mimeType = 'application/vnd.google-apps.document'";

sub new {
  my $class = shift;

  state $check = signature(
    bless => !!0,
    named => [
      api      => HasApi,
      drive    => HasMethods[qw(list)], { optional => 1 },
      endpoint => Str, { default => $Docs_Endpoint },
    ],
  );
  my $self = $check->(@_);

  return bless $self, $class;
}

sub api {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      uri     => Str, { default => '' },
      _extra_ => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));
  my $uri = $self->{endpoint};
  $uri .= "/$p->{uri}" if $p->{uri};
  return $self->rest_api()->api(%$p, uri => $uri);
}

sub create_document {
  my $self = shift;

  state $check = signature(
    bless => !!0,
    named => [
      title   => Str, { optional => 1 },
      name    => Str, { optional => 1 },
      _extra_ => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));
  $p->{title} || $p->{name} or LOGDIE "Either 'title' or 'name' should be supplied";
  $p->{title} ||= $p->{name};
  delete $p->{name};

  my $result = $self->api(
    method  => 'post',
    content => { title => $p->{title} },
  );
  $result->{documentId} or LOGDIE "No 'documentId' returned from creating document";

  return $self->open_document(id => $result->{documentId});
}

sub open_document { Document->new(docs_api => shift, @_); }

sub delete_document {
  my $self = shift;
  my $id = $Document_Id;
  state $check = signature(positional => [StrMatch[qr/$id/]]);
  my ($document_id) = $check->(@_);
  return $self->drive()->file(id => $document_id)->delete();
}

sub delete_all_documents_by_filters {
  my $self = shift;

  state $check = signature(positional => [ArrayRef->plus_coercions(Str, sub { [$_]; })]);
  my ($filter) = $check->(@_);

  my $count = 0;
  foreach my $filter (@$filter) {
    my @documents = $self->documents_by_filter(filter => $filter);
    $count += scalar @documents;
    DEBUG(sprintf("Deleting %d documents for filter '$filter'", scalar @documents));
    $self->delete_document($_->{id}) foreach (@documents);
  }
  return $count;
}

sub delete_all_documents {
  my $self = shift;
  my @names = @_;
  @names = map { "name = '$_'"; } @names;
  return $self->delete_all_documents_by_filters(@names);
}

sub documents_by_filter {
  my $self = shift;

  state $check = signature(
    bless => !!0,
    named => [
      filter        => Str, { optional => 1 },
      max_pages     => Int, { default => 0 },
      page_callback => CodeRef, { optional => 1 },
      params        => HashRef, { default => {} },
    ],
  );
  my $p = $check->(@_);

  my $drive = $self->drive();
  my $filter = $Document_Filter;
  $filter .= " and ($p->{filter})" if $p->{filter};
  return $drive->list(
    filter    => $filter,
    max_pages => $p->{max_pages},
    params    => $p->{params},
    ($p->{page_callback} ? (page_callback => $p->{page_callback}) : ()),
  );
}

sub documents {
  my $self = shift;

  state $check = signature(
    bless => !!0,
    named => [
      name          => Str, { optional => 1 },
      max_pages     => Int, { default => 0 },
      page_callback => CodeRef, { optional => 1 },
      params        => HashRef, { default => {} },
    ],
  );
  my $p = $check->(@_);

  my $name = delete $p->{name};
  $p->{filter} = "name = '$name'" if $name;
  return $self->documents_by_filter(%$p);
}

sub drive {
  my $self = shift;
  $self->{drive} //= DriveApi3->new(api => $self->rest_api());
  return $self->{drive};
}

sub rest_api { shift->{api}; }
sub transaction { shift->rest_api()->transaction(); }
sub stats { shift->rest_api()->stats(); }
sub reset_stats { shift->rest_api->reset_stats(); }

1;

__END__

=head1 NAME

Google::RestApi::DocsApi1 - API to Google Docs API V1.

=head1 SYNOPSIS

=head2 Basic Setup

 use Google::RestApi;
 use Google::RestApi::DocsApi1;

 # Create the REST API instance
 my $rest_api = Google::RestApi->new(
   config_file => '/path/to/config.yaml',
 );

 # Create the Docs API instance
 my $docs_api = Google::RestApi::DocsApi1->new(api => $rest_api);

=head2 Creating and Opening Documents

 # Create a new document
 my $doc = $docs_api->create_document(title => 'My Document');

 # Open an existing document by ID
 my $doc = $docs_api->open_document(id => 'document_id');

 # Get document content
 my $content = $doc->get();

=head2 Batch Updates

 # Queue up changes and submit them together
 $doc->insert_text(text => 'Hello, World!', index => 1);
 $doc->insert_text(text => "\n\nThis is a paragraph.", index => 14);
 $doc->submit_requests();

 # Style the text
 $doc->update_text_style(
   range  => { startIndex => 1, endIndex => 14 },
   style  => { bold => JSON::MaybeXS::true() },
   fields => 'bold',
 );
 $doc->submit_requests();

=head2 Find and Replace

 $doc->replace_all_text(
   find        => 'old text',
   replacement => 'new text',
 );
 $doc->submit_requests();

=head2 Listing and Deleting Documents

 # List documents via Drive
 my @docs = $docs_api->documents();
 my @docs = $docs_api->documents(name => 'My Document');

 # Delete a document
 $docs_api->delete_document($document_id);

=head1 DESCRIPTION

Google::RestApi::DocsApi1 provides a Perl interface to the Google Docs API V1.
It enables document management including:

=over 4

=item * Document creation and retrieval

=item * Batch updates (insert text, delete content, formatting)

=item * Find and replace operations

=item * Table, header, footer, and section management

=item * Named range management

=item * Document listing and deletion via Drive API

=back

It is assumed that you are familiar with the Google Docs API:
L<https://developers.google.com/docs/api/reference/rest>

=head2 Architecture

The API uses a two-level object model:

 DocsApi1 (top-level)
   |-- open_document(id => ...)    -> Document
   |-- create_document(title => ...) -> Document

Document objects inherit from L<Google::RestApi::Request> for batch
request queuing. Requests are queued and submitted together via
C<submit_requests()>.

=head1 NAVIGATION

=over

=item * L<Google::RestApi::DocsApi1> - This module (top-level Docs API)

=item * L<Google::RestApi::DocsApi1::Document> - Document operations and batch updates

=back

=head1 SUBROUTINES

=head2 new(%args)

Creates a new DocsApi1 instance.

 my $docs_api = Google::RestApi::DocsApi1->new(api => $rest_api);

%args consists of:

=over

=item * C<api> L<Google::RestApi>: Required. A configured RestApi instance.

=item * C<drive> <object>: Optional. A Drive API instance for listing/deleting documents.

=item * C<endpoint> <string>: Optional. Override the default Docs API endpoint.

=back

=head2 api(%args)

Low-level method to make API calls. You would not normally call this directly
unless making a Google API call not currently supported by this framework.

%args consists of:

=over

=item * C<uri> <string>: Path segments to append to the Docs endpoint.

=item * C<%args>: Additional arguments passed to L<Google::RestApi>'s api() (content, params, method, etc).

=back

Returns the response hash from the Google API.

=head2 create_document(%args)

Creates a new Google Docs document.

 my $doc = $docs_api->create_document(title => 'My Document');

%args consists of:

=over

=item * C<title|name> <string>: The title (or name) of the new document.

=back

Returns a Document object for the created document.

=head2 open_document(%args)

Opens an existing document by ID.

 my $doc = $docs_api->open_document(id => 'document_id');

%args are passed to the Document constructor.

Returns a Document object.

=head2 delete_document(document_id<string>)

Deletes the document from Google Drive.

=head2 delete_all_documents([document_name<string>])

Deletes all documents with the given names from Google Drive.

Returns the number of documents deleted.

=head2 delete_all_documents_by_filters([filters<arrayref>])

Deletes all documents matching the given Drive query filters.

Returns the number of documents deleted.

=head2 documents_by_filter(%args)

Lists documents matching a Drive query filter, combined with the document MIME type filter.

%args consists of:

=over

=item * C<filter> <string>: Optional. A Drive query filter string.

=item * C<max_pages> <int>: Optional. Maximum pages to fetch (default 0 = unlimited).

=item * C<page_callback> <coderef>: Optional. Called with the result hashref for each page. Return false to stop pagination. See L<Google::RestApi/PAGE CALLBACKS>.

=item * C<params> <hashref>: Optional. Additional query parameters passed to the Drive API.

=back

Returns a list of file hashrefs with id and name.

=head2 documents(%args)

Lists documents, optionally filtered by name.

%args consists of:

=over

=item * C<name> <string>: Optional. Filter by document name.

=item * C<max_pages> <int>: Optional. Maximum pages to fetch (default 0 = unlimited).

=item * C<page_callback> <coderef>: Optional. Called with the result hashref for each page. Return false to stop pagination. See L<Google::RestApi/PAGE CALLBACKS>.

=item * C<params> <hashref>: Optional. Additional query parameters passed to the Drive API.

=back

Returns a list of file hashrefs with id and name.

=head2 drive()

Returns a DriveApi3 instance for file operations. Lazily created if not provided.

=head2 rest_api()

Returns the underlying L<Google::RestApi> instance.

=head2 transaction()

Returns the last API transaction details.

=head2 stats()

Returns API call statistics.

=head2 reset_stats()

Resets API call statistics.

=head1 SEE ALSO

=over

=item * L<Google::RestApi> - The underlying REST API client

=item * L<Google::RestApi::DriveApi3> - Google Drive API (related module)

=item * L<Google::RestApi::SheetsApi4> - Google Sheets API (related module)

=item * L<Google::RestApi::CalendarApi3> - Google Calendar API (related module)

=item * L<Google::RestApi::GmailApi1> - Google Gmail API (related module)

=item * L<Google::RestApi::TasksApi1> - Google Tasks API (related module)

=item * L<https://developers.google.com/docs/api/reference/rest> - Google Docs API Reference

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
