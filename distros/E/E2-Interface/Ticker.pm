# E2::Ticker
# Jose M. Weeks <jose@joseweeks.com>
# 17 June 2003
#
# See bottom for pod documentation.

package E2::Ticker;

use 5.006;
use strict;
use warnings;
use Carp;
use E2::Interface;

our @ISA = ("E2::Interface");
our $VERSION = "0.32";
our $DEBUG; *DEBUG = *E2::Interface::DEBUG;

our %xml_title = (
	interfaces	=> "XML Interfaces Ticker",
	clientversions	=> "Client Version XML Ticker",
	messages	=> "Universal Message XML Ticker",
	session		=> "Personal Session XML Ticker",
	search		=> "E2 XML Search Interface",
	scratch		=> "Scratch Pad XML Ticker",
	vars		=> "Raw VARS XML Ticker",
	timesince	=> "Time Since XML Ticker",
	usersearch	=> "User Search XML Ticker II",
	heaven		=> "Node Heaven XML Ticker",
	bestusers	=> "Everything's Best Users XML Ticker",
	coolnodes	=> "Cool Nodes XML Ticker II",
	edcools		=> "Editor Cools XML Ticker",
	random		=> "Random Nodes XML Ticker",
	rooms		=> "Available Rooms XML Ticker",
	otherusers	=> "Other Users XML Ticker II",
	newwriteups	=> "New Writeups XML Ticker"
);

# Prototypes

sub new;

sub new_writeups;
sub other_users;
sub random_nodes;
sub cool_nodes;
sub editor_cools;
sub time_since;

sub random_nodes_wit;
sub time_since_now;

# Private

sub parse;

# Methods

sub new {
	my $arg   = shift;
	my $class = ref( $arg ) || $arg;
	my $self  = $class->SUPER::new();

	$self->{xml_interfaces} = \%xml_title;

	$self->{ticker_string} = undef;
	
	bless( $self, $class );
	return $self;
}

sub use_string {
	my $self = shift or croak "Usage: use_string E2TICKER, STRING";
	my $string = shift;

	$self->{ticker_string} = $string;
}

# This method is private (undocumented). It should not be called from
# anywhere except internally or in derived classes.
# 
# It takes the following parameters:
# 	E2TICKER	- $self
# 	TYPE		- Type of ticker to load
# 	HANDLERS	- a reference to a hash of twig parsers
# 	LISTREF		- a reference to the list we want to return
#	OPTIONS		- set of attr, val pairs used in the POST request

sub parse {
	croak "Usage: parse E2TICKER, TYPE, HANDLERS, LISTREF, [ OPTIONS ]"
		if @_ < 4;
		
	my $self = shift;
	my $type = shift;
	my $handlers = shift;
	my $listref = shift;

	warn "E2::Ticker::parse\n"	if $DEBUG > 1;
	warn "Parsing $type ticker:\n" . Dumper( $handlers )
		if $DEBUG > 2;

	# Sanity check

	if( ref $handlers ne 'HASH' || ref $listref ne 'ARRAY' ) {
		croak "Usage: parse E2TICKER, TYPE, HANDLERS, LISTREF, " .
			"[ OPTIONS ]";
	}

	# Note: The exception below will only be raised if there are
	# bugs in e2interface, unless applications are calling
	# E2::Ticker::parse on their own, which they shouldn't be
	# doing. This exception is undocumented (it is not
	# thrown by any documented methods).

	my $title = $self->{xml_interfaces}->{$type};
	if( !$title ) {
		croak "Invalid ticker type: $type";
	}

	# This is here in case (for some oddball reason) someone wants
	# to load a ticker from a text string. This is used for the test
	# cases, and probably for cacheing and so on...

	if( my $s = $self->{ticker_string} ) {
		$self->{ticker_string} = undef;
		$self->parse_twig( $s, $handlers );
		return @$listref;
	}
	
	# Otherwise, do the normal thing, which is to load the
	# node from e2.

	return $self->thread_then(
		[
			\&E2::Interface::process_request,
			$self,
			node => $title,
			@_
		],
		sub {
			$self->parse_twig(shift, $handlers);
			return @$listref;
		}
	);
}

