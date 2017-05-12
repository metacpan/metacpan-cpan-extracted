# E2::Usergroup
# Jose M. Weeks <jose@joseweeks.com>
# 05 June 2003
#
# See bottom for pod documentation.

package E2::Usergroup;

use 5.006;
use strict;
use warnings;
use Carp;

use E2::Node;

our @ISA = "E2::Node";
our $VERSION = "0.32";
our $DEBUG; *DEBUG = *E2::Interface::DEBUG;

# Prototypes

sub new;
sub clear;

sub description;
sub list_members;
sub list_weblog;

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
	my $self = shift	or croak "Usage: clear E2USERGROUP";

	warn "E2::Usergroup::clear\n"	if $DEBUG > 1;
	
	@{ $self->{members} } = ();
	@{ $self->{weblog} }  = ();
	$self->{description}  = undef;

	# Now clear parent

	return $self->SUPER::clear;
}

sub twig_handlers {
	my $self = shift or croak "Usage: twig_handlers E2USERGROUP";

	return (
		'description' => sub {
			(my $a, my $b) = @_;
			$self->{description} = $b->text;
		},
		'weblog/e2link' => sub {
			(my $a, my $b) = @_;
			push @{ $self->{weblog} }, {
				title => $b->text,
				id    => $b->{att}->{node_id}
			};
		},
		'usergroup/e2link' => sub {
			(my $a, my $b) = @_;
			push @{ $self->{members} }, {
				name  => $b->text,
				id    => $b->{att}->{node_id}
			};
		}
	);
}			

sub type_as_string {
	return 'usergroup';
}

sub description {
	my $self = shift	or croak "Usage: description E2USERGROUP";
	return $self->{description};
}

sub list_members {
	my $self = shift	or croak "Usage: list_members E2USERGROUP";
	return undef if !$self->node_id;
	return @{ $self->{members} };
}

sub list_weblog {
	my $self = shift	or croak "Usage: list_weblog E2USERGROUP";
	return undef if !$self->node_id;
	return @{ $self->{weblog} };
}

1;
__END__
		
=head1 NAME

E2::Usergroup - A module for loading usergroup lists from L<http://everything2.com>.

=head1 SYNOPSIS

	use E2::Usergroup;

	my $group = new E2::Usergroup;

	$group->login( "username", "password" ); # See E2::Interface

	if( $group->load( "edev" ) ) {                       # See E2::Node
		print "Listing for group " . $group->title;  # See E2::Node
		print "\n(Description: " . $group->description . ")";
		print "\nMembers:\n";
		foreach my $m ($group->list_members) {
			print "  " . $m->{name} . "\n";
		}

		# Note, this weblog listing will only be available to
		# members of this group.

		print "\nWeblog:\n";
		foreach my $w ($group->list_weblog) {
			print "  " . $w->{title} . "\n";
		}
	}

=head1 DESCRIPTION

This module provides access to L<http://everything2.com>'s usergroup lists. It inherits L<E2::Node|E2::Node>.

=head1 CONSTRUCTOR

=over

=item new

C<new> creates a new C<E2::Usergroup> object. Until that object is logged in in one way or another (see L<E2::Interface>), it will use the "Guest User" account, and will be limited in what information it can fetch and which operations it can perform.

=back

=head1 METHODS

=over

=item $group-E<gt>clear

C<clear> clears all the information currently stored in $group. 

=item $group-E<gt>description

This method returns the description string of the currently-loaded usergroup. It returns C<undef> if no usergroup is loaded.

=item $group-E<gt>list_members

This method returns a list of hashrefs corresponding to each member of the currently-loaded usergroup. It returns an empty list if the usergroup has no members, and C<undef> if no usergroup is loaded.

The keys to the returned hashrefs are the following:

	name	# Username
	id	# user_id

=item $group-E<gt>list_weblog

This method returns a list of hashrefs corresponding to each item in the currently-loaded usergroup's weblog. Keys to the hashrefs are the following:

	title	# Title of the weblogged node
	id	# node_id of the weblogged node

NOTE: To recieve this weblog, the user must be logged in and must be a member of this usergroup. If the usergroup has no weblog or if the user has no access to it, this method returns an empty list. If there is no usergroup currently loaded, this method returns C<undef>.

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
