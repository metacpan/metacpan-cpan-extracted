package Image::Resize::Path;
{
  $Image::Resize::Path::VERSION = '0.01';
}

use strict;
use warnings;
use base qw(Class::Accessor);

use GD;
use GD::Image;
use Carp qw(croak carp);

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# STATIC METHODS
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

sub new
# Purpose: Constructor
# Input:   Ref/String of class
#          Hash of parameters
# Output:  Ref to instance
{
    my ( $class, %params) = @_;

    my $self = bless {}, ref($class) || $class;

    $self->_init(\%params);

    return $self;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# PUBLIC METHODS 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

__PACKAGE__->mk_accessors(qw(src_path dest_path));

sub resize_images
# Purpose: Resizes images in a directory
# Input:   Ref/String of class
# Output:  An array ref of images resized
{
    my ($self, $width, $height) = @_;

    if ($width && $height)
    {
        return $self->_resize_images($width, $height);
    }
    else
    {
        croak('A width and height must be specified');
    }
    
}

sub supported_images
# Purpose: An accessor to for supported_images
# Input:   Ref of self
#          Array ref of supported image extensions
# Output:  Hash ref of support image extensions
{
    my ($self, $images_ar) = @_;

    if ( $images_ar )
    {
        if (ref $images_ar eq 'ARRAY' )
        {
            %{$self->{supported_images}} = map { $_ => 1 } @{$images_ar};        
        }
        else
        {
            carp "Parameter must be an array ref. Example: ['gif','jpg']";
            return;
        }
    }

    return $self->{supported_images};
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# PRIVATE METHODS
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

sub _init
# Purpose: Initializes object state
# Input:   Ref to self
#          Hash ref of parameters
# Output:  Ref to to self
{
    my ($self, $params) = @_;

    $self->src_path( $params->{src_path} || undef );
    $self->dest_path ( $params->{dest_path} || undef);
    $self->supported_images( ['jpg', 'gif', 'png' ] );

    return $self;
}

sub _read_path
# Purpose: Generates an array ref of valid files to resize
# Input:   Ref to self
# Output:  An array ref of files
{
    my ($self) = @_;
    
    return if !$self->src_path;

    opendir(DIR, $self->src_path) || die "Unable to open directory: $!\n"; 

    my @files = ();

    foreach my $file(readdir(DIR))
    {
        if (my $ext = $self->_validate_file($file))
        {
            push @files, [$file, $ext];
        }
    }

    close DIR;

    return \@files;
}

sub _resize_images
# Purpose: Generates an array ref of valid files to resize
# Input:   Ref to self
# Output:  An array ref of files
{
    my ($self, $width, $height) = @_;

    my $dest_path = $self->dest_path;
    my $src_path  = $self->src_path;

    if ( $src_path && -e $dest_path )
    {
        if ( $src_path eq $dest_path )
        {
            croak ("The source path equals the dest path!");
            return;
        }

        my $images_ar = $self->_read_path;
        my @modified_images = ();

        for my $image_data ( @{$images_ar} )
        {
            my $file_name   = $image_data->[0];
            my $ext         = $image_data->[1];
            my $src_image_obj   = GD::Image->new($src_path . '/' . $file_name);

            my ($img_width, $img_height)   = $src_image_obj->getBounds;

            my $dest_image_obj  = GD::Image->new($width, $height);

            $dest_image_obj->copyResampled(
                    $src_image_obj,
                    0, 0,               
                    0, 0,               
                    $width, $height,    
                    $img_width, $img_height
                );

            #$file_name =~ s/$ext/png/o;
            open (OUT, '>', $dest_path . '/' . $file_name) || croak ("There was a problem opening the file: $file_name $!");
            binmode OUT;

            if ( eval{ $dest_image_obj->can($ext) } )
            { 
                print OUT $dest_image_obj->$ext;
                push @modified_images, $file_name;
            }

            close OUT;

            if ( $@ )
            {
                croak($@);
                return;
            }

            
        }

        return @modified_images;
    }
    else
    {
        croak('A destination path must be set');
    }

}

sub _validate_file
# Purpose: Validates that a file has a proper extension for resizing
# Input:   Ref to self
#          String to file name
# Output:  Returns file name or undef
{
    my ($self, $file) = @_;

    my $src_path = $self->src_path;

    my $full_image_path = $src_path . '/' . $file;

    if (-e $full_image_path && $file =~ m/.+\.(.{3})$/)
    {
        my $ext = $1;             
        return $ext if (defined $self->{supported_images}->{$ext} && $self->{supported_images}->{$ext} );
    }
    return 0;
}

1;



=pod

=head1 NAME

Image::Resize::Path - A lightweight wrapper to GD for mass image resizing

=head1 VERSION

version 0.01

=head1 SYNOPSIS

use Image::Resize::Path;

my $image_obj = Image::Resize::Path->new;
$image_obj->supported_images(['jpg']);

my $path = './test_data';

$test_obj->src_path('/src');
$test_obj->dest_path('/dest');
$test_obj->resize_images(100,100);

=head1 DESCRIPTION

Inspired by Image::Resize

=head1 STATIC METHODS

sub new()

    Purpose: Constructor
    Input:   Ref/String of class
             Hash of parameters
    Output:  Ref to instance

=head1 PUBLIC METHODS

dest_path()

    Purpose: An accessor for dest_path. This must be set.
    Input:   A string/path value.
    Output:  The current destination path.

resize_images()

    Purpose: Resizes images in a directory.
    Input:   Ref/String of class.
    Output:  An array ref of images resized.

supported_images()

    Purpose: An accessor to for supported_images.
    Input:   Ref of self.
             Array ref of supported image extensions.
    Output:  Hash ref of support image extensions.

src_path()

    Purpose: An accessor for dest_path. This must be set.
    Input:   A string/path value.
    Output:  The current source path.

=head1 AUTHOR

Logan Bell <logan@orchardtech.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Logan Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

# ABSTRACT: A lightweight wrapper to GD for mass image resizing






