sub load_interfaces {
	my $self = shift or croak "Usage: interfaces E2TICKER";

	warn "E2::Ticker::load_interfaces\n"	if $DEBUG > 1;
	
	my $handlers = {
		'this' => sub {
			(my $a, my $b) = @_;
			$self->{xml_interfaces}->{interfaces} =
				$b->text;
		},
		'xmlexport' => sub {
			(my $a, my $b) = @_;
			my $c = $b->{att}->{iface};
			$self->{xml_interfaces}->{$c} = $b->text;
		}
	};

	# Since we're loading a URL instead of a node or node_id,
	# we're going to have to do this one without the help
	# of E2::Interface::process_request, and therefore without
	# E2::Ticker::parse.

	# If we're working threaded, we have to do it the hard way

	if( $self->{threads} ) {
		return thread_then(
			[
				\&E2::Interface::start_job,
				$self,
				'POST',
				"http://$self->{domain}/interfaces.xml",
				$self->{cookie},
				$self->{agentstring},
				links_noparse => $self->{links_noparse},
			],
		sub {
			my $response = shift;

			$self->{xml_interfaces} = {};
	
			$self->parse_twig( $response, $handlers );
			
			return 1;

		});
	}

	# Otherwise, do the same as above, but without passing the work off
	# to another thread.

	my $response = process_request_raw(
				'POST',
				"http://$self->{domain}/interfaces.xml", 
				$self->{cookie},
				$self->{agentstring},
				links_noparse => $self->{links_noparse},
		       );

	$self->cookie( extract_cookie( $response ) );

	my $xml = post_process( $response );
	
	$self->{xml_interfaces} = {};

	$self->parse_twig( $xml, $handlers );

	return 1;
}

sub new_writeups {
	my $self = shift or croak "Usage: new_writeups E2TICKER [, COUNT ]";
	my $count = shift;

	my %opt;

	my @writeups;

	warn "E2::Ticker::new_writeups"		if $DEBUG > 1;

	$opt{count} = $count	if $count;

	my $handlers = 	{
		'wu' => sub {
			(my $a, my $b) = @_;
			my $wu = {};
	
			$wu->{type} = $b->{att}->{wrtype};

			my $c = $b->first_child('e2link');
			
			$wu->{title} = $c->text;
			$wu->{id} = $c->{att}->{node_id};

			$c = $b->first_child('author')->first_child('e2link');
			$wu->{author} = $c->text;
			$wu->{author_id} = $c->{att}->{node_id};
			
			$c = $b->first_child('parent')->first_child('e2link');
			$wu->{parent} = $c->text;
			$wu->{parent_id} = $c->{att}->{node_id};
			
			push @writeups, $wu;
		}
	};

	return $self->parse( 'newwriteups', $handlers, \@writeups, %opt );
}

sub other_users {
	my $self = shift or croak "Usage: other_users E2TICKER [, ROOM_ID ]";
	my $room = shift;

	my @users;
	
	warn "E2::Ticker::other_users"		if $DEBUG > 1;

	my %opt = ( nosort => 1 );
	$opt{in_room} = $room	if $room;
	
	my $handlers = {
		'user' => sub {
			(my $a, my $b) = @_;
			my $user = {};
		
			$user->{god}	= $b->{att}->{e2god};
			$user->{editor}	= $b->{att}->{ce};
			$user->{edev}	= $b->{att}->{edev};
			$user->{xp}	= $b->{att}->{xp};
			$user->{borged}	= $b->{att}->{borged};

			my $c = $b->first_child('e2link');
			$user->{name}	= $c->text;
			$user->{id}	= $c->{att}->{node_id};

			if( $c = $b->first_child('room' ) ) {
				$user->{room} = $c->text;
				$user->{room_id} = $c->{att}->{node_id};
			}

			push @users, $user;
		}
	};

	return $self->parse( 'otherusers', $handlers, \@users, %opt );
}

sub random_nodes {
	my $self = shift or croak "Usage: random_nodes E2TICKER";

	my @random;

	warn "E2::Ticker::random_nodes"		if $DEBUG > 1;

	my $handlers = {
		'e2link' => sub {
			(my $a, my $b) = @_;
			push @random, {
				title => $b->text,
				id =>    $b->{att}->{node_id}
			};
		},
		'wit' => sub {
			(my $a, my $b) = @_;
			$self->{wit} = $b->text;
		}
	};

	return $self->parse( 'random', $handlers, \@random );
}

