# ============================================================================
package Mail::Builder::Image;
# ============================================================================

use namespace::autoclean;
use Moose;
with qw(Mail::Builder::Role::File);
use Mail::Builder::TypeConstraints;

use Carp;

our $VERSION = $Mail::Builder::VERSION;

has 'id' => (
    is          => 'rw',
    isa         => 'Str',
    lazy_build  => 1,
    trigger     => sub { shift->clear_cache },
);

has 'mimetype' => (
    is          => 'rw',
    isa         => 'Mail::Builder::Type::ImageMimetype',
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
            $params->{id} = $_[1];
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
        && $filename->basename =~ m/\.(PNG|JPE?G|GIF)$/i) {
        $filetype = 'image/'.lc($1);
        $filetype = 'image/jpeg'
            if $filetype eq 'image/jpg';
    } else {
        my $filecontent = $self->filecontent;
        $filetype = $self->_check_magic_string($filecontent);
    }

    unless (defined $filetype) {
        croak('Could not determine the file type automatically and/or invalid file type (only image/png, image/jpeg an image/gif allowed)');
    }

    return $filetype;
}

sub _build_id {
    my ($self) = @_;

    my $filename = $self->filename;
    my $id;

    if (defined $filename) {
        $id = $filename->basename;
        $id =~ s/[.-]/_/g;
        $id =~ s/(.+)\.(JPE?G|GIF|PNG)$/$1/i;
    }

    unless (defined $id
        && $id !~ m/^\s*$/) {
        croak('Could not determine the image id automatically');
    }

    return $id;
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
        $value = $file;
    }

    my $entity = MIME::Entity->build(
        Disposition     => 'inline',
        Type            => $self->mimetype,
        Top             => 0,
        Id              => '<'.$self->id.'>',
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

Mail::Builder::Image - Class for handling inline images

=head1 SYNOPSIS

  use Mail::Builder::Image;
  
  my $image1 = Mail::Builder::Image->new({
      file  => 'path/to/image.png',
      id    => 'location',
  });
  
  my $image2 = Mail::Builder::Image->new($fh);
  
  my $image1_entity = $image1->serialize;

=head1 DESCRIPTION

This class handles inline images that should be displayed in html e-mail
messages.

=head1 METHODS

=head2 Constructor

=head3 new

The constructor can be called in multiple ways

 Mail::Builder::Image->new({
     file       => Path | Path::Class::File | IO::File | FH | ScalarRef,
     [ id       => Image id, ]
     [ mimetype => MIME type, ]
 })
 OR
 Mail::Builder::Image->new(
    Path | Path::Class::File | IO::File | FH | ScalarRef
    [, Image id [, MIME type ]]
 )

See L<Accessors> for more details.

=head2 Public Methods

=head3 serialize

Returns the image file as a L<MIME::Entity> object.

=head3 filename

If possible, returns the filename of the image file as a L<Path::Class::File>
object.

=head3 filecontent

Returns the content of the image file.

=head3 filehandle

If possible, returns a filehandle for the image file as a L<IO::File> object.

=head2 Accessors

=head3 id

ID of the file. If no id is provided the lowercase filename without the
extension will be used as the ID.

The ID is needed to reference the image in the e-mail body:

 <img src="cid:invitation_location"/>

=head3 mimetype

Mime type of the image. Valid types are

=over

=item * image/gif

=item * image/jpeg

=item * image/png

=back

If not provided the mime type is determined by analyzing the filename
extension and file content.

=head3 file

Image. Can be a

=over

=item * Path (or a Path::Class::File object)

=item * Filehandle (or an IO::File object)

=item * ScalarRef containing the image data

=back

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=cut

