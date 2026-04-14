package Google::RestApi::DocsApi1::Document;

our $VERSION = '2.2.1';

use Google::RestApi::Setup;

use parent "Google::RestApi::Request";

sub new {
  my $class = shift;

  state $check = signature(
    bless => !!0,
    named => [
      docs_api => HasApi,
      id       => Str,
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
  $p->{uri} = $self->{id} . ($p->{uri} ? "/$p->{uri}" : '');
  return $self->docs_api()->api(%$p);
}

sub document_id { shift->{id}; }

sub get {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      fields  => Str, { optional => 1 },
      _extra_ => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));
  my %params;
  $params{fields} = delete $p->{fields} if $p->{fields};
  return $self->api(
    %$p,
    (%params ? (params => \%params) : ()),
  );
}

sub submit_requests {
  my $self = shift;

  my @requests = $self->batch_requests();
  return if !@requests;

  my $result = $self->api(
    uri     => ':batchUpdate',
    method  => 'post',
    content => { requests => \@requests },
  );

  my $replies = $result->{replies} || [];
  $self->requests_response_from_api($replies);

  return $result;
}

# Request builder methods. Each queues a request hash and returns $self for chaining.

sub insert_text {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      text     => Str,
      index    => Int, { optional => 1 },
      segment_id => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);

  my %location;
  $location{index} = $p->{index} if defined $p->{index};
  $location{segmentId} = $p->{segment_id} if defined $p->{segment_id};

  $self->batch_requests(
    insertText => {
      text     => $p->{text},
      location => \%location,
    },
  );
  return $self;
}

sub delete_content {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      range => HashRef,
    ],
  );
  my $p = $check->(@_);

  $self->batch_requests(
    deleteContentRange => {
      range => $p->{range},
    },
  );
  return $self;
}

sub replace_all_text {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      find        => Str,
      replacement => Str,
      match_case  => Bool, { default => 1 },
    ],
  );
  my $p = $check->(@_);

  $self->batch_requests(
    replaceAllText => {
      containsText => {
        text      => $p->{find},
        matchCase => $p->{match_case} ? JSON::MaybeXS::true() : JSON::MaybeXS::false(),
      },
      replaceText => $p->{replacement},
    },
  );
  return $self;
}

sub update_text_style {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      range  => HashRef,
      style  => HashRef,
      fields => Str,
    ],
  );
  my $p = $check->(@_);

  $self->batch_requests(
    updateTextStyle => {
      range     => $p->{range},
      textStyle => $p->{style},
      fields    => $p->{fields},
    },
  );
  return $self;
}

sub update_paragraph_style {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      range  => HashRef,
      style  => HashRef,
      fields => Str,
    ],
  );
  my $p = $check->(@_);

  $self->batch_requests(
    updateParagraphStyle => {
      range          => $p->{range},
      paragraphStyle => $p->{style},
      fields         => $p->{fields},
    },
  );
  return $self;
}

sub insert_table {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      index   => Int,
      rows    => Int,
      columns => Int,
      segment_id => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);

  my %location = (index => $p->{index});
  $location{segmentId} = $p->{segment_id} if defined $p->{segment_id};

  $self->batch_requests(
    insertTable => {
      rows             => $p->{rows},
      columns          => $p->{columns},
      location         => \%location,
    },
  );
  return $self;
}

sub insert_inline_image {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      index      => Int,
      uri        => Str,
      width      => HashRef, { optional => 1 },
      height     => HashRef, { optional => 1 },
      segment_id => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);

  my %location = (index => $p->{index});
  $location{segmentId} = $p->{segment_id} if defined $p->{segment_id};

  my %request = (
    uri                => $p->{uri},
    location           => \%location,
  );
  if ($p->{width} || $p->{height}) {
    my %size;
    $size{width} = $p->{width} if $p->{width};
    $size{height} = $p->{height} if $p->{height};
    $request{objectSize} = \%size;
  }

  $self->batch_requests(insertInlineImage => \%request);
  return $self;
}

sub create_paragraph_bullets {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      range         => HashRef,
      bullet_preset => Str,
    ],
  );
  my $p = $check->(@_);

  $self->batch_requests(
    createParagraphBullets => {
      range        => $p->{range},
      bulletPreset => $p->{bullet_preset},
    },
  );
  return $self;
}

sub delete_paragraph_bullets {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      range => HashRef,
    ],
  );
  my $p = $check->(@_);

  $self->batch_requests(
    deleteParagraphBullets => {
      range => $p->{range},
    },
  );
  return $self;
}

sub create_named_range {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      name  => Str,
      range => HashRef,
    ],
  );
  my $p = $check->(@_);

  $self->batch_requests(
    createNamedRange => {
      name  => $p->{name},
      range => $p->{range},
    },
  );
  return $self;
}

sub delete_named_range {
  my $self = shift;
  state $check = signature(positional => [Str]);
  my ($named_range_id) = $check->(@_);

  $self->batch_requests(
    deleteNamedRange => {
      namedRangeId => $named_range_id,
    },
  );
  return $self;
}

sub create_header {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      type                   => Str,
      section_break_location => HashRef, { optional => 1 },
    ],
  );
  my $p = $check->(@_);

  my %request = (type => $p->{type});
  $request{sectionBreakLocation} = $p->{section_break_location}
    if $p->{section_break_location};

  $self->batch_requests(createHeader => \%request);
  return $self;
}

