package Image::Random;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use File::Basename qw(fileparse);
use Imager;
use Imager::Color;
use List::MoreUtils qw(none);

our $VERSION = 0.09;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Background color.
	$self->{'color'} = undef;

	# Image type.
	$self->{'type'} = 'bmp';

	# Sizes.
	$self->{'height'} = 1080;
	$self->{'width'} = 1920;

	# Process params.
	set_params($self, @params);

	# Image magick object.
	$self->_imager;

	# Check color.
	if (defined $self->{'color'}
		&& ! $self->{'color'}->isa('Imager::Color')) {

		err 'Bad background color definition. Use Imager::Color '.
			'object.';
	}

	# Check type.
	if (defined $self->{'type'}) {
		$self->_check_type($self->{'type'});
	}

	# Object.
	return $self;
}

# Create image.
sub create {
	my ($self, $path) = @_;

	# Background color.
	my $background;
	if ($self->{'color'}) {
		$background = $self->{'color'};
	} else {
		$background = Imager::Color->new(int rand 256, int rand 256,
			int rand 256);
	}

	# Create image.
	$self->{'i'}->box(
		'color' => $background,
		'filled' => 1,
	);

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

	# Save.
	my $ret = $self->{'i'}->write(
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
		$self->_imager;
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

# Create imager object.
sub _imager {
	my $self = shift;
	$self->{'i'} = Imager->new(
		'xsize' => $self->{'width'},
		'ysize' => $self->{'height'},
	);
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Image::Random - Perl class for creating random image.

=head1 SYNOPSIS

 use Image::Random;

 my $obj = Image::Random->new(%parameters);
 my $type = $obj->create($output_path);
 my ($width, $height) = $obj->sizes($new_width, $new_height);
 my $type = $obj->type($new_type);

=head1 METHODS

=head2 C<new>

 my $obj = Image::Random->new(%parameters);

Constructor.

=over 8

=item * C<color>

 Color of image.
 Default value is undef.
 Undefined value means random color.

=item * C<height>

 Height of image.
 Default value is 1920.

=item * C<type>

 Image type.
 List of supported types: bmp, gif, jpeg, png, pnm, raw, sgi, tga, tiff
 Default value is 'bmp'.

=item * C<width>

 Width of image.
 Default value is 1080.

=back

=head2 C<create>

 my $type = $obj->create($output_path);

Create image.

Returns scalar value of supported file type.

=head2 C<sizes>

 my ($width, $height) = $obj->sizes($new_width, $new_height);

Set/Get image sizes.

Both parameters are optional, used only for set sizes.

Returns actual width and height.

=head2 C<type>

 my $type = $obj->type($new_type);

Set/Get image type.

Parameter $new_type is optional, used only for setting.

Returns actual type of image.

=head1 ERRORS

 new():
         Bad background color definition. Use Imager::Color object.
         Image type '%s' doesn't supported.
         From Class::Utils:
                 Unknown parameter '%s'.

 create():
         Cannot write file to '$path'.
                 Error, %s
         Image type '%s' doesn't supported.

=head1 EXAMPLE

 use strict;
 use warnings;

 use File::Temp qw(tempfile);
 use Image::Random;

 # Temporary file.
 my (undef, $temp) = tempfile();

 # Object.
 my $obj = Image::Random->new;

 # Create image.
 my $type = $obj->create($temp);

 # Print out type.
 print $type."\n";

 # Unlink file.
 unlink $temp;

 # Output:
 # bmp

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<File::Basename>,
L<Imager>,
L<Imager::Color>,
L<List::MoreUtils>.

=head1 SEE ALSO

=over

=item L<Data::Random>

Perl module to generate random data

=item L<Image::Select>

Perl class for creating random image.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Image-Random>.

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2013-2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.09

=cut
