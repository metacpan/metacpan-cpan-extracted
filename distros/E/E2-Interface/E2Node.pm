# E2::E2Node
# Jose M. Weeks <jose@joseweeks.com>
# 03 July 2003
#
# See bottom for pod documentation.

package E2::E2Node;

use 5.006;
use strict;
use warnings;
use Carp;

use E2::Node;
use E2::Writeup;

our @ISA = "E2::Node";
our $VERSION = "0.33";
our $DEBUG; *DEBUG = *E2::Interface::DEBUG;

# Prototypes

sub new;
sub clear;

sub has_mine;
sub is_locked;

sub list_writeups;
sub list_softlinks;
sub list_firmlinks;
sub list_sametitles;

sub get_writeup;
sub get_writeup_by_author;
sub get_my_writeup;
sub get_writeup_number;
sub get_writeup_count;

sub vote;

sub add_writeup;
sub create;

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
	my $self = shift	or croak "Usage: clear E2E2NODE";

	warn "E2::E2Node::clear\n"	if $DEBUG > 1;

	@{ $self->{writeups} } = ();	 # Array to hold writeups in currently
					 # loaded node. See E2::Writeup.
	
	$self->{locked}		= undef; # soft locked

	$self->{next}		= 0;	 # Next writeup to return
	$self->{mine}		= undef; # My writeup in this node.

	@{ $self->{firmlinks} }	= ();	 # List of firmlinks
	@{ $self->{softlinks} }	= ();	 # List of softlinks
	@{ $self->{sametitles}}	= ();	 # List of sametitles
					 # The preceding three return hashrefs
					 # with the following keys:
					 # 	o title
					 # 	o id
					 # sametitles has this as well:
					 # 	o type

	# Now clear parent

	return $self->SUPER::clear;
}

sub has_mine {
	my $self = shift	or croak "Usage: has_mine E2E2NODE";

	if(!$self->node_id)	{ return undef; }	# No node loaded

	if( defined( $self->{mine} ) ) { 
		return 1;
	}

	return 0;
}

sub is_locked {
	my $self = shift	or croak "Usage: is_locked E2E2NODE";

	if( !$self->node_id )	{ return undef; }

	if( $self->{locked} )	{ return 1; }
	else			{ return 0; }
}

sub list_softlinks {
	my $self = shift	or croak "Usage: list_softlinks E2NODE";

	return undef if !$self->node_id;
	
	return @{ $self->{softlinks} };
}

sub list_firmlinks {
	my $self = shift	or croak "Usage: list_firmlinks E2NODE";

	return undef if !$self->node_id;
	
	return @{ $self->{firmlinks} };
}

sub list_sametitles {
	my $self = shift	or croak "Usage: list_sametitles E2NODE";

	return undef if !$self->node_id;

	return @{ $self->{sametitles} };
}

sub twig_handlers {
	my $self = shift or croak "Usage: twig_handlers E2E2NODE";

	return (

		'node/nodelock' => sub {
			(my $a, my $b) = @_;
			$self->{locked} = $b->text;
			if( $self->{locked} eq "" ) {
				$self->{locked} = undef;
			}
		},
		'node/writeup' => sub {
			(my $a, my $b) = @_;

			my $wu = new E2::Writeup;
			$wu->clone( $self );
			$wu->parse( $b );

			my $name = $self->this_username;
			my $uid = $self->this_user_id;
			
			if( $self->logged_in &&
				($uid ?	$uid == $wu->author_id :
					lc($name) eq lc($wu->author)) ) {
				$self->{mine} = @{ $self->{writeups} };
			}

			push @{ $self->{writeups} }, $wu;
		},
		'node/softlinks/e2link' => sub {
			(my $a, my $b) = @_;
			push @{ $self->{softlinks} }, {
				title => $b->text,
				id    => $b->{att}->{node_id}
			};
		},
		'node/firmlinks/e2link' => sub {
			(my $a, my $b) = @_;
			push @{ $self->{firmlinks} }, {
				title => $b->text,
				id    => $b->{att}->{node_id}
			};
		},
		'node/sametitles/nodesuggest' => sub {
			(my $a, my $b) = @_;
			my $c = $b->first_child( 'e2link' );
			push @{ $self->{sametitles} }, {
				title => $c->text,
				type  => $b->{att}->{type},
				id    => $c->{att}->{node_id}
			};
		}
	);
}

sub type_as_string {
	return 'e2node';
}

sub list_writeups {
	my $self = shift	or croak "Usage: list_writeups E2E2NODE";

	return undef if !$self->exists;
	return @{ $self->{writeups} };
}

sub get_writeup {
	my $self = shift	or croak "Usage: get_writeup E2E2NODE [ , NUM ]";
	my $num  = shift;

	if( $num ) { 
		$self->{next} = $num;
	}

	return $self->{writeups}[ $self->{next}++ ];
}

