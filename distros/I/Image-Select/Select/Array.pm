package Image::Select::Array;

# Pragmas.
use base qw(Image::Select);
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Error::Pure qw(err);

# Version.
our $VERSION = 0.04;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Debug.
	$self->{'debug'} = 0;

	# Loop.
	$self->{'loop'} = 0;

	# Image list.
	$self->{'image_list'} = [];

	# Image type.
	$self->{'type'} = 'bmp';

	# Sizes.
	$self->{'height'} = 1080;
	$self->{'width'} = 1920;

	# Process params.
	set_params($self, @params);

	# Check type.
	if (defined $self->{'type'}) {
		$self->_check_type($self->{'type'});
	}

	# Check images array.
	if (! defined $self->{'image_list'}
		|| ref $self->{'image_list'} ne 'ARRAY') {

		err "Parameter 'image_list' must be reference to array ".
			'with images.';
	}

	# Check images.
	if (! @{$self->{'image_list'}}) {
		err 'No images.';
	}

	# Check images path.
	foreach my $image (@{$self->{'image_list'}}) {
		if (! -r $image) {
			err "Image '$image' doesn't readable.";
		}
	}

	# Images to select.
	$self->{'_images_to_select'} = $self->{'image_list'};
	$self->{'_images_index'} = 0;

	# Object.
	return $self;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Image::Select::Array - Selecting image from list with checking.

=head1 SYNOPSIS

 use Image::Select::Array;
 my $obj = Image::Select::Array->new(%parameters);
 my $type = $obj->create($output_path);
 my ($width, $height) = $obj->sizes($new_width, $new_height);
 my $type = $obj->type($new_type);

=head1 METHODS

=over 8

=item C<new(%parameters)>

 Constructor.

=over 8

=item * C<debug>

 Debug mode.
 Default value is 0.

=item * C<height>

 Height of image.
 Default value is 1920.

=item * C<loop>

 Returns images in loop.
 Default value is 0.

=item * C<image_list>

 List of images in array reference.
 It is required.
 Default value is [].

=item * C<type>

 Image type.
 List of supported types: bmp, gif, jpeg, png, pnm, raw, sgi, tga, tiff
 Default value is undef.

=item * C<width>

 Width of image.
 Default value is 1080.

=back

=item C<create($path)>

 Create image.
 Returns scalar value of supported file type.

=item C<sizes([$width, $height])>

 Set/Get image sizes.
 Returns actual width and height.

=item C<type([$type])>

 Set/Get image type.
 Returns actual type of image.

=back

=head1 ERRORS

 new():
         No images.
         Image '%s' doesn't readable.
         Image type '%s' doesn't supported.
         Parameter 'image_list' must be reference to array with images.
         Class::Utils:
                 Unknown parameter '%s'.

 create():
         Cannot read file '%s'.
                 Error, %s
         Cannot resize image from file '%s'.
                 Error, %s
         Cannot write file to '$path'.
                 Error, %s
         No file '%s'.
         Image type '%s' doesn't supported.

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use File::Spec::Functions qw(catfile);
 use File::Temp qw(tempfile tempdir);
 use Image::Random;
 use Image::Select::Array;

 # Temporary directory to random images.
 my $tempdir = tempdir(CLEANUP => 1);

 # Create temporary images.
 my $rand = Image::Random->new;
 my @images;
 for my $i (1 .. 5) {
         my $image = catfile($tempdir, $i.'.png');
         $rand->create($image);
         push @images, $image;
 }

 # Object.
 my $obj = Image::Select::Array->new(
         'image_list' => \@images,
 );

 # Temporary file.
 my (undef, $temp) = tempfile();

 # Create image.
 my $type = $obj->create($temp);

 # Print out type.
 print $type."\n";

 # Unlink file.
 unlink $temp;

 # Output:
 # bmp

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use File::Spec::Functions qw(catfile);
 use File::Temp qw(tempfile tempdir);
 use Image::Random;
 use Image::Select::Array;

 # Temporary directory for random images.
 my $tempdir = tempdir(CLEANUP => 1);

 # Create temporary images.
 my $rand = Image::Random->new;
 my @images;
 for my $i (1 .. 5) {
         my $image = catfile($tempdir, $i.'.png');
         $rand->create(catfile($tempdir, $i.'.png'));
         push @images, $image;
 }

 # Object.
 my $obj = Image::Select::Array->new(
         'image_list' => \@images,
         'loop' => 0,
 );

 # Temporary file.
 my (undef, $temp) = tempfile();

 # Create image.
 while (my $type = $obj->create($temp)) {

         # Print out type.
         print $type."\n";
 }

 # Unlink file.
 unlink $temp;

 # Output:
 # bmp
 # bmp
 # bmp
 # bmp
 # bmp

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Image::Select>.

=head1 SEE ALSO

=over

=item L<Image::Random>

Perl class for creating random image.

=item L<Image::Select>

Selecting image from images directory.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Image-Select>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.04

=cut
