package Lego::Part::Image;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Readonly;
use Scalar::Util qw(blessed);

# Constants.
Readonly::Scalar our $EMPTY_STR => q{};

our $VERSION = 0.06;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;	

	# Part object.
	$self->{'part'} = undef;

	# Process parameters.
	set_params($self, @params);

	# Check part object.
	if (! defined $self->{'part'}) {
		err "Parameter 'part' is required.";
	}
	if (! blessed($self->{'part'})
		|| ! $self->{'part'}->isa('Lego::Part')) {

		err "Parameter 'part' must be Lego::Part object.";
	}

	# Object.
	return $self;
}

# Get image.
sub image {
	my $self = shift;

	# TODO Implement getting of image with cache.
	err "This is abstract class. image() method not implemented.";

	return;
}

# Get image URL.
sub image_url {
	my $self = shift;

	err "This is abstract class. image_url() method not implemented.";

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Lego::Part::Image - Lego part image abstract class.

=head1 SYNOPSIS

 use Lego::Part::Image;

 my $obj = Lego::Part::Image->new;
 $obj->image;
 $obj->image_url;

=head1 METHODS

=head2 * C<new>

 my $obj = Lego::Part::Image->new;

Constructor.

=over 8

=item * C<part>

L<Lego::Part> object.

It is required.

Default value is undef.

=back

Returns instance of object.

=head2 C<image>

 $obj->image;

Abstract method for getting image.

=head2 C<image_url>

 $obj->image_url;

Abstract method for getting image url.

=head1 ERRORS

 new():
         Parameter 'part' is required.
         Parameter 'part' must be Lego::Part object.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 image():
         This is abstract class. image() method not implemented.

 image_url():
         This is abstract class. image_url() method not implemented.

=head1 EXAMPLE

=for comment filename=abstract_class.pl

 use strict;
 use warnings;

 use Lego::Part;
 use Lego::Part::Image;

 # Error pure setting.
 $ENV{'ERROR_PURE_TYPE'} = 'Print';

 # Object.
 my $obj = Lego::Part::Image->new(
         'part' => Lego::Part->new(
                'color' => 'red',
                'design_id' => '3002',
         ),
 );

 # Get image.
 $obj->image;

 # Output:
 # Lego::Part::Image: This is abstract class. image() method not implemented.

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Readonly>,
L<Scalar::Util>.

=head1 SEE ALSO

=over

=item L<Lego::Part::Image::PeeronCom>

Lego part image class for peeron.com.

=item L<Lego::Part::Image::LegoCom>

Lego part image class for lego.com.

=item L<Lego::Part::Image::LugnetCom>

Lego part image class for lugnet.com.

=item L<Task::Lego>

Install the Lego modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Lego-Part-Image>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2015-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.06

=cut