sub create_footer {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      type                   => Str,
      section_break_location => HashRef, { optional => 1 },
    ],
  );
  my $p = $check->(@_);

  my %request = (type => $p->{type});
  $request{sectionBreakLocation} = $p->{section_break_location}
    if $p->{section_break_location};

  $self->batch_requests(createFooter => \%request);
  return $self;
}

sub delete_header {
  my $self = shift;
  state $check = signature(positional => [Str]);
  my ($header_id) = $check->(@_);
  $self->batch_requests(deleteHeader => { headerId => $header_id });
  return $self;
}

sub delete_footer {
  my $self = shift;
  state $check = signature(positional => [Str]);
  my ($footer_id) = $check->(@_);
  $self->batch_requests(deleteFooter => { footerId => $footer_id });
  return $self;
}

sub insert_page_break {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      index      => Int,
      segment_id => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);

  my %location = (index => $p->{index});
  $location{segmentId} = $p->{segment_id} if defined $p->{segment_id};

  $self->batch_requests(
    insertPageBreak => {
      location => \%location,
    },
  );
  return $self;
}

sub insert_section_break {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      index      => Int,
      type       => Str,
      segment_id => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);

  my %location = (index => $p->{index});
  $location{segmentId} = $p->{segment_id} if defined $p->{segment_id};

  $self->batch_requests(
    insertSectionBreak => {
      sectionType => $p->{type},
      location    => \%location,
    },
  );
  return $self;
}

sub update_document_style {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      style  => HashRef,
      fields => Str,
    ],
  );
  my $p = $check->(@_);

  $self->batch_requests(
    updateDocumentStyle => {
      documentStyle => $p->{style},
      fields        => $p->{fields},
    },
  );
  return $self;
}

sub docs_api { shift->{docs_api}; }
sub rest_api { shift->docs_api()->rest_api(); }
sub transaction { shift->docs_api()->transaction(); }
sub stats { shift->docs_api()->stats(); }
sub reset_stats { shift->docs_api()->reset_stats(); }

1;

__END__

=head1 NAME

Google::RestApi::DocsApi1::Document - Represents a Google Docs document with batch update support.

=head1 DESCRIPTION

Document inherits from L<Google::RestApi::Request> and provides methods
to queue Google Docs API batch update requests. Requests are collected
and submitted together via C<submit_requests()>.

See the description and synopsis at L<Google::RestApi::DocsApi1>.

=head1 NAVIGATION

=over

=item * L<Google::RestApi::DocsApi1>

=item * L<Google::RestApi::DocsApi1::Document>

=back

=head1 SUBROUTINES

=over

=item new(%args)

Creates a new Document instance.

%args consists of:

=over

=item * C<docs_api> L<Google::RestApi::DocsApi1>: Required. The parent DocsApi1 object.

=item * C<id> <string>: Required. The document ID (Google Drive file ID).

=back

=item api(%args)

Calls the parent DocsApi1's 'api' routine adding the document ID.

=item document_id()

Returns the document ID.

=item get(%args)

Gets the document content.

%args consists of:

=over

=item * C<fields> <string>: Optional. Fields to return (e.g. 'title', 'body').

=back

=item submit_requests()

Submits all queued batch requests to the Google Docs API batchUpdate endpoint.

=item insert_text(%args)

Queues an insertText request.

%args: C<text> (required), C<index> (optional), C<segment_id> (optional).

=item delete_content(%args)

Queues a deleteContentRange request.

%args: C<range> (required hashref with startIndex/endIndex).

=item replace_all_text(%args)

Queues a replaceAllText request.

%args: C<find> (required), C<replacement> (required), C<match_case> (default true).

=item update_text_style(%args)

Queues an updateTextStyle request.

%args: C<range> (required), C<style> (required hashref), C<fields> (required).

=item update_paragraph_style(%args)

Queues an updateParagraphStyle request.

%args: C<range> (required), C<style> (required hashref), C<fields> (required).

=item insert_table(%args)

Queues an insertTable request.

%args: C<index> (required), C<rows> (required), C<columns> (required), C<segment_id> (optional).

=item insert_inline_image(%args)

Queues an insertInlineImage request.

%args: C<index> (required), C<uri> (required), C<width> (optional hashref), C<height> (optional hashref), C<segment_id> (optional).

=item create_paragraph_bullets(%args)

Queues a createParagraphBullets request.

%args: C<range> (required), C<bullet_preset> (required).

=item delete_paragraph_bullets(%args)

Queues a deleteParagraphBullets request.

%args: C<range> (required hashref).

=item create_named_range(%args)

Queues a createNamedRange request.

%args: C<name> (required), C<range> (required hashref).

=item delete_named_range(named_range_id)

Queues a deleteNamedRange request.

=item create_header(%args)

Queues a createHeader request.

%args: C<type> (required, e.g. 'DEFAULT'), C<section_break_location> (optional hashref).

=item create_footer(%args)

Queues a createFooter request.

%args: C<type> (required), C<section_break_location> (optional hashref).

=item delete_header(header_id)

Queues a deleteHeader request.

=item delete_footer(footer_id)

Queues a deleteFooter request.

=item insert_page_break(%args)

Queues an insertPageBreak request.

%args: C<index> (required), C<segment_id> (optional).

=item insert_section_break(%args)

Queues an insertSectionBreak request.

%args: C<index> (required), C<type> (required), C<segment_id> (optional).

=item update_document_style(%args)

Queues an updateDocumentStyle request.

%args: C<style> (required hashref), C<fields> (required).

=item docs_api()

Returns the parent DocsApi1 object.

=item rest_api()

Returns the underlying L<Google::RestApi> instance.

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
