package Image::Checkerboard;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Imager;
use Imager::Fill;
use List::MoreUtils qw(none);

our $VERSION = 0.05;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Background color.
	$self->{'bg'} = 'black';

	# Flip flag.
	$self->{'flip'} = 1;

	# Foreground color.
	$self->{'fg'} = 'white';

	# Sizes.
	$self->{'width'} = 1920;
	$self->{'height'} = 1080;

	# Image type.
	$self->{'type'} = 'bmp';

	# Process params.
	set_params($self, @params);

	# Flip stay.
	$self->{'_flip_stay'} = 0;

	# Imager object.
	$self->{'_imager'} = Imager->new(
		'xsize' => $self->{'width'},
		'ysize' => $self->{'height'},
	);

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
	} else {
		$suffix = $self->{'type'};
	}

	# Fill.
	my $fill = Imager::Fill->new(
		'hatch' => 'check4x4',
		'fg' => $self->{'_flip_stay'} ? $self->{'fg'} : $self->{'bg'},
		'bg' => $self->{'_flip_stay'} ? $self->{'bg'} : $self->{'fg'},
	);
	$self->{'_flip_stay'} = $self->{'_flip_stay'} == 1 ? 0 : 1;

	# Add checkboard.
	$self->{'_imager'}->box('fill' => $fill);

	# Save file.
	my $ret = $self->{'_imager'}->write(
		'file' => $path,
		'type' => $suffix,
	);
	if (! $ret) {
		err "Cannot write file to '$path'.",
			'Error', $self->{'_imager'}->errstr;
	}
	
	return $suffix;
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

		err "Image type '$type' doesn't supported."
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Image::Checkerboard - Image generator for checkboards.

=head1 SYNOPSIS

 use Image::Checkerboard;

 my $image = Image::Checkerboard->new(%parameters);
 my $suffix = $image->create($path);
 my $type = $image->type($type);

=head1 METHODS

=head2 C<new>

 my $image = Image::Checkerboard->new(%parameters);

Constructor.

Returns instance of object.

=over 8

=item * C<bg>

 Background color.
 Default value is 'black'.

=item * C<flip>

 Flip flag. Means that each next video has reversed foreground and background.
 Default value is 1.

=item * C<fg>

 Foreground color.
 Default value is 'white'.

=item * C<height>

 Image height.
 Default value is 1080.

=item * C<type>

 Image type.
 Possible types are:
 - bmp
 - gif
 - jpeg
 - png
 - pnm
 - raw
 - sgi
 - tga
 - tiff
 Default value is 'bmp'.

=item * C<width>

 Image width.
 Default value is 1920.

=back

=head2 C<create>

 my $suffix = $image->create($path);

Create image.

Returns scalar value of supported file type.

=head2 C<type>

 my $type = $image->type($type);

Set/Get image type.

Returns actual type of image.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
 create():
         Cannot write file to '$path'.",
	         Error, %s
         Image type '%s' doesn't supported.

 type():
         Image type '%s' doesn't supported.


=head1 EXAMPLE

 use strict;
 use warnings;

 use File::Temp qw(tempfile);
 use Image::Checkerboard;

 # Temporary file.
 my (undef, $temp) = tempfile();

 # Object.
 my $obj = Image::Checkerboard->new;

 # Create image.
 my $type = $obj->create($temp);

 # Print out type.
 print $type."\n";

 # Unlink file.
 unlink $temp;

 # Output:
 # bmp

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Image-Checkerboard/master/images/ex1.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Image-Checkerboard/master/images/ex1.png" alt="Generated image" width="533px" height="300px" />
</a>

=end html

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Imager>,
L<Imager::Fill>,
L<List::MoreUtils>.

=head1 SEE ALSO

=over

=item L<Image::Random>

Perl class for creating random image.

=item L<Image::Select>

Perl class for creating random image.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Image-Checkerboard>.

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2012-2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