sub get_writeup_by_author {
	my $self   = shift
		or croak "Usage: get_writeup_by_author E2E2NODE, AUTHOR";
	my $author = shift
		or croak "Usage: get_writeup_by_author E2E2NODE, AUTHOR";

	if( !$self->node_id ) { return undef; }

	for( my $i = 0; $i < @{ $self->{writeups} }; $i++ ) {
		if( lc($author) eq 
		    lc($self->{writeups}[$i]->author) ) {
			return $self->{writeups}[$i];
		}
	}

	return 0;
}

sub get_my_writeup {
	my $self = shift	or croak "Usage: get_my_writeup E2E2NODE";
	my $i = $self->{mine};

	if( ! defined $i ) { return undef; }

	return $self->{writeups}[$i];
}

sub get_writeup_number {
	my $self = shift	or croak "Usage: get_writeup_number E2E2NODE";

	if( !$self->node_id ) { return undef; }
	return $self->{next};
}

sub get_writeup_count {
	my $self = shift	or croak "Usage: get_writeup_count E2E2NODE";

	if( !$self->node_id ) { return undef; }

	return $$self->{writeups};
}

sub create {
	my $self  = shift	or croak "Usage: create E2E2NODE, TITLE";
	my $title = shift	or croak "Usage: create E2E2NODE, TITLE";

	warn "E2::E2Node::create\n"	if $DEBUG > 1;

	# Make sure we have username & user_id

	if( !$self->logged_in ) {
		warn "Unable to create node: not logged in"	if $DEBUG;
		return undef;
	}

	return $self->thread_then(
		[
			\&E2::Interface::process_request,
			$self,
			node 	=> $title,
		  	op	=> "new",
		  	type	=> "e2node",
		  	displaytype => "xmltrue",
		  	e2node_createdby_user => $self->{user_id}
		],
	sub {

		my $r = shift;
		if( !$r =~ /<author .*?user_id="(.*?)"/s ) { 
			croak "Invalid document";
		}

		$self->load_from_xml( $r );

		return $self->exists;
	});
}

# FIXME: Allow multiple votes/replies/etc. in one request.

sub vote {
	my $self = shift or croak "Usage: vote E2E2NODE, NODE_ID => VOTE [ , NODE_ID2 = VOTE2 [ , ... ] ]";
	my %list = @_    or croak "Usage: vote E2E2NODE, NODE_ID => VOTE [ , NODE_ID2 = VOTE2 [ , ... ] ]";

	warn "E2::E2Node::vote\n"	if $DEBUG > 1;

	if( !$self->logged_in ) {
		warn "Unable to vote: not logged in"	if $DEBUG;
		return undef;
	}

	my %params = (	node_id		=> $self->{node_id},
			op		=> "vote",
			displaytype	=> "xmltrue");

	foreach( keys %list ) {
		my $v = $list{$_};

		if( $v != 1 && $v != -1 ) { next; }

		$params{ "vote__$_" } = $v;
	}

	return $self->thread_then(
		[
			\&E2::Interface::process_request,
			$self,
			%params
		],
	sub {
		my $r = shift;
		
		if( !($r =~ /<node /s ) ) {
			croak 'Invalid document';
		}

		return  $self->load_from_xml( $r );
	});
}

sub add_writeup {
	my $self = shift
	  or croak "Usage: add_writeup E2E2NODE, TEXT, TYPE [ , NODISPLAY ]";
	my $text = shift
	  or croak "Usage: add_writeup E2E2NODE, TEXT, TYPE [ , NODISPLAY ]";
	my $type = shift
	  or croak "Usage: add_writeup E2E2NODE, TEXT, TYPE [ , NODISPLAY ]";
	my $nodisplay = shift;

	warn "E2::E2Node::add_writeup\n"	if $DEBUG > 1;

	if( !$self->logged_in ) {
		warn "Unable to add writeup: not logged in"	if $DEBUG;
		return undef;
	}

	return $self->thread_then(
		[
			\&E2::Interface::process_request,
			$self,
			node	=> "new writeup",
			op	=> "new",
			type	=> "writeup",
			node	=> $self->{node_id},	# Why two "node" params?
			writeup_notnew	=> $nodisplay,  # dunno....
			writeup_doctext	=> $text,
			writeup_parent_e2node	=> $self->{node_id},
			writeuptype	=> $type
		],
	sub {
	
		# FIXME - Add code to test for success.

		return 1;
	});
}

1;
__END__
		
=head1 NAME

E2::E2Node - A module for fetching, accessing, and manipulating e2nodes on L<http://everything2.com>.

=head1 SYNOPSIS

	use E2::E2Node;

	my $node = new E2::E2Node;
	$node->login( "username", "password" ); # See E2::Interface

	if( $node->load( "Butterfinger McFlurry" ) ) { # See E2::Node
		print $node->title . " :\n\n";         # See E2::Node
		while( my $w = $node->get_writeup ) {
			print $w->title . " by ";      # See E2::Writeup
			print $w->author;              # See E2::Writeup
			print "\n" . $w->text . "\n";  # See E2::Writeup
		}
	}

	# List softlinks
	
	print "\nSoftlinks:\n";
	foreach my $s ($node->list_softlinks) {
		print $s->{title} . "\n";
	}

