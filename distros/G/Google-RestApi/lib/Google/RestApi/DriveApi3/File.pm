package Google::RestApi::DriveApi3::File;

our $VERSION = '2.1.1';

use Google::RestApi::Setup;

use parent 'Google::RestApi::SubResource';

use aliased 'Google::RestApi::DriveApi3';
use aliased 'Google::RestApi::DriveApi3::Permission';
use aliased 'Google::RestApi::DriveApi3::Revision';
use aliased 'Google::RestApi::DriveApi3::Comment';

sub new {
  my $class = shift;
  my $qr_id = $Google::RestApi::DriveApi3::Drive_File_Id;
  state $check = signature(
    bless => !!0,
    named => [
      drive => HasApi,
      id    => StrMatch[qr/$qr_id/],
    ],
  );
  return bless $check->(@_), $class;
}

sub _uri_base { 'files' }
sub _parent_accessor { 'drive' }

sub copy {
  my $self = shift;

  state $check = signature(
    bless => !!0,
    named => [
      name    => Str, { optional => 1 },
      title   => Str, { optional => 1 },
      _extra_ => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));
  $p->{name} //= $p->{title};
  $p->{content}->{name} = $p->{name} if defined $p->{name};
  delete @$p{qw(name title)};

  $p->{uri} = 'copy';
  $p->{method} = 'post';

  my $copy = $self->api(%$p);
  DEBUG(sprintf("Copied file '%s' to '%s'", $self->file_id(), $copy->{id}));
  return ref($self)->new(
    drive => $self->drive(),
    id    => $copy->{id},
  );
}

sub delete {
  my $self = shift;
  DEBUG(sprintf("Deleting file '%s'", $self->file_id()));
  return $self->api(method => 'delete');
}

sub get {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      fields => Str, { optional => 1 },
      params => HashRef, { default => {} },
    ],
  );
  my $p = $check->(@_);

  my $params = $p->{params};
  $params->{fields} = $p->{fields} if defined $p->{fields};

  return $self->api(params => $params);
}

sub update {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      name        => Str, { optional => 1 },
      description => Str, { optional => 1 },
      mime_type   => Str, { optional => 1 },
      add_parents    => Str, { optional => 1 },
      remove_parents => Str, { optional => 1 },
      _extra_     => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  my %params;
  $params{addParents} = delete $p->{add_parents} if defined $p->{add_parents};
  $params{removeParents} = delete $p->{remove_parents} if defined $p->{remove_parents};

  my %content;
  $content{name} = delete $p->{name} if defined $p->{name};
  $content{description} = delete $p->{description} if defined $p->{description};
  $content{mimeType} = delete $p->{mime_type} if defined $p->{mime_type};

  DEBUG(sprintf("Updating file '%s'", $self->file_id()));
  return $self->api(
    method  => 'patch',
    params  => \%params,
    content => \%content,
  );
}

sub export {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      mime_type => Str,
    ],
  );
  my $p = $check->(@_);

  DEBUG(sprintf("Exporting file '%s' as '%s'", $self->file_id(), $p->{mime_type}));
  return $self->api(
    uri    => 'export',
    params => { mimeType => $p->{mime_type} },
  );
}

sub watch {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      id         => Str,
      type       => Str, { default => 'web_hook' },
      address    => Str,
      expiration => Int, { optional => 1 },
      _extra_    => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  my $content = {
    id      => delete $p->{id},
    type    => delete $p->{type},
    address => delete $p->{address},
  };
  $content->{expiration} = delete $p->{expiration} if defined $p->{expiration};

  DEBUG(sprintf("Setting watch on file '%s'", $self->file_id()));
  return $self->api(
    uri     => 'watch',
    method  => 'post',
    content => $content,
  );
}

sub permission {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      id => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);
  return Permission->new(file => $self, %$p);
}

sub permissions {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      fields        => Str, { optional => 1 },
      max_pages     => Int, { default => 0 },
      page_callback => CodeRef, { optional => 1 },
      params        => HashRef, { default => {} },
    ],
  );
  my $p = $check->(@_);

  return paginated_list(
    api            => $self,
    uri            => 'permissions',
    result_key     => 'permissions',
    default_fields => 'permissions(id, role, type, emailAddress)',
    max_pages      => $p->{max_pages},
    params         => $p->{params},
    ($p->{page_callback} ? (page_callback => $p->{page_callback}) : ()),
  );
}

