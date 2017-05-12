package Lego::Part::Image::PeeronCom;

# Pragmas.
use base qw(Lego::Part::Image);
use strict;
use warnings;

# Modules.
use Error::Pure qw(err);

# Version.
our $VERSION = 0.05;

# Get image URL.
sub image_url {
	my $self = shift;
	if (! defined $self->{'part'}->color) {
		err "Color doesn't defined.";
	}
	if (! defined $self->{'part'}->design_id) {
		err "Design ID doesn't defined.";
	}
	my $url = sprintf 'http://media.peeron.com/ldraw/images/%d/100/%s.png',
		$self->{'part'}->color, $self->{'part'}->design_id;
	return $url;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Lego::Part::Image::PeeronCom - Lego part image class for peeron.com.

=head1 SYNOPSIS

 use Lego::Part::Image::PeeronCom;
 my $obj = Lego::Part::Image::PeeronCom->new;
 my $image = $obj->image;
 my $image_url = $obj->image_url;

=head1 METHODS

=over 8

=item * C<new()>

 Constructor.
 Returns object.

=over 8

=item * C<part>

 Lego::Part object.
 It is required.
 Default value is undef.

=back

=item * C<image()>

 Get image.
 Not implemented now.

=item * C<image_url()>

 Get image URL.
 Returns string with image URL.

=back

=head1 ERRORS

 new():
         From Lego::Part::Image::new():
                 Parameter 'part' is required.
                 Parameter 'part' must be Lego::Part object.
                 From Class::Utils::set_params():
                         Unknown parameter '%s'.

 image():
         This is abstract class. image() method not implemented.

 image_url():
         Color doesn't defined.
         Design ID doesn't defined.

=head1 EXAMPLE

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Lego::Part;
 use Lego::Part::Image::PeeronCom;

 # Object.
 my $obj = Lego::Part::Image::PeeronCom->new(
         'part' => Lego::Part->new(
                'color' => 1,
                'design_id' => '3003',
         ),
 );

 # Get image URL.
 my $image_url = $obj->image_url;

 # Print out.
 print "Part with design ID '3003' and color '1' URL is: ".$image_url."\n";

 # Output:
 # Part with design ID '3003' and color '1' URL is: http://media.peeron.com/ldraw/images/1/100/3003.png

=begin html

<img src="http://media.peeron.com/ldraw/images/1/100/3003.png" alt="Lego brick with design ID '3003' and color '1'." />

=end html

=head1 DEPENDENCIES

L<Error::Pure>,
L<Lego::Part::Image>.

=head1 SEE ALSO

=over

=item L<Lego::Part::Image>

Lego part image abstract class.

=item L<Lego::Part::Image::LegoCom>

Lego part image class for lego.com.

=item L<Lego::Part::Image::LugnetCom>

Lego part image class for lugnet.com.

=item L<Task::Lego>

Install the Lego modules.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Lego-Part-Image>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.05

=cut