sub cool_nodes {
	my $self = shift or croak "Usage: cool_nodes E2TICKER [, WRITTEN_BY ] [, COOLED_BY ] [, COUNT ] [, OFFSET ]";
	my $written_by = shift;
	my $cooled_by = shift;
	my $count = shift;
	my $offset = shift;

	my @cools;

	warn "E2::Ticker::cool_nodes"		if $DEBUG > 1;

	my %opt;

	$opt{writtenby}		= $written_by	if $written_by;
	$opt{cooledby}		= $cooled_by	if $cooled_by;
	$opt{limit}		= $count	if $count;
	$opt{startat}		= $offset	if $offset;

	my $handlers = {
		'cool' => sub {
			(my $a, my $b) = @_;
			my $cool = {};
			my $c = $b->first_child('writeup')->first_child('e2link');

			$cool->{title}	= $c->text;
			$cool->{id}	= $c->{att}->{node_id};

			$c = $b->first_child('author')->first_child('e2link');

			$cool->{author}		= $c->text;
			$cool->{author_id}	= $c->{att}->{node_id};

			$c = $b->first_child('cooledby')->first_child('e2link');

			$cool->{cooledby}	= $c->text;
			$cool->{cooledby_id}	= $c->{att}->{node_id};

			push @cools, $cool;
		}
	};

	return $self->parse( 'coolnodes', $handlers, \@cools, %opt );
}

sub editor_cools {
	my $self = shift or croak "Usage: editor_cools E2TICKER [, COUNT ]";
	my $count = shift;

	my @edcools;
	
	warn "E2::Ticker::editor_cools"		if $DEBUG > 1;

	my %opt;

	$opt{count} = $count		if $count;

	my $handlers = {
		'edselection' => sub {
			(my $a, my $b) = @_;
			my $cool = {};
			my $c = $b->first_child('endorsed');

			$cool->{editor} = $c->text;
			$cool->{editor_id} = $c->{att}->{node_id};

			$c = $b->first_child('e2link');

			$cool->{title}	= $c->text;
			$cool->{id}	= $c->{att}->{node_id};

			push @edcools, $cool;
		}
	};

	return $self->parse( 'edcools', $handlers, \@edcools, %opt );
}

sub time_since {
	my $self = shift or croak "Usage: time_since E2TICKER [, USER1 [, USER2 [, ... ] ] ]";
	my @users = @_;
	my $string = undef;

	my @timesince;
	
	my %opt;

	warn "E2::Ticker::time_since"		if $DEBUG > 1;

	my $handlers = {
		'now' => sub {
			(my $a, my $b) = @_;
			$self->{now} = $b->text;
		},
		'user' => sub {
			(my $a, my $b) = @_;
			my $user = {};

			my $c = $b->first_child( 'e2link' );

			$user->{time} = $b->{att}->{lasttime};
			$user->{name} = $c->text;
			$user->{id} = $c->{att}->{node_id};

			push @timesince, $user;
		}
	};

	# If they've passed a list of users, determine
	# whether the list is of usernames or user_ids
	# and set %opt accordingly.

	if( @users ) {
		foreach my $u (@users) {
			if( ! int $u ) {
				$string = 1;
			}
		}

		my $key = $string ? 'node' : 'node_id';
		%opt = ( $key => join ',', @users );
	}

	return $self->parse( 'timesince', $handlers, \@timesince, %opt );
}

sub available_rooms {
	my $self = shift or croak "Usage: available_rooms E2TICKER";

	my @rooms = ( { title => 'outside', id => undef } );
	
	warn "E2::Ticker::available_rooms"		if $DEBUG > 1;

	my $handlers = {
		'outside/e2link' => sub {
			(my $a, my $b) = @_;
			$rooms[0] = {
				title	=> $b->text,
				id	=> $b->{att}->{node_id}
			};
		},
		'roomlist/e2link' => sub {
			(my $a, my $b) = @_;
			push @rooms, {
				title	=> $b->text,
				id	=> $b->{att}->{node_id}
			};
		}
	};

	return $self->parse( 'rooms', $handlers, \@rooms );
}

