# E2::Session
# Jose M. Weeks <jose@joseweeks.com>
# 29 June 2003
#
# See bottom for pod documentation.

package E2::Session;

use 5.006;
use strict;
use warnings;
use Carp;

use E2::Ticker;

our $VERSION = "0.33";
our @ISA = qw(E2::Ticker);
our $DEBUG; *DEBUG = *E2::Interface::DEBUG;

sub new;
sub clear;

sub update;

sub time;

sub votes;
sub cools;
sub karma;
sub experience;
sub writeups;
sub borged;
sub forbidden;

sub xpchange;
sub nextlevel;

sub new { 
	my $arg   = shift;
	my $class = ref( $arg ) || $arg;
	my $self  = $class->SUPER::new();

	return bless ($self, $class);
}

sub clear {
	my $self = shift	or croak "Usage: clear E2SESSION";

	warn "E2::Session::clear\n"	if $DEBUG > 1;

	$self->{votes} = undef;
	$self->{cools} = undef;
	$self->{karma} = undef;
	$self->{experience} = undef;
	$self->{writeups} = undef;
	$self->{borged} = undef;
	$self->{forbidden} = undef;

	$self->{time} = undef;

	$self->{xpchange} = undef;
	$self->{nextlevel} = {};

	@{ $self->{personal} } = ();

	return 1;
}

sub votes {
	my $self = shift	or croak "Usage: votes E2SESSION";
	return $self->{votes};
}

sub cools {
	my $self = shift	or croak "Usage: cools E2SESSION";
	return $self->{cools};
}

sub karma {
	my $self = shift	or croak "Usage: karma E2SESSION";
	return $self->{karma};
}

sub experience {
	my $self = shift	or croak "Usage: experience E2SESSION";
	return $self->{experience};
}

sub writeups {
	my $self = shift	or croak "Usage: writeups E2SESSION";
	return $self->{writeups};
}

sub borged {
	my $self = shift	or croak "Usage: borged E2SESSION";
	return $self->{borged};
}

sub forbidden {
	my $self = shift	or croak "Usage: forbidden E2SESSION";
	return $self->{forbidden};
}

sub time {
	my $self = shift	or croak "Usage: time E2SESSION";
	return $self->{time};
}

sub xpchange {
	my $self = shift	or croak "Usage: xpchange E2SESSION";
	return $self->{xpchange};
}

sub nextlevel {
	my $self = shift	or croak "Usage: nextlevel E2SESSION";
	return $self->{nextlevel};
}

sub list_personal_nodes {
	my $self = shift	or croak "Usage: list_personal_nodes  E2SESSION";
	return @{ $self->{personal} };
}

sub update {
	my $self = shift or croak "Usage: update E2SESSION";

	warn "E2::Session::update\n"	if $DEBUG > 1;

	my $handlers = {
		'currentuser' => sub {
			(my $a, my $b) = @_;
			${$self->{this_username}} = $b->text;
			${$self->{this_user_id}}  = $b->{att}->{user_id};
		},
		'servertime' => sub {
			(my $a, my $b) = @_;
			$self->{time} = $b->text;
		},
		'borgstatus' => sub {
			(my $a, my $b) = @_;
			$self->{borged} = $b->{att}->{value};
		},
		'cools' => sub {
			(my $a, my $b) = @_;
			$self->{cools} = $b->text;
		},
		'votesleft' => sub {
			(my $a, my $b) = @_;
			$self->{votes} = $b->text;
		},
		'karma' => sub {
			(my $a, my $b) = @_;
			$self->{karma} = $b->text;
		},
		'experience' => sub {
			(my $a, my $b) = @_;
			$self->{experience} = $b->text;
		},
		'numwriteups' => sub {
			(my $a, my $b) = @_;
			$self->{writeups} = $b->text;
		},
		'forbiddance' => sub {
			(my $a, my $b) = @_;
			$self->{forbidden} = $b->text;
		},
		'xpinfo' => sub {
			(my $a, my $b) = @_;
			if( my $c = $b->first_child('xpchange') ) {
				$self->{xpchange} = $c->text;
			}
			if( my $c = $b->first_child('nextlevel') ) {
				$self->{nextlevel} = {
					experience => $c->{att}->
						{experience},
					writeups => $c->{att}->
						{writeups},
					level => $c->text
				};
			}
		},
		'personalnodes/e2node' => sub {
			(my $a, my $b) = @_;
			push @{ $self->{personal} }, {
				title => $b->text,
				id    => $b->{att}->{node_id}
			};
		}
	};

	$self->clear;

	$self->parse( 'session', $handlers, [ 1 ] );
}

