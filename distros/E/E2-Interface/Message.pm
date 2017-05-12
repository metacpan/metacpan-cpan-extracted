# E2::Message
# Jose M. Weeks <jose@joseweeks.com>
# 18 June 2003
#
# See bottom for pod documentation.

package E2::Message;

use 5.006;
use strict;
use warnings;
use Carp;

use E2::Ticker;
use E2::Node;	# for set_room

our @ISA 	= "E2::Ticker";
our $VERSION	= "0.32";
our $DEBUG; *DEBUG = *E2::Interface::DEBUG;

our %room_name_to_id  = (
	"outside"		=> undef, # 1102338,
	"political asylum"	=> 553129,
	"noder's nursery"	=> 553146
);

# Methods

sub new;

sub list_public;
sub list_private;

sub reset_public;
sub reset_private;

sub room;
sub room_id;
sub topic;

sub set_room;
sub send;
sub blab;
sub delete;

# Private

sub list_messages;

# Methods

sub new { 
	my $arg   = shift;
	my $class = ref( $arg ) || $arg;
	my $self  = $class->SUPER::new();
	return bless ($self, $class);
}

sub topic {
	my $self = shift	or croak "Usage: topic E2MESSAGE";
	return $self->{topic};
}

sub room {
	my $self = shift 	or croak "Usage: room E2MESSAGE";
	return $self->{room};
}

sub room_id {
	my $self = shift	or croak "Usage: room_id E2MESSAGE";
	return $self->{room_id};
}

sub reset_public {
	my $self = shift	or croak "Usage: reset_public E2MESSAGE";
	$self->{msglimit} = undef;
}

sub reset_private {
	my $self = shift	or croak "Usage: reset_private E2MESSAGE";
	$self->{p_msglimit} = undef;
}

sub list_public {
	my $self = shift	or croak "Usage: list_public E2MESSAGE";
	
	my %opt;
	my @list;
	
	warn "E2::Message::list_public\n"	if $DEBUG > 1;

	# We need to lock list_public, because there is a re-entrance issue
	# with msglimit (if we call this method a second time before the
	# first has completed, we'll have two list_publics with the same
	# msglimit, which means any messages retrieved will be retrieved
	# twice).

	return () if $self->{__lock_list_public};
	$self->{__lock_list_public} = 1;
	
	$opt{nosort}	= 1;
	$opt{backtime}	= 10;
	$opt{msglimit}	= $self->{msglimit} if $self->{msglimit};
	$opt{for_node}	= $self->{room_id}  if $self->{room_id};
	
	# This code is repeated in list_private (to some extent).

	my $handlers = {
		'messages/topic' => sub {
			(my $a, my $b) = @_;
			$self->{topic} = $b->text;
		},
		'messages/room' => sub {
			(my $a, my $b) = @_;

			# If we're in the process of changing rooms, don't
			# store any room values.

			return	if $self->{room_lock};

			$self->{room} =  $b->text;
			$self->{room_id} = $b->{att}->{room_id}
		},
		'messages/msglist/msg' => sub {
			(my $a, my $b) = @_;
			my $m = {};

			$m->{id}     = $b->{att}->{msg_id};
			$m->{time}   = $b->{att}->{msg_time};

			# Set 'author' and 'author_id' if they exist

			if( my $f = $b->first_child('from') ) {
				$m->{author} = $f->first_child('e2link')->text;
				$m->{author_id} = $f->first_child('e2link')->
					{att}->{node_id};
			}

			$m->{archive} = $b->{att}->{archive};
			
			$m->{text} = $b->first_child('txt')->text;

			if( !$self->{msglimit} ||
			    $m->{id} > $self->{msglimit} ) {
				$self->{msglimit} = $m->{id};
			}

			push @list, $m;
		}
	};

	# We need to do some post-processing (sorting), so we'll have to use
	# thread_then
	
	return $self->thread_then(
		[
			\&E2::Ticker::parse,
			$self,
			'messages',
			$handlers,
			[],		# It'll be more efficient to not pass
			%opt		# @list back and forth, so just pass a
		],			# dummy value.
		sub { return sort { $a->{id} <=> $b->{id} } @list }, # POST
		sub { delete $self->{__lock_list_public}          }  # FINISH
	);	
}