sub best_users {
	my $self = shift or croak "Usage: best_users E2TICKER [, NOGODS ]";
	my $nogods = shift;

	my @bestusers;
	
	warn "E2::Ticker::best_users"		if $DEBUG > 1;

	my %opt;
	$opt{ebu_noadmins} = 1	if $nogods;

	my $handlers = {
		'bestuser' => sub {
			(my $a, my $b) = @_;
			my $exp = $b->first_child( 'experience' );
			my $wri = $b->first_child( 'writeups' );
			my $usr = $b->first_child( 'e2link' );
			my $lvl = $b->first_child( 'level' );
				
			push @bestusers, {
				experience   => $exp->text,
				writeups     => $wri->text,
				id           => $usr->{att}->{node_id},
				user         => $usr->text,
				level        => $lvl->{att}->{value},
				level_string => $lvl->text
			};
		}
	};

	return $self->parse( 'bestusers', $handlers, \@bestusers, %opt );
}

sub node_heaven {
	my $self = shift or croak "Usage: node_heaven E2TICKER [, NODE_ID ]";
	my $node_id = shift;

	my @heaven;

	warn "E2::Ticker::node_heaven"		if $DEBUG > 1;

	if( !$self->logged_in ) { return undef; }

	my %opt;

	$opt{visitnode_id} = $node_id	if $node_id;

	my $handlers = {
		'nodeangel' => sub {
			(my $a, my $b) = @_;
			push @heaven, {
				title => $b->{att}->{title},
				id    => $b->{att}->{node_id},
				reputation => $b->{att}->{reputation},
				createtime => $b->{att}->{createtime},
				text  => $b->text
			};
		}
	};

	return $self->parse( 'heaven', $handlers, \@heaven, %opt );
}

sub maintenance_nodes {
	my $self = shift	or croak "Usage: maintenance_nodes E2TICKER";

	my @maintenance;
	
	warn "E2::Ticker::maintenance_nodes"		if $DEBUG > 1;

	my $handlers = {
		'e2link' => sub {
			(my $a, my $b) = @_;
			push @maintenance, {
				title	=> $b->text,
				id	=> $b->{att}->{node_id}
			};
		}
	};

	return $self->parse( 'maintenance', $handlers, \@maintenance );
}

sub raw_vars {
	my $self = shift	or croak "Usage: raw_vars E2TICKER";

	my $vars = {};
	
	warn "E2::Ticker::raw_vars"		if $DEBUG > 1;

	# Another method that doesn't return a list. Again, we'll have
	# to thread_then

	my $handlers = {
		'key' => sub {
			(my $a, my $b) = @_;
			$vars->{$b->{att}->{name}} = $b->text;
		}
	};

	return $self->thread_then( 
		[
			\&parse,
			$self,
			'vars',
			$handlers,
			[]		# dummy value for array
		],
		sub { return $vars }
	);
}

sub interfaces {
	my $self = shift	or croak "Usage: interfaces E2TICKER";

	return $self->{xml_interfaces};
}
	
sub random_nodes_wit {
	my $self = shift 	or croak "Usage: random_wit_now E2TICKER";
	return $self->{wit};
}

sub time_since_now {
	my $self = shift	or croak "Usage: time_since_now E2TICKER";
	return $self->{now};
}

1;
__END__

=head1 NAME

E2::Ticker - A module for fetching L<http://everything2.com>'s tickers.

=head1 SYNOPSIS

	use E2::Ticker;

	my $ticker = new E2::Ticker;

	# List New Writeups

	print "New Writeups:\n-------------\n";

	foreach my $n ($ticker->new_writeups) {
		print $n->{title} . "\n";
	}

	# List Other Users

	print "\nOther Users:\n------------\n";

	foreach my $u ($ticker->other_users) {
		print $u->{name};
		print '[$]' if $u->{editor};
		print '[@]' if $u->{god};
		print "\n";
	}

	# (and so on...)

=head1 DESCRIPTION

This module provides an interface for fetching L<http://everything2.com>'s New Writeups, Cool Nodes, Editor Cools, Random Nodes, Other Users, Time Since, Available Rooms, Best Users, Node Heaven, Maintenance Nodes, Scratch Pad, and Raw Vars, and Interfaces tickers. It also serves as a base class for other modules that load ticker pages.

