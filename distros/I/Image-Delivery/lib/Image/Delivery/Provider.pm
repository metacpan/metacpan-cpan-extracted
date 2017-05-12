package Image::Delivery::Provider;

=pod

=head1 NAME

Image::Delivery::Provider - The abstract Image Provider class

=head1 DESCRIPTION

An Image Provider is a class that provides images in a way that
makes them usable within an L<Image::Delivery|Image::Delivery> system.

As well as the actual image data, it provides a variety of metadata
that allows the Image::Delivery object to name and store the image correctly.

=cut

use strict;
use Digest::MD5           ();
use Digest::TransformPath ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.14';
}





#####################################################################
# Static Methods

sub filetypes {
	'gif', 'jpg', 'png';
}





#####################################################################
# Constructor

# Should be implemented in a subclass
# sub new





#####################################################################
# Main Instance Methods

# Object identifier
# If the Provider doesn't provide an ID, use a Digest of the
# image as a default.
sub id {
	my $self = shift;
	return $self->{id} if $self->{id};

	# Create a default id from the image data
	my $image = $self->image;
	ref $image eq 'SCALAR' or return undef;
	$self->{id} = Digest::MD5::md5_hex( $$image );
}

# Return the image data
### Implemented in subclass
# sub image

# Determine the file-type of the image
sub content_type {
	my $self  = shift;
	return $self->{content_type} if $self->{content_type};

	# Generate the content_type from the image data.
	# We only need the first 32 bytes to do this.
	my $image = $self->image or return undef;
	my $head  = substr($$image, 0, 32);
	return $self->{content_type} = 'image/jpeg' if $head =~ /^\xFF\xD8/;
	return $self->{content_type} = 'image/gif'  if $head =~ /^GIF8[79]a/;
	return $self->{content_type} = 'image/png'  if $head =~ /^\x89PNG\x0d\x0a\x1a\x0a/;
	undef;
}

# Determine the extention to use
sub extension {
	my $self = shift;
	return $self->{extension} if $self->{extension};

	# Generate the extension from the content_type
	my $content_type = $self->content_type or return undef;
	my $extension = {
		'image/jpeg' => 'jpg',
		'image/gif'  => 'gif',
		'image/png'  => 'png',
		}->{$content_type} or return undef;
	$self->{extension} = $extension;
}

# Return the TransformPath for the Provider
sub TransformPath {
	my $self = shift;
	return $self->{TransformPath} if $self->{TransformPath};

	# Create a default TransformPath from the id
	my $id = $self->id or return undef;
	$self->{TransformPath} = Digest::TransformPath->new($id);
}





#####################################################################
# Coercion Support

sub __as_Digest_TransformPath { shift->TransformPath }

1;
