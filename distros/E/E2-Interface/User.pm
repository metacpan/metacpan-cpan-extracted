# E2::User
# Jose M. Weeks <jose@joseweeks.com>
# 05 June 2003
#
# See bottom for pod documentation.

package E2::User;

use 5.006;
use strict;
use warnings;
use Carp;

use E2::Node;

our $VERSION = "0.32";
our @ISA = qw(E2::Node);
our $DEBUG; *DEBUG = *E2::Interface::DEBUG;

sub new;
sub clear;

sub name;
sub id;
sub alias;
sub alias_id;
sub text;
sub lasttime;
sub experience;
sub level;
sub level_string;
sub writeup_count;
sub cool_count;
sub image_url;
sub lastnode;
sub lastnode_id;
sub mission;
sub specialties;
sub motto;
sub employment;

sub groups;
sub bookmarks;

sub new { 
	my $arg   = shift;
	my $class = ref( $arg ) || $arg;
	my $self  = $class->SUPER::new();

	$self->clear;
	return $self;
}

sub clear {
	my $self = shift or croak "Usage: clear E2USER";

	warn "E2::User::clear\n"	if $DEBUG > 1;

	$self->{alias}		= undef;
	$self->{alias_id}	= undef;
	$self->{text}		= undef; # Homenode text
	$self->{lasttime}	= undef;
	$self->{experience}	= undef;
	$self->{level}		= undef; # Integer
	$self->{level_string}	= undef; # Ex: "3 (Acolyte)"
	$self->{writeup_num}	= undef;
	$self->{cool_num}	= undef;
	$self->{image}		= undef; # Relative URL
	$self->{lastnode}	= undef;
	$self->{lastnode_id}	= undef;
	$self->{mission}	= undef;
	$self->{specialties}	= undef;
	$self->{motto}		= undef;
	$self->{employment}	= undef;
	$self->{groups}		= ();	 # these are lists of hashrefs
	$self->{bookmarks}	= ();    # with the following keys:
					 #	o title
					 #	o id

	return $self->SUPER::clear;
}

sub type_as_string {
	return 'user';
};

sub twig_handlers {
	my $self = shift or croak "Usage: twig_handlers E2USER";

	return (
		'useralias/e2link' => sub {
			(my $a, my $b) = @_;
			$self->{alias} = $b->text;
			$self->{alias_id} = $b->{att}->{node_id};
		},
		'node/doctext' => sub {
			(my $a, my $b) = @_;
			$self->{text} = $b->text;
		},
		'experience' => sub {
			(my $a, my $b) = @_;
			$self->{experience} = $b->text;
		},
		'lasttime' => sub {
			(my $a, my $b) = @_;
			$self->{lasttime} = $b->text;
		},
		'level' => sub {
			(my $a, my $b) = @_;
			$self->{level} = $b->{att}->{value};
			$self->{level_string} = $b->text;
		},
		'writeups' => sub {
			(my $a, my $b) = @_;
			$self->{writeup_num} = $b->text;
		},
		'image' => sub {
			(my $a, my $b) = @_;
			$self->{image} = $b->text;
		},
		'lastnoded/e2link' => sub {
			(my $a, my $b) = @_;
			$self->{lastnode} = $b->text;
			$self->{lastnode_id} = $b->{att}->{node_id};
		},
		'cools' => sub {
			(my $a, my $b) = @_;
			$self->{cool_num} = $b->text;
		},
		'userstrings/mission' => sub {
			(my $a, my $b) = @_;
			$self->{mission} = $b->text;
		},
		'userstrings/specialties' => sub {
			(my $a, my $b) = @_;
			$self->{specialties} = $b->text;
		},
		'userstrings/motto' => sub {
			(my $a, my $b) = @_;
			$self->{motto} = $b->text;
		},
		'userstrings/employment' => sub {
			(my $a, my $b) = @_;
			$self->{employment} = $b->text;
		},
		'groupmembership/e2link' => sub {
			(my $a, my $b) = @_;
			push @{ $self->{groups} }, {
				title	=> $b->text,
				id	=> $b->{att}->{node_id}
			};
		},
		'bookmarks/e2link' => sub {
			(my $a, my $b) = @_;
			push @{ $self->{bookmarks} }, {
				title	=> $b->text,
				id	=> $b->{att}->{node_id}
			};
		}
	);
}

#---------------
# Access Members
#---------------

sub name {
	my $self = shift or croak "Usage: name E2USER";

	return $self->title;
}

sub id {
	my $self = shift or croak "Usage: id E2USER";

	return $self->node_id;
}

sub alias {
	my $self = shift or croak "Usage: alias E2USER";

	return $self->{alias};
}

sub alias_id {
	my $self = shift or croak "Usage: alias_id E2USER";

	return $self->{alias_id};
}

sub text {
	my $self = shift or croak "Usage: text E2USER";

	return $self->{text};
}

sub lasttime {
	my $self = shift or croak "Usage: lasttime E2USER";

	return $self->{lasttime};
}

sub experience {
	my $self = shift or croak "Usage: experience E2USER";

	return $self->{experience};
}

sub level {
	my $self = shift or croak "Usage: level E2USER";

	return $self->{level};
}

sub level_string {
	my $self = shift or croak "Usage: level_string E2USER";

	return $self->{level_string};
}