=head1 CONSTRUCTOR

=over

=item new

C<new> creates a new C<E2::Ticker> object.

=back

=head1 METHODS

=over

=item $ticker-E<gt>new_writeups [ COUNT ]

This method fetches the New Writeups ticker from everything2 and returns a list of hashrefs (sorted reverse-chronologically). If COUNT is specified, it returns "COUNT" values, otherwise it returns the server's default count.

The returned hashrefs have the following keys:

	title		# Writeup title
	id		# node_id
	type		# type (person, place, thing, or idea)
	author		# Author's username
	author_id	# Author's user_id
	parent		# Parent node
	parent_id	# Parent's node_id

Exceptions: 'Unable to process request', 'Parse error:'

=item $ticker-E<gt>other_users [ ROOM_ID ]

This method fetches the Other Users ticker from everything2 and returns a list of hashrefs (sorted by descending XP). If ROOM_ID is specified, only users in the specified room are listed.

The returned hashrefs have the following keys:

	name	# Username
	id	# user_id
	god	# Boolean: Member of gods group?
	editor	# Boolean: Member of Content Editors group? 
	edev	# Boolean: Member of edev group?
	xp	# User's experience number
	borged	# Is this user borged?

	# The following are only defined if user is not "outside"

	room	# Name of the room user is in
	room_id	# node_id of room user is in
	
NOTE: only users who are members of edev are able to determine whether another user is an edev member.

Exceptions: 'Unable to process request', 'Parse error:'

=item $ticker-E<gt>random_nodes

This method fetches the Random Nodes ticker from everything2 and returns a list of hashrefs.

The returned hashrefs have the following keys:

	title
	id

This method also retrieves the "random wit" from everything2, which is then retrievable by calling C<random_wit>.

Exceptions: 'Unable to process request', 'Parse error:'

=item $ticker-E<gt>cool_nodes [ WRITTEN_BY ] [, COOLED_BY ] [, COUNT ] [, OFFSET ]

This method fetches the Cool Nodes ticker from everything2 and returns a list of hashrefs (sorted reverse-chronologically). Results can be filtered by "WRITTEN_BY" and "COOLED_BY", which should be usernames. If COUNT is specified, this method returns "COUNT" values. COUNT has a server default of 50, and a max of 50 as well. OFFSET specifies how many values back to start in the list, and is used for paging through Cool Nodes.

The returned hashrefs have the following keys:

	title		# Title of the writeup
	id		# node_id
	author		# Author's username
	author_id	# Author's user_id
	cooledby	# Username of user who C!d the writeup
	cooledby_id	# user_id of user who C!d the writeup

Exceptions: 'Unable to process request', 'Parse error:'

=item $ticker-E<gt>editor_cools

This method fetches the Editor Cools (or "Endorsements") ticker from everything2 and returns a list of hashrefs (sorted reverse-chronologically). If COUNT is specified, it returns "COUNT" values, otherwise it returns the server's default count.

The returned hashrefs have the following keys:

	title		# Title of the node (not writeup) edcooled
	id		# node_id
	editor		# Username of the editor who cooled the node
	editor_id	# user_id of the editor who cooled the node

Exceptions: 'Unable to process request', 'Parse error:'

=item $ticker-E<gt>time_since [ USER_LIST ]

This method fetches the Time Since ticker and returns a list of values. If USER_LIST is not specified, it returns a list with one value, that corresponding to the currently-logged-in user.

Otherwise, USER_LIST should be a list of either usernames or user_ids. 

It returns a list of hashrefs with the following keys:

	name	# Username
	id	# user_id
	time	# The last time this user was seen

C<time_since> determines whether the USER_LIST is composed names or ids by testing to see if the items in the list are all integers or not. This means that, if a user has a name that is also a valid integer, this name must be passed in a list with other usernames that are not.

C<time_since> also fetches the current time, which is retrievable via a call to C<time_since_now>.

Exceptions: 'Unable to process request', 'Parse error:'

=item $ticker-E<gt>available_rooms

This method returns a list of available rooms. The first item in this list is the "go outside" superdoc.

Each item in this list is a hashref with the following keys:

	title	# The room's title
	id	# The room's node_id

This method returns C<undef> on failure.