sub list_private {
	my $self = shift	or croak "Usage: list_private E2MESSAGE [, DROP_ARCHIVED ]";
	my $drop_archived = shift;
	my @list;
	my %opt;
	
	warn "E2::Message::list_private\n"	if $DEBUG > 1;

	return () if $self->{__lock_list_private};
	$self->{__lock_list_private} = 1;

	$opt{msglimit}	= $self->{p_msglimit}	if $self->{p_msglimit};
	$opt{for_node}	= "me";

	my $handlers = {
		'messages/msglist/msg' => sub {
			(my $a, my $b) = @_;
			my $m = {};

			$m->{id}     = $b->{att}->{msg_id};
			$m->{time}   = $b->{att}->{msg_time};

			# Set 'author' and 'author_id' if they exist

			if( my $f = $b->first_child('from') ) {
				$m->{author} = $f->first_child('e2link')->text;
				$m->{author_id} = $f->first_child('e2link')->
					{att}->{node_id};
			}

			$m->{archive} = $b->{att}->{archive};
			
			$m->{text} = $b->first_child('txt')->text;

			# Do group stuff if this is a group message

			if( my $g = $b->first_child( 'grp' ) ) {
				$m->{group} = $g->first_child('e2link')->text;
				$m->{group_id} = $g->first_child('e2link')->
					{att}->{node_id};
				$m->{grouptype} = $g->{att}->{type};
			}

			if( !$self->{p_msglimit} ||
				$m->{id} > $self->{p_msglimit} ) {
				$self->{p_msglimit} = $m->{id};
			}

			# Don't store if we're dropping archived AND
			# this message is archived.

			if( $drop_archived && $m->{archive} ) {
				return;
			}

			push @list, $m;
		}
	};

	# We need to do some post-processing (sorting), so we'll have to use
	# thread_then
	
	return $self->thread_then(
		[
			\&E2::Ticker::parse,
			$self,
			'messages',
			$handlers,
			[],		# It'll be more efficient to not pass
			%opt		# @list back and forth, so just pass a
		],			# dummy value.
		sub { return sort { $a->{id} <=> $b->{id} } @list }, # POST
		sub { delete $self->{__lock_list_private}         }  # FINISH
	);	
}

sub send {
	my $self = shift		or croak "Usage: send E2MESSAGE, MESSAGE_TEXT";
	my $message = shift		or croak "Usage: send E2MESSAGE, MESSAGE_TEXT";
	
	warn "E2::Message::send\n"		if $DEBUG > 1;
	
	if( ! $self->logged_in ) {
		warn "Unable to send message: not logged in"	if $DEBUG;
		return undef;
	}
	
	return $self->thread_then(
		[
			\&E2::Interface::process_request,
			$self,
			op	=> "message",
			message	=> $message
		],
	sub {
		return 1;	# FIXME
	});
}
	
sub set_room {
	our $self = shift	or croak "Usage: set_room E2MESSAGE, ROOM_NAME";
	my $room = shift	or croak "Usage: set_room E2MESSAGE, ROOM_NAME";

	warn "E2::Message::set_room\n"	if $DEBUG > 1;

	return undef if $self->{__lock_set_room};
	$self->{__lock_set_room} = 1;

	if( ! $self->logged_in ) {
		warn "Unable to set room message: not logged in" if $DEBUG;
		return undef;
	}

	$room = lc( $room );
	
	# Return 0 if we're already in the specified room
	
	if( lc($self->{room}) eq $room ) {
		return 0;
	}

	# Change rooms

	our $n = new E2::Node;
	$n->clone( $self );
	
	return $self->thread_then( 
		[
			\&E2::Node::load,
			$n,
			$room,
			'room'
		],
	sub {
		if( (!$n->type) || $n->type ne 'room' ) {
			return undef;
		}
	
		$self->{room}		= $n->title;
		$self->{room_id}	= $n->node_id;
		$self->{topic}		= $n->description;
		$self->{msglimit}	= undef;

		delete $self->{__lock_set_room};
		
		return 1;
	});
}

