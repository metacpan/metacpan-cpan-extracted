# E2::Superdoc
# Jose M. Weeks <jose@joseweeks.com>
# 07 August 2003
#
# See bottom for pod documentation.

package E2::Superdoc;

use 5.006;
use strict;
use warnings;
use Carp;

use E2::Node;

our @ISA = "E2::Node";
our $VERSION = "0.34";
our $DEBUG; *DEBUG = *E2::Interface::DEBUG;

# Prototypes

sub new;
sub clear;

sub text;

# Private

sub type_as_string;
sub twig_handlers;

# Object Methods

sub new {
	my $arg   = shift;
	my $class = ref( $arg ) || $arg;
	my $self  = $class->SUPER::new();

	# See clear for the other members of $self

	$self->clear;
	return $self;
}

sub clear {
	my $self = shift	or croak "Usage: clear E2SUPERDOC";

	warn "E2::Superdoc::clear\n"	if $DEBUG > 1;

	$self->{text} = undef;

	# Now clear parent

	return $self->SUPER::clear;
}

sub text {
	my $self = shift	or croak "Usage: tetx E2SUPERDOC";

	return $self->{text};
}

sub twig_handlers {
	my $self = shift or croak "Usage: twig_handlers E2SUPERDOC";

	return (

		'node/superdoctext' => sub {
			(my $a, my $b) = @_;
			$self->{text} = $b->text;
		}
	);
}

sub type_as_string {
	return 'superdoc';
}

1;
__END__
		
=head1 NAME

E2::E2Node - A module for fetching data and manipulating e2nodes on L<http://everything2.com>.

=head1 SYNOPSIS

	use E2::Superdoc;

	my $superdoc = new E2::Superdoc;

	$superdoc->login( "username", "password" ); # See E2::Interface

	if( $superdoc->load( "nate and dem bones" ) ) {    # See E2::Node
		print $superdoc->title . " :\n\n";         # See E2::Node
		print $superdoc->text . "\n";
	}

	# That's it, folks.

=head1 DESCRIPTION

This module provides an interface to L<http://everything2.com>'s superdocs. It inherits L<E2::Node|E2::Node>.

The XML output of a superdoc is basically just the HTML that the superdoc spits out. This output is available via the method C<text> once a superdoc has been C<load>ed.

=head1 CONSTRUCTOR

=over

=item new

C<new> creates a new C<E2::Superdoc> object. Until that object is logged in in one way or another (see L<E2::Interface>), it will use the "Guest User" account.

=back

=head1 METHODS

=over

=item $superdoc-E<gt>clear

C<clear> clears all the information currently stored in $superdoc.

=item $superdoc-E<gt>text

C<text> returns the superdoc text of the currently-loaded superdoc.

=back

=head1 SEE ALSO

L<E2::Interface>,
L<E2::Node>,
L<http://everything2.com>,
L<http://everything2.com/?node=clientdev>

=head1 AUTHOR

Jose M. Weeks E<lt>I<jose@joseweeks.com>E<gt> (I<Simpleton> on E2)

=head1 COPYRIGHT

This software is public domain.

=cut