Exceptions: 'Unable to process request', 'Parse error:'

=item $ticker-E<gt>best_users [ NOGODS ]

This method returns a list of Everything2's Best Users. If NOGODS (boolean) is specified, site admins are not included in the listing.

Each item in the returned list is a hashref with the following keys:

	user		# Username of this user
	id		# user_id of this user
	experience	# This user's experience number
	writeups	# The number of writeups this user has posted
	level		# The level of this user (integer)
	level_string	# The level string of this user 
			# Example: "11 (Godhead)"

NOTE: The e2 server currently ignores the NOGODS option (ebu_noadmins) and instead serves a list based upon the logged-in user's preference (specified in a checkbox on http://everything2.com/?node=Everything's+Best+Users). The NOGODS option should be considered broken (ignored) until this is resolved serverside.

Exceptions: 'Unable to process request', 'Parse error:'

=item $ticker-E<gt>node_heaven [ NODE_ID ]

This method returns a list of the currently-logged-in user's node heaven (deleted writeups). If NODE_ID is specified, it returns a list with a single element, the deleted writeup corresponding to that NODE_ID. If the specified NODE_ID is not a deleted writeup, or if the user has no deleted writeups, this method returns an empty list.

If the current user is not logged-in, this method returns C<undef>.

Each element in the returned list is a hashref with the following keys:

	title		# The title of the writeup
	id		# The node_id of the writeup
	reputation	# The reputation the writeup had when deleted
	createtime	# The timestamp of the writeup's creation

If NODE_ID is specified, the additional key will be included:

	text		# The text of the writeup

Exceptions: 'Unable to process request', 'Parse error:'

=item $ticker-E<gt>maintenance_nodes

This method returns a list of maintenance nodes (example: "E2 Nuke Request"). It returns a list of hashrefs with the following keys:

	title	# Title of node
	id	# node_id of node

Exceptions: 'Unable to process request', 'Parse error:'

=item $ticker-E<gt>raw_vars

This method returns a hashref to the current user's "raw vars" hash on E2. It consists of a number of key/value pairs.

Exceptions: 'Unable to process request', 'Parse error:'

=item $ticker-E<gt>load_interfaces

This method loads the site-independant list of ticker nodes. E2::Ticker holds its own default list, but extremely paranoid clients can call C<load_interface> to make sure it's using the up-to-date list of ticker interfaces.

The loaded list can be accessed by calling C<interfaces>.

This method returns true on success.

Exceptions: 'Unable to process request', 'Parse error:'

=item $ticker-E<gt>interfaces

This method returns the list of xml interfaces used to load xml tickers. It returns a hashref with keys corresponding to the names of the interfaces and values corresponding to the node title of the corresponding ticker.

=item $ticker-E<gt>random_nodes_wit

This method returns the "random wit" that was fetched by the last call to C<random_nodes>. Returns C<undef> if none have been fetched.

=item $ticker-E<gt>time_since_now

This method returns the "now" value returned by the last call to C<time_since>. Returns C<undef> if that method has not been called.

=item $ticker-E<gt>use_string STRING

This method can be used to load a ticker from an XML string rather than the everything2.com server. It's used internally for debugging the tickers, and can be used to cache ticker pages (see C<E2::Interface::document>).

C<use_string> only affects the next ticker-loading method called. Example usage:

	my $xml_string = ... ;
	$ticker->use_string( $xml_string );

	my @w = $ticker->new_writeups;	# loaded from $xml_string

	my @w2 = $ticker->new_writeups; # This time it's loaded from the
					# e2 servers.

C<use_string> does not check whether the string is of the proper type for that particular ticker-loading method, nor does it check whether or not the string is valid XML. If you use this method, it is assumed you know what you are doing.

=back

=head1 SEE ALSO

L<E2::Interface>,
L<E2::Search>,
L<E2::Usersearch>,
L<E2::Message>,
L<E2::Session>,
L<E2::ClientVersion>,
L<E2::Scratchpad>,
L<http://everything2.com>,
L<http://everything2.com/?node=clientdev>

=head1 AUTHOR

Jose M. Weeks E<lt>I<jose@joseweeks.com>E<gt> (I<Simpleton> on E2)

=head1 COPYRIGHT

This software is public domain.

=cut