sub blab {
	my $self    = shift	or croak "Usage: blab E2MESSAGE, USER_ID, TEXT [ , CC_BOOL ]";
	my $user_id = shift	or croak "Usage: blab E2MESSAGE, USER_ID, TEXT [ , CC_BOOL ]";
	my $text    = shift	or croak "Usage: blab E2MESSAGE, USER_ID, TEXT [ , CC_BOOL ]";
	my $cc	    = shift;

	my %request;

	warn "E2::Message::blab\n"	if $DEBUG > 1;

	if( ! $self->logged_in ) {
		warn "Unable to blab: not logged in"	if $DEBUG;
		return undef;
	}

	$request{node_id} = $user_id;
	$request{"msguser_$user_id"} = $text;

	if( $cc ) {
		if( !$self->this_user_id ) {

			return $self->thread_then(
				[
					\&E2::Interface::verify_login,
					$self
				],
			sub {
				return undef	if !$self->this_user_id;

				$request{"ccmsguser_$self->{user_id}"} = 1;

				return process_request( %request );
			});
			
		} else {
			$request{"ccmsguser_$self->{user_id}"} = 1
		}
	}

	return $self->process_request( %request );
}

sub archive {
	my $self = shift	or croak "Usage: archive E2MESSAGE, MSG_ID ...";
	my @msgs = @_		or croak "Usage: archive E2MESSAGE, MSG_ID ...";

	warn "E2::Message::archive\n"	if $DEBUG > 1;
	
	my %req = ( op => 'message' );
	
	foreach( @msgs ) { $req{"archive_$_"} = 'yup' }

	return $self->process_request( %req );
}

sub unarchive {
	my $self = shift  or croak "Usage: unarchive E2MESSAGE, MSG_ID ...";
	my @msgs = @_	  or croak "Usage: unarchive E2MESSAGE, MSG_ID ...";

	warn "E2::Message::unarchive\n"	if $DEBUG > 1;
	
	my %req = ( op => 'message' );
	
	foreach( @msgs ) { $req{"unarchive_$_"} = 'yup' }

	return $self->process_request( %req );
}

sub delete {
	my $self = shift	or croak "Usage: delete E2MESSAGE, MSG_ID ...";
	my @msgs = @_		or croak "Usage: delete E2MESSAGE, MSG_ID ...";

	warn "E2::Message::delete\n"	if $DEBUG > 1;
	
	my %req = ( op => 'message' );
	
	foreach( @msgs ) { $req{"deletemsg_$_"} = 'yup' }

	return $self->process_request( %req );
}

sub perform {
	my $self = shift or croak "Usage: perform E2MESSAGE, HASH";
	my %ops = @_     or croak "Usage: perform E2MESSAGE, HASH";

	my %req = ( op => 'message' );

	foreach( keys %ops ) {
		if( lc($ops{$_}) eq 'delete' ) {
			$req{"deletemsg_$_"} = 'yup';
		} elsif( lc($ops{$_}) eq 'archive' ) {
			$req{"archive_$_"}   = 'yup';
		} elsif( lc($ops{$_}) eq 'unarchive' ) {
			$req{"unarchive_$_"} = 'yup';
		} else {
			croak "Invalid operation: $_";
		}
	}

	return $self->process_request( %req );
}

1;
__END__

=head1 NAME

E2::Message - A module for accessing Everything2 messages

=head1 SYNOPSIS

	use E2::Message;

	my $catbox = new E2::Message;
	$catbox->login( "username", "password" ); # see E2::Interface
	$catbox->set_room( "Outside" );	

	# List public messages

	my @msg = $catbox->list_public;

	# Output the messages

	print "Public Messages:\n";
	print "(Topic: " . $catbox->topic . ")\n";
	foreach my $m (@msg) {
		print "$m->{author}: $m->{text}\n";
	}

	# List unarchived private messages

	@msg = $catbox->list_private( 1 );

	# Output the messages

	print "Private Messages:\n";
	foreach my $m (@msg) {
		print "($m->{group}) " if $m->{group};
		print "$m->{author}: $m->{text}\n";
	}

=head1 DESCRIPTION