sub writeup_count {
	my $self = shift or croak "Usage: writeup_count E2USER";

	return $self->{writeup_num};
}

sub cool_count {
	my $self = shift or croak "Usage: cool_count E2USER";

	return $self->{cool_num};
}

sub image_url {
	my $self = shift or croak "Usage: image_url E2USER";

	return $self->{image};
}

sub lastnode {
	my $self = shift or croak "Usage: lastnode E2USER";

	return $self->{lastnode};
}

sub lastnode_id {
	my $self = shift or croak "Usage: lastnode_id E2USER";

	return $self->{lastnode_id};
}

sub mission {
	my $self = shift or croak "Usage: mission E2USER";

	return $self->{mission};
}

sub specialties {
	my $self = shift or croak "Usage: specialties E2USER";

	return $self->{specialties};
}

sub motto {
	my $self = shift or croak "Usage: motto E2USER";

	return $self->{motto};
}

sub employment {
	my $self = shift or croak "Usage: employment E2USER";

	return $self->{employment};
}

sub groups {
	my $self = shift or croak "Usage: groups E2USER";
	if( ! defined $self->{groups} ) { return (); }
	return @{ $self->{groups} };
}

sub bookmarks {
	my $self = shift or croak "Usage: bookmarks E2USER";
	if( ! defined $self->{bookmarks} ) { return (); }
	return @{ $self->{bookmarks} };
}

1;
__END__

=head1 NAME

E2::User - A module for loading user data and sorting and listing a user's writeups

=head1 SYNOPSIS


	use E2::User;

	# Display homenode info

	my $user = new E2::User;
	$user->load( "dem bones" ); # see E2::Node

	print $user->name;
	print "\nuser since: " . $user->createtime; # See E2::Node
	print "\nlast seen: " . $user->lasttime;
	print "\nnumber of writeups / XP: ";
	print $user->writeup_count . '/' . $user->experience;
	print "\nlevel: " . $user->level_string;
	print "\nC!s spent: " . $user->cool_count;
	print "\nmission drive within everything:\n\t";
	print $user->mission;
	print "\nspecialties:\n\t" . $user->specialties;
	print "\nschool/company:\n\t" . $user->employment;
	print "\nmotto:\n\t" . $user->motto;
	print "\nmember of:\n\t";

	foreach my $g ( $user->groups ) { print $g->{title} . ' '; }

	print "\nmost recent writeup:\n\t";
	print $user->lastnode;

	print "\n-------------------------------------\n\n";

	print $user->text;

	print "\n\nUser Bookmarks:\n";

	foreach my $g ( $user->bookmarks ) {
		print $g->{title};
		print "\n";
	}

=head1 DESCRIPTION

This module provides access to user information that is normally displayed on a user's homenode. It inherits L<E2::Node|E2::Node>.

NOTE: E2::Node provides $user-E<gt>createtime and other methods that might be useful in displaying user information.

=head1 CONSTRUCTOR

=over

=item new

C<new> creates an C<E2::User> object. 

=back

=head1 METHODS

=over

=item $user-E<gt>name

=item $user-E<gt>id

=item $user-E<gt>lasttime

These return, respectively, the username, user_id, the time of account creation, and the last time the specified user was seen on E2.

NOTE: L<E2::Node|E2::Node> provides $user-E<gt>createtime, as well as other methods that might be useful in displaying user information.

=item $user-E<gt>alias

=item $user-E<gt>alias_id

These return, respectively, the username and user_id of this user's alias (for message forwarding) if he indeed has one.

=item $user-E<gt>text

C<text> returns the text of the "User Bio" section of the user's homenode.

=item $user-E<gt>experience

=item $user-E<gt>level

=item $user-E<gt>level_string

These return, respectively, the XP number of the user in question, the level number, and the level including description text ("13 (Pseudo God)", etc.).

=item $user-E<gt>writeup_count

=item $user-E<gt>cool_count

These return, respectively, the number of writeups written by the user in question, and the number of C!s he has spent.

=item $user-E<gt>image_url

C<image> returns a relative URL to the homenode image of the user in question.

=item $user-E<gt>lastnode

=item $user-E<gt>lastnode_id

These return the name and id, respectively, of the most recent node written by this user.

=item $user-E<gt>mission

=item $user-E<gt>specialties

=item $user-E<gt>motto

=item $user-E<gt>employment

These return the strings that are displayed in the user's homenode regarding his mission drive, specialties, motto, and his employer or school.

=item $user-E<gt>groups

C<groups> returns a list of hashrefs corresponding to the groups which this user is a member. It only lists membership in 'gods', 'Content Editors', and 'edev'. Hash keys include 'title' and 'id'.

=item $user-E<gt>bookmarks

C<bookmarks> returns a list of hashrefs corresponding to the nodes that this user has bookmarked. Hash keys include 'title' and 'id'.

=back

=head1 SEE ALSO

L<E2::Interface>,
L<E2::Node>,
L<E2::UserSearch>,
L<http://everything2.com>,
L<http://everything2.com/?node=clientdev>

=head1 AUTHOR

Jose M. Weeks E<lt>I<jose@joseweeks.com>E<gt> (I<Simpleton> on E2)

=head1 COPYRIGHT

This software is public domain.

=cut