sub revision {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      id => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);
  return Revision->new(file => $self, %$p);
}

sub revisions {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      fields        => Str, { optional => 1 },
      max_pages     => Int, { default => 0 },
      page_callback => CodeRef, { optional => 1 },
      params        => HashRef, { default => {} },
    ],
  );
  my $p = $check->(@_);

  return paginated_list(
    api            => $self,
    uri            => 'revisions',
    result_key     => 'revisions',
    default_fields => 'revisions(id, modifiedTime, keepForever)',
    max_pages      => $p->{max_pages},
    params         => $p->{params},
    ($p->{page_callback} ? (page_callback => $p->{page_callback}) : ()),
  );
}

sub comment {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      id => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);
  return Comment->new(file => $self, %$p);
}

sub comments {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      fields          => Str, { optional => 1 },
      include_deleted => Bool, { default => 0 },
      max_pages       => Int, { default => 0 },
      page_callback   => CodeRef, { optional => 1 },
      params          => HashRef, { default => {} },
    ],
  );
  my $p = $check->(@_);

  $p->{params}->{includeDeleted} = $p->{include_deleted} ? 'true' : 'false';

  return paginated_list(
    api            => $self,
    uri            => 'comments',
    result_key     => 'comments',
    default_fields => 'comments(id, content, author, createdTime)',
    max_pages      => $p->{max_pages},
    params         => $p->{params},
    ($p->{page_callback} ? (page_callback => $p->{page_callback}) : ()),
  );
}

sub file_id { shift->{id}; }
sub drive { shift->{drive}; }

1;

__END__

=head1 NAME

Google::RestApi::DriveApi3::File - File object for Google Drive.

=head1 SYNOPSIS

 my $file = $drive->file(id => 'file_id');

 # Get file metadata
 my $metadata = $file->get();
 my $name = $file->get(fields => 'name')->{name};

 # Update file
 $file->update(name => 'new_name', description => 'new description');

 # Copy and delete
 my $copy = $file->copy(name => 'copy_of_file');
 $file->delete();

 # Export (for Google Docs)
 my $pdf = $file->export(mime_type => 'application/pdf');

 # Watch for changes
 $file->watch(id => 'channel-id', address => 'https://example.com/webhook');

 # Permissions
 my @perms = $file->permissions();
 my $perm = $file->permission(id => 'perm_id');
 $file->permission()->create(role => 'reader', type => 'anyone');

 # Revisions
 my @revs = $file->revisions();
 my $rev = $file->revision(id => 'rev_id');

 # Comments
 my @comments = $file->comments();
 my $comment = $file->comment(id => 'comment_id');
 $file->comment()->create(content => 'Nice work!');

=head1 DESCRIPTION

Represents a Google Drive file with full CRUD operations, permissions,
revisions, and comments management.

=head1 METHODS

=head2 get(fields => $fields, params => \%params)

Retrieves file metadata.

=head2 update(name => $name, description => $desc, ...)

Updates file metadata. Supports name, description, mime_type,
add_parents, and remove_parents parameters.

=head2 copy(name => $name)

Creates a copy of the file. Returns a new File object.

=head2 delete()

Permanently deletes the file.

=head2 export(mime_type => $type)

Exports Google Docs/Sheets/Slides to the specified format.

=head2 watch(id => $channel_id, address => $url)

Sets up a notification channel for file changes.

=head2 permission(id => $id)

Returns a Permission object. If id is provided, represents that permission.
Without id, can be used to create new permissions.

=head2 permissions(max_pages => $n, page_callback => $coderef)

Lists all permissions on the file. C<max_pages> limits the number of pages
fetched (default 0 = unlimited). Supports C<page_callback>,
see L<Google::RestApi/PAGE CALLBACKS>.

=head2 revision(id => $id)

Returns a Revision object for the given revision ID.

=head2 revisions(max_pages => $n, page_callback => $coderef)

Lists all revisions of the file. C<max_pages> limits the number of pages
fetched (default 0 = unlimited). Supports C<page_callback>,
see L<Google::RestApi/PAGE CALLBACKS>.

=head2 comment(id => $id)

Returns a Comment object. Without id, can be used to create new comments.

=head2 comments(include_deleted => $bool, max_pages => $n, page_callback => $coderef)

Lists all comments on the file. C<max_pages> limits the number of pages
fetched (default 0 = unlimited). Supports C<page_callback>,
see L<Google::RestApi/PAGE CALLBACKS>.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