This module provides an interface to L<http://everything2.com>'s messaging system (the chatterbox as well as private messages). It inherits L<E2::Ticker|E2::Ticker>.

C<E2::Message> fetches public and private messages from everything2.com. Subsequent calls to its C<list_public> and C<list_private> will return only new messages, unless the corresponding C<reset> method has been called.

=head1 CONSTRUCTOR

=over

=item new

C<new> creates an C<E2::Message> object that defaults to "Guest User" on E2 and, until C<login> is called, can retrieve only public messages and can send neither public nor private messages.

=back

=head1 METHODS

=over

=item $catbox-E<gt>topic

This method returns the current public room's topic. This topic is updated as a side-effect to both C<list_public> and C<set_room>, so if neither of these methods have been called, C<topic> will return C<undef>.

=item $catbox-E<gt>room

This method returns the current room name.

=item $catbox-E<gt>room_id

This method returns the current room's node_id.

=item $catbox-E<gt>list_public

C<list_public> fetches and returns any public messages in the current room that have been posted since the last call to C<list_public>, as well as updating the topic, room, and room_id. It returns a list of hashrefs representing the fetched messages, each with the following keys:

	author		# Username of message author
	author_id	# User_id of message author
	message_id	# Id of message
	time		# Timestamp of message
	text		# Text of the message

C<list_public> returns an empty list if no new messages exist.

Exceptions: 'Unable to process request', 'Parse error:'

=item $catbox-E<gt>list_private [ DROP_ARCHIVED ]

C<list_private> fetches and returns any private messages that have been posted sincethe last call to C<list_private>. If DROP_ARCHIVED is true, only messages that do not have the 'archive' flag will be returned. This method returns a list of hashrefs representing the fetched messages, each with the following keys:

	author		# Username of message author
	author_id	# User_id of message author
	id		# Id of message
	time		# Timestamp of message
	text		# Text of the message
	archive		# Boolean: Is this message archived?

	# The following only exist for
	# group messages

	group		# Name of usergroup 
	group_id	# Id of usergourp
	grouptype	# Type of usergroup

C<list_private> returns an empty list if no new messages exist.

Exceptions: 'Unable to process request', 'Parse error:'

=item $catbox-E<gt>reset_public

This method resets the public message ticker, so the next call to C<list_public> will retrieve all available public messages (they will all be considered "unfetched").

=item $catbox-E<gt>reset_private

This method resets the private message ticker, so that in the next call to C<list_private>, all private messages will be considered "unfetched."

=item $catbox-E<gt>send MESSAGE_TEXT

C<send> sends "TEXT" as if it were entered into E2's chatterbox. This message need not be escaped in any way. It returns true on success and C<undef> on failure.

Exceptions: 'Unable to process request'

=item $catbox-E<gt>blab RECIPIANT_ID, MESSAGE_TEXT [, CC ]

C<blab> sends the private "blab" message MESSAGE_TEXT to user_id RECIPIANT_ID. If CC is true, sends a copy of the message to the sender as well. Returns true on success and C<undef> on failure.

Exceptions: 'Unable to process request'

=item $catbox-E<gt>archive MSG_ID_LIST

=item $catbox-E<gt>unarchive MSG_ID_LIST

=item $catbox-E<gt>delete MSG_ID_LIST

These methods archive, unarchive, or permanently delete the messages in MSG_ID_LIST (this is a list of message ids).

Exceptions: 'Unable to process request'

=item $catbox-E<gt>perform HASH

This method performs multiple archive, unarchive, and delete operations on a list of messages.

HASH is organized as a hash of msg_id => operation pairs. Example:

	$catbox->perform( 
		100 => 'archive',
		101 => 'unarchive',
		102 => 'delete'
	);

If any operations besides "archive", "unarchive", and "delete" are specified, this method throws an "Invalid operation:" exception.

Exceptions: 'Unable to process request', 'Invalid operation:'

=item $catbox-E<gt>set_room ROOM_NAME

C<set_room> changes the current public room to ROOM_NAME. It returns true on success, 0 if ROOM_NAME is already the current room, and undef on failure.

Exceptions: 'Unable to process request'

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
