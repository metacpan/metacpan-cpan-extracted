package Lego::Part::Image::LugnetCom;

use base qw(Lego::Part::Image);
use strict;
use warnings;

use Error::Pure qw(err);

our $VERSION = 0.06;

# Get image URL.
sub image_url {
	my $self = shift;

	if (! defined $self->{'part'}->design_id) {
		err "Design ID doesn't defined.";
	}
	my $url = sprintf 'http://img.lugnet.com/ld/%s.gif',
		$self->{'part'}->design_id;

	return $url;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Lego::Part::Image::LugnetCom - Lego part image class for lugnet.com.

=head1 SYNOPSIS

 use Lego::Part::Image::LugnetCom;

 my $obj = Lego::Part::Image::LugnetCom->new;
 my $image = $obj->image;
 my $image_url = $obj->image_url;

=head1 METHODS

=head2 C<new>

 my $obj = Lego::Part::Image::LugnetCom->new;

Constructor.

=over 8

=item * C<part>

L<Lego::Part> object.

It is required.

Default value is undef.

=back

Returns instance of object.

=head2 C<image>

 my $image = $obj->image;

Get image.

Not implemented now.

=head2 C<image_url>

 my $image_url = $obj->image_url;

Get image URL.

Returns string with image URL.

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
         Design ID doesn't defined.

=head1 EXAMPLE

=for comment filename=link_for_lugnet_com.pl

 use strict;
 use warnings;

 use Lego::Part;
 use Lego::Part::Image::LugnetCom;

 # Object.
 my $obj = Lego::Part::Image::LugnetCom->new(
         'part' => Lego::Part->new(
                'design_id' => '3003',
         ),
 );

 # Get image URL.
 my $image_url = $obj->image_url;

 # Print out.
 print "Part with design ID '3003' URL is: ".$image_url."\n";

 # Output:
 # Part with design ID '3003' URL is: http://img.lugnet.com/ld/3003.gif

=begin html

<img src="http://img.lugnet.com/ld/3003.gif" alt="Lego brick with design ID '3003'." />

=end html

=head1 DEPENDENCIES

L<Error::Pure>,
L<Lego::Part::Image>.

=head1 SEE ALSO

=over

=item L<Lego::Part::Image>

Lego part image abstract class.

=item L<Lego::Part::Image::PeeronCom>

Lego part image class for peeron.com.

=item L<Lego::Part::Image::LegoCom>

Lego part image class for lego.com.

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
