package Image::Select;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use File::Basename qw(fileparse);
use File::Find::Rule qw(:MMagic);
use Imager;
use List::MoreUtils qw(none);

# Version.
our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Debug.
	$self->{'debug'} = 0;

	# Loop.
	$self->{'loop'} = 0;

	# Path to images.
	$self->{'path_to_images'} = undef;

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

	# Check path to images.
	if (! defined $self->{'path_to_images'}
		|| ! -d $self->{'path_to_images'}) {

		err "Parameter 'path_to_images' is required.";
	}

	# Load images.
	$self->{'_images_to_select'} = [
		sort File::Find::Rule->file->magic(
			'image/bmp',
			'image/gif',
			'image/jpeg',
			'image/png',
			'image/tiff',
			'image/x-ms-bmp',
			'image/x-portable-pixmap',
			# XXX tga?
			# XXX raw?
			# XXX sgi?
		)->in($self->{'path_to_images'}),
	];
	if (! @{$self->{'_images_to_select'}}) {
		err 'No images.';
	}
	$self->{'_images_index'} = 0;

	# Object.
	return $self;
}

# Create image.
sub create {
	my ($self, $path) = @_;

	# Load next image.
	my $i = Imager->new;
	if ($self->{'_images_index'} > $#{$self->{'_images_to_select'}}) {
		if ($self->{'loop'}) {
			$self->{'_images_index'} = 0;
		} else {
			return;
		}
	}
	my $file = $self->{'_images_to_select'}->[$self->{'_images_index'}];
	if (! -r $file) {
		err "No file '$file'.";
	}
	my $ret = $i->read('file' => $file);
	if (! $ret) {
		err "Cannot read file '$file'.",
			'Error', Imager->errstr;
	}
	$self->{'_images_index'}++;

	# Get type.
	my $suffix;
	if (! defined $self->{'type'}) {

		# Get suffix.
		(my $name, undef, $suffix) = fileparse($path, qr/\.[^.]*/ms);
		$suffix =~ s/^\.//ms;

		# Jpeg.
		if ($suffix eq 'jpg') {
			$suffix = 'jpeg';
		}

		# Check type.
		$self->_check_type($suffix);
	} else {
		$suffix = $self->{'type'};
	}

	# Scale.
	my $new_i = $i->scale(
		'xpixels' => $self->{'width'},
		'ypixels' => $self->{'height'},
	);
	if (! $new_i) {
		err "Cannot resize image from file '$file'.",
			'Error', Imager->errstr;
	}

	# Save.
	if ($self->{'debug'}) {
		print "Path: $path\n";
	}
	$ret = $new_i->write(
		'file' => $path,
		'type' => $suffix,
	);
	if (! $ret) {
		err "Cannot write file to '$path'.",
			'Error', Imager->errstr;
	}

	return $suffix;
}

# Set/Get image sizes.
sub sizes {
	my ($self, $width, $height) = @_;
	if ($width && $height) {
		$self->{'width'} = $width;
		$self->{'height'} = $height;
	}
	return ($self->{'width'}, $self->{'height'});
}

# Set/Get image type.
sub type {
	my ($self, $type) = @_;
	if ($type) {
		$self->_check_type($type);
		$self->{'type'} = $type;
	}
	return $self->{'type'};
}

# Check supported image type.
sub _check_type {
	my ($self, $type) = @_;
	
	# Check type.
	if (none { $type eq $_ } ('bmp', 'gif', 'jpeg', 'png',
		'pnm', 'raw', 'sgi', 'tga', 'tiff')) {

		err "Image type '$type' doesn't supported.";
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Image::Select - Selecting image from images directory.

=head1 SYNOPSIS

 use Image::Select;
 my $obj = Image::Select->new(%parameters);
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

=item * C<path_to_images>

 Path to images.
 It is required.
 Default value is undef.

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
         Parameter 'path_to_images' is required.
         Image type '%s' doesn't supported.
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
 use Image::Select;

 # Temporary directory to random images.
 my $tempdir = tempdir(CLEANUP => 1);

 # Create temporary images.
 my $rand = Image::Random->new;
 for my $i (1 .. 5) {
         $rand->create(catfile($tempdir, $i.'.png'));
 }

 # Object.
 my $obj = Image::Select->new(
         'path_to_images' => $tempdir,
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
 use Image::Select;

 # Temporary directory for random images.
 my $tempdir = tempdir(CLEANUP => 1);

 # Create temporary images.
 my $rand = Image::Random->new;
 for my $i (1 .. 5) {
         $rand->create(catfile($tempdir, $i.'.png'));
 }

 # Object.
 my $obj = Image::Select->new(
         'loop' => 0,
         'path_to_images' => $tempdir,
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
L<File::Basename>,
L<File::Find::Rule>,
L<File::Find::Rule::MMagic>,
L<Imager>,
L<List::MoreUtils>.

=head1 SEE ALSO

=over

=item L<Image::Random>

Perl class for creating random image.

=item L<Image::Select::Array>

Selecting image from list with checking.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Image-Select>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2014-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.04

=cut
