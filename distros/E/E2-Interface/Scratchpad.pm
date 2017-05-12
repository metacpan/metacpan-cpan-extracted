# E2::Scratchpad
# Jose M. Weeks <jose@joseweeks.com>
# 17 June 2003
#
# See bottom for pod documentation.

package E2::Scratchpad;

use 5.006;
use strict;
use warnings;
use Carp;
use E2::Ticker;

our @ISA = ("E2::Ticker");
our $VERSION = "0.32";
our $DEBUG; *DEBUG = *E2::Interface::DEBUG;

sub new {
	my $arg = shift;
	my $class = ref($arg) || $arg;

	my $self = $class->SUPER::new( @_ );

	$self->{text} = undef;
	$self->{user} = undef;
	$self->{shared} = undef;

	return $self;
}

sub text   { return $_[0]->{text}   }
sub user   { return $_[0]->{user}   }
sub shared { return $_[0]->{shared} }

sub load {
	my $self = shift or croak "Usage: scratch_pad E2SCRATCHPAD [, USER ]";
	my $user_id = shift;
	my %opt;

	warn "E2::Scratchpad::load"	if $DEBUG > 1;

	$opt{scratch} = $user_id	if $user_id;

	my $handlers = {
		'scratchtxt' => sub {
			(my $a, my $b) = @_;
			$self->{text} = $b->text;
			$self->{user} = $b->{att}->{user};
			$self->{shared} = $b->{att}->{user};
		}
	};

	$self->{text} = undef;
	$self->{user} = undef;
	$self->{shared} = undef;

	return $self->thread_then( 
		[
			\&E2::Ticker::parse,
			$self,
			'scratch',
			$handlers,
			[],	# dummy value for array
			%opt
		],
		sub { return $self->user ? 1 : 0 }
	);
}

sub update {
	my $self = shift or croak "Usage: update E2SCRATCHPAD [ TEXT ] [, SHARE ]";
	my $text = shift;
	my $share = shift;

	warn "E2::Scratchpad::update"		if $DEBUG > 1;
	
	# Must be logged in AND either updating the text or the share
	# (or both)

	if( ! $self->logged_in ) {
		warn "Unable to update scratchpad: not logged in" if $DEBUG;
		return undef;
	}
	if( ! defined $text && ! defined $share ) {
		warn "Nothing to update" if $DEBUG;
		return undef;
	}

	my %req = (
		node => 'E2 Scratch Pad',
		skratchsubmit => 1,
		sexisgood => 1,
		submit => 'Update!'
	);

	if( defined $text ) {
		$req{skratch} = $text;
	}

	if( defined $share ) {
		# ...
	}

	$self->thread_then(
		[ \&E2::Interface::process_request, $self, %req ],
		sub {
			# FIXME: test for success
			return 1;
		}
	);
}

1;
__END__

=head1 NAME

E2::Scratchpad - A module for loading and setting a user's E2 Scratch Pad.

=head1 SYNOPSIS

	use E2::Scratchpad;
	use E2::User; # We need to get a user's user_id

	my $scratch = new E2::Scratchpad;

	# Load nate's scratchpad

	my $user = new E2::User;
	$user->load( 'nate' )
		or die "Can't load nate's homenode";

	$scratch->load( $user->id )
		or die "Can't load nate's scratchpad";

	.......

	# Login and load your own scratchpad

	$scratch->login( "username", "password" )
		or die "Unable to login";
	$scratch->load
		or die "Can't load your scratchpad";

	# Display your scratchpad

	print $scratch->user . "'s scratchpad:\n";
	print "(Other users can " . 
	      ($scratch->shared ? '' : 'NOT ') .
	      "view your scratchpad.)\n";
	print "-------------------------------\n";
	print $scratch->text;
	
	# Update your scratchpad

	$scratch->update( "Scratchpad text goes here\n" );

=head1 DESCRIPTION

This module allows access to user's scratchpads (with read and write access to a user's own scratchpad and read access to the scratchpad of any user who chooses to share his publicly.

=head1 CONSTRUCTOR

=over

=item new

C<new> creates a new C<E2::Scratchpad> object.

=back

=head1 METHODS

=over

=item $scratch-E<gt>load [ USER_ID ]

This method fetches a user's scratchpad.

If USER_ID is specified, it attempts to fetch the scratchpad of that user (who may or may not have chosen to share it publicly). If USER_ID is not specified, it fetches the scratchpad of the currently-logged-in user.

This method returns true on success and C<undef> on failure.

Exceptions: 'Unable to process request', 'Parse error:'

=item $scratch-E<gt>update [ TEXT ] [, SHARE ]

If TEXT is specified, this method updates the text of the currently-logged-in user's scratchpad. If SHARE is specified, it tells the server whether this scratchpad is to be publicly shared or not.

If either parameter is undefined, it is ignored. Pass an empty string as TEXT to clear the scratchpad, and 0 as SHARE to set the scratchpad as not shared.

Exceptions: 'Unable to process request'

=item $scratch-E<gt>shared

=item $scratch-E<gt>user

=item $scratch-E<gt>text

These methods return, respectively, the boolean: "Is this scratchpad publicly shared?"; the username of the user to whom this scratchpad belongs, and the text of this scratchpad.

C<load> must be called before any of these values will be defined.

=back

=head1 SEE ALSO

L<E2::Interface>,
L<E2::Ticker>,
L<http://everything2.com>,
L<http://everything2.com/?node=clientdev>

=head1 AUTHOR

Jose M. Weeks E<lt>I<jose@joseweeks.com>E<gt> (I<Simpleton> on E2)

=head1 COPYRIGHT

This software is public domain.

=cut