1;
__END__

=head1 NAME

E2::Session - Load session information about the current E2 user

=head1 SYNOPSIS

	use E2::Session;

	my $session = new E2::Session;

	$session->login( "username", "password" );    # See E2::Interface

	$session->update;

	print "Username: " . $session->this_username; # See E2::Interface
	print "\nuser_id: " . $session->this_user_id; # See E2::Interface

	print "\nVotes left today: " . $session->votes;
	print "\nCools left today: " . $session->cools;
	print "\nExperience: " . $session->experience;
	print "\nWriteups: " . $session->writeups;
	print "\nBorged: " . ($session->borged ? "Yes" : "No");
	print "\nForbidden to post: " . ($session->forbidden ? "Yes" : "No");
	print "\nServer time: " . $session->time;

	if( $session->xpchange ) {
		print "\nChange in XP: " . $session->xpchange;
		print "\nTo reach level " . $session->nextlevel->{level};
		print "\n     XP:" . $session->nextlevel->{experience};
		print "\n     Writeups:" . $session->nextlevel->{writeups};
	}

	foreach( $session->list_personal_nodes ) {
		print "\nPersonal node: $_->{title}";
	}

=head1 DESCRIPTION

This module allows a user to load his session information
This module provides an interface to everything2.com's search interface. It inherits L<E2::Ticker|E2::Ticker>.

=head1 CONSTRUCTOR

=over

=item new

C<new> creates an C<E2::Session> object.

=back

=head1 METHODS

=over

=item $session-E<gt>clear

This method clears all stored session values.

=item $session-E<gt>update

This method fetches the personal session from e2 and makes available all of the access methods below. If a user is not logged in, the only session information fetched will be the servertime (retrievable via C<time>) and this user's username and user_id (retrievable via C<this_username> and C<this_user_id>, which are inherited from E2::Interface).

C<xpchange> and C<nextlevel> are only available if the user's writeup count or experience number has changed since the user's session was last loaded. C<update> works very much like the epicenter nodelet on E2, and "last loaded" refers to either updating the session or loading a web page that contains the epicenter.

One other side-effect of calling update (or loading the epicenter) is that a user who's been borged must do so at least once, after the length of his borging has expired, before he will be able to speak again.

=item $session-E<gt>votes

=item $session-E<gt>cools

=item $session-E<gt>experience

=item $session-E<gt>writeups

=item $session-E<gt>time

These methods return the user's number of votes left today, number of cools left today, their current experience number, their current number of writeups, and the current server time. Example server time: 
"Sun Mar 16 15:58:20 2003".

=item $session-E<gt>borged

=item $session-E<gt>forbidden

These methods return values corresponding, respectively, to whether the current user has been borged and whether the current user has been forbidden to post writeups. Both return boolean values, but C<forbidden>, if true, is a text string describing the lock.

=item $session-E<gt>xpchange

This method returns the user's change in experience since that previous time he updated his user session (or loaded an epicenter nodelet). It is only defined if either the user's experience number or writeup count has changed since the previous update.

=item $session-E<gt>nextlevel

This method returns information about requirements the user must meet to reach the next level. It is only defined if either the user's experience number or writeup count has changed since the previous update (either by a call to C<update> or by loading the epicenter nodelet).

This method returns a hashref with the following keys:

	experience	# Extra experience required to level up
	writeups	# Extra writeups required to level up
	level		# The next level as an integer

=back

=head1 SEE ALSO

L<E2::Interface>,
L<E2::Ticker>,
L<http://everything2.com/?node=clientdev>
L<http://everything2.com/?node=e2interface>

=head1 AUTHOR

Jose M. Weeks E<lt>I<jose@joseweeks.com>E<gt> (I<Simpleton> on E2)

=head1 COPYRIGHT

This software is public domain.

=cut
