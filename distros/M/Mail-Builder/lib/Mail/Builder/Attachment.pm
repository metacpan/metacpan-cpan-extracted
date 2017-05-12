# ============================================================================
package Mail::Builder::Attachment;
# ============================================================================

use namespace::autoclean;
use Moose;
with qw(Mail::Builder::Role::File);
use Mail::Builder::TypeConstraints;

use MIME::Types;
use Carp;
use Encode;

our $VERSION = $Mail::Builder::VERSION;

has 'name' => (
    is          => 'rw',
    isa         => 'Str',
    lazy_build  => 1,
    trigger     => sub { shift->clear_cache },
);

has 'mimetype' => (
    is          => 'rw',
    isa         => 'Mail::Builder::Type::Mimetype',
    lazy_build  => 1,
    trigger     => sub { shift->clear_cache },
);


around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    if ( scalar @_ == 1 && ref $_[0] eq 'HASH' ) {
        return $class->$orig($_[0]);
    }
    else {
        my $params = {
            file    => $_[0],
        };
        if (defined $_[1]) {
            $params->{name} = $_[1];
        }
        if (defined $_[2]) {
            $params->{mimetype} = $_[2];
        }
        return $class->$orig($params);
    }
};

sub _build_mimetype {
    my ($self) = @_;

    my $filename = $self->filename;
    my $filetype;

    if (defined $filename
        && lc($filename->basename) =~ /\.([0-9a-z]{1,4})$/)  {
        my $mimetype = MIME::Types->new->mimeTypeOf($1);
        $filetype = $mimetype->type
            if defined $mimetype;
    }

    unless (defined $filetype) {
        my $filecontent = $self->filecontent;
        $filetype = $self->_check_magic_string($filecontent);
    }

    $filetype ||= 'application/octet-stream';

    return $filetype;
}

sub _build_name {
    my ($self) = @_;

    my $filename = $self->filename;
    my $name;

    if (defined $filename) {
        $name = $filename->basename;
    }

    unless (defined $name
        && $name !~ m/^\s*$/) {
        croak('Could not determine the attachment name automatically');
    }

    return $name;
}

sub serialize {
    my ($self) = @_;

    return $self->cache
        if ($self->has_cache);

    my $file = $self->file;
    my $accessor;
    my $value;

    if (blessed $file) {
        if ($file->isa('IO::File')) {
            $accessor = 'Data';
            $value = $self->filecontent;
        } elsif ($file->isa('Path::Class::File')) {
            $accessor = 'Path';
            $value = $file->stringify;
        }
    } else {
        $accessor = 'Data';
        $value = $$file;
    }

    my $entity = MIME::Entity->build(
        Disposition     => 'attachment',
        Type            => $self->mimetype,
        Top             => 0,
        Filename        => Mail::Builder::Utils::encode_mime($self->name),
        Encoding        => 'base64',
        $accessor       => $value,
    );

    $self->cache($entity);

    return $entity;
}

__PACKAGE__->meta->make_immutable;

1;

=encoding utf8

=head1 NAME

Mail::Builder::Attachment - Class for handling e-mail attachments

=head1 SYNOPSIS

  use Mail::Builder::Attachment;
  
  my $attachment1 = Mail::Builder::Attachment->new({
      file  => 'path/to/attachment.pdf',
      name  => 'LoveLetter.txt.vbs',
  });
  
  my $attachment2 = Mail::Builder::Attachment->new($fh);
  
  my $attachment_entity = $attachment1->serialize;

=head1 DESCRIPTION

This class handles e-mail attachments for Mail::Builder.

=head1 METHODS

=head2 Constructor

=head3 new

The constructor can be called in multiple ways

 Mail::Builder::Attachment->new({
     file       => Path | Path::Class::File | IO::File | FH | ScalarRef,
     [ name     => Attachment filename, ]
     [ mimetype => MIME type, ]
 })
 OR
 Mail::Builder::Image->new(
    Path | Path::Class::File | IO::File | FH | ScalarRef
    [, Attachment filename [, MIME type ]]
 )

See L<Accessors> for more details.

=head2 Public Methods

=head3 serialize

Returns the attachment as a L<MIME::Entity> object.

=head3 filename

If possible, returns the filename of the attachment file as a
L<Path::Class::File> object.

=head3 filecontent

Returns the content of the attachment file.

=head3 filehandle

If possible, returns a filehandle for the attachment file as a
L<IO::File> object.

=head2 Accessors

=head3 name

Name of the attachment as used in the e-mail message. If no name is provided
the current filename will be used.

=head3 mimetype

Mime type of the attachment.

If not provided the mime type is determined by analyzing the filename
extension.

=head3 file

Attachment file. Can be a

=over

=item * Path (or a Path::Class::File object)

=item * Filehandle (or an IO::File object)

=item * ScalarRef containing the attachment data

=back

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=cut