=head1 DESCRIPTION

This module provides an interface to L<http://everything2.com>'s e2nodes and writeups. It inherits L<E2::Node|E2::Node>.

C<E2::E2Node> is used by loading an entire node (via E2::Node's C<load> or C<load_by_id>) and then operating upon the writeups within that node. It is capable of listing and retrieving the writeups in a node, creating nodes, adding writeups to a node, and voting upon writeups in a node.

=head1 CONSTRUCTOR

=over

=item new

C<new> creates a new C<E2::E2Node> object. Until that object is logged in in one way or another (see L<E2::Interface>), it will use the "Guest User" account, and will be limited in what information it can fetch and which operations it can perform.

=back

=head1 METHODS

=over

=item $node-E<gt>clear

C<clear> clears all the information currently stored in $node. 

=item $node-E<gt>has_mine

=item $node-E<gt>is_locked

Boolean: "Does this node have a writeup by me in it?"; "Is this node softlocked?"

C<is_locked> is actually a string value, if true, consisting of the text of the softlock.

=item $node-E<gt>list_softlinks

=item $node-E<gt>list_firmlinks

=item $node-E<gt>list_sametitles

These methods return a list of softlinks, firmlinks, or sametitles.

They each return a list of hashrefs. C<list_softlinks> and C<list_firmlinks> return hashrefs with the keys "title" and "id". C<list_sametitles>, which deals with the "'x' is also a: user / room / etc.", has the additional key of "type".

These return empty lists if the current node has none of the respective softlinks, firmlinks, or sametitles, or C<undef> if there is no node currently loaded.

=item $node-E<gt>list_writeups

C<list_writeups> returns a list of E2::Writeups corresponding to the writeups in the currently-loaded node. It returns an empty list if this node contains no writeups, and C<undef> if there is no node currently loaded.

NOTE: All E2::Writeups returned by these methods are C<clone>d from $node, and therefore share the same login cookie, background threads, etc.

=item $node-E<gt>get_writeup [ NUM ]

=item $node-E<gt>get_writeup_by_author AUTHOR

=item $node-E<gt>get_my_writeup

These methods return references to E2::Writeup objects. C<get_writeup> returns the NUM'th writeup in the current node (or, if NUM is not specified, the writeup immediately succeeding the last writeup returned by C<get_writeup>). C<get_writeup_by_author> returns the writeup in the current node that was written by AUTHOR. C<get_my_writeup> returns the writeup in the current node written by the currently-logged-in user. See the E2::Writeup manpage for information about accessing writeup data.

NOTE: All E2::Writeups returned by these methods are C<clone>d from $node, and therefore share the same login cookie, background threads, etc.

These methods return C<undef> if they cannot return a writeup.

=item $node-E<gt>get_writeup_count

C<get_writeup_count> returns the number of writeups in the current node. Returns C<undef> if there is no node currently loaded.

=item $node-E<gt>get_writeup_number

C<get_writeup_number> returns the number of the next writeup that C<get_writeup> will, by default, return. Returns C<undef> if there is no node currently loaded.

=item $node-E<gt>vote NODE_ID =E<gt> VOTE [ , NODE_ID2 =E<gt> VOTE2 [ , ... ] ]

C<vote> votes on a list of writeups. There should be a NODE_ID =E<gt> VOTE pair for each writeup to vote upon. NODE_ID is the node_id of the writeup, and VOTE is either -1 or 1, (downvote or upvote, respectively).

This method returns C<undef> if there is no node currently loaded, otherwise it returns true. THIS DOES NOT NECESSARILY MEAN THE VOTES WENT THROUGH.

In the process of voting, the current node is re-fetched and re-loaded, and if the caller wishes to determine whether each vote "caught" (as opposed to just refreshing the display or file or whatever output he is using, which will reflect the changes), he must do so manually.

Exceptions: 'Unable to process request', 'Invalid document'

=item $node-E<gt>add_writeup TEXT, TYPE [ , NODISPLAY ]

C<add_writeup> adds a new writeup to the current node. TEXT is the text of the writeup, TYPE is the type of writeup it is (one of: "person", "place", "thing", or "idea"), and NODISPLAY, if true (it defaults to false), tells E2 not to display this writeup in "New Writeups". It returns true on success and C<undef> on failure.

Exceptions: 'Unable to process request'

=item $node-E<gt>create TITLE

C<create> creates a new node (a "nodeshell") of title TITLE, then loads this new node.

It returns true if the created node now exists. Otherwise returns C<undef>.

Exceptions: 'Unable to process request', 'Invalid document'

=back

=head1 SEE ALSO

L<E2::Interface>,
L<E2::Node>,
L<E2::Writeup>,
L<http://everything2.com>,
L<http://everything2.com/?node=clientdev>

=head1 AUTHOR

Jose M. Weeks E<lt>I<jose@joseweeks.com>E<gt> (I<Simpleton> on E2)

=head1 COPYRIGHT

This software is public domain.

=cut
