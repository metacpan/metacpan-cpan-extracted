# E2::Writeup
# Jose M. Weeks <jose@joseweeks.com>
# 23 June 2003
#
# See bottom for pod documentation.

package E2::Writeup;

use 5.006;
use strict;
use warnings;
use Carp;
use HTML::Entities;

use E2::Node;

our @ISA = "E2::Node";
our $VERSION = "0.33";
our $DEBUG; *DEBUG = *E2::Interface::DEBUG;

# Prototypes

sub new;

sub clear;

sub wrtype;
sub parent;
sub parent_id;
sub marked;
sub rep;
sub text;
sub cools;
sub cool_count;

sub cool;

sub update;

# Private

sub type_as_string;
sub twig_handlers;
sub parse;

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
	my $self = shift	or croak "Usage: clear E2WRITEUP";

	warn "E2::Writeup::clear\n"	if $DEBUG > 1;
	
	$self->{author} 	= undef;
	$self->{author_id}	= undef;
	$self->{wrtype}		= undef;
	$self->{parent}		= undef;
	$self->{parent_id}	= undef;
	$self->{marked}		= undef; # Marked for destruction
	$self->{text}		= undef;
	$self->{cool_count}	= 0;

	$self->{rep}		= {};	# Hash with the following keys:
					#	o up
					#	o down
					#	o total
					#	o cast

	@{$self->{cools} }	= ();	# List of cools, each a hashref
					# with the following keys:
					#	o name # username of C!er
					#	o id   # user_id of C!er

	# Now clear parent

	return $self->SUPER::clear;
}

sub type_as_string {
	return 'writeup';
}

sub parse {
	my $self = shift	or croak "Usage: parse E2WRITEUP, TWIG";
	my $b = shift		or croak "Usage: parse E2WRITEUP, TWIG";

	warn "E2::Writeup::parse\n"	if $DEBUG > 1;

	# $b is an XML::Twig

	$self->{node_id}	= $b->{att}->{node_id};
	$self->{createtime}	= $self->decode_xml( $b->{att}->{createtime} );
	$self->{marked}		= $b->{att}->{marked};
	$self->{wrtype}		= $b->first_child('writeuptype')->text;
				
	my $c			= $b->first_child('parent')->
					first_child('e2link');

	$self->{parent}		= $self->decode_xml( $c->text );
	$self->{parent_id}	= $c->{att}->{node_id};

	$self->{title}   	= $self->decode_xml(
					$b->first_child('title')->text
				  );

	$c 			= $b->first_child('author');
	$self->{author}		= $self->decode_xml( $c->text );
	$self->{author_id}	= $c->{att}->{user_id};

	$c			= $b->first_child('doctext');
	if( $c ) { 
		$self->{text} = $self->decode_xml($c->text);
	}

	$c			= $b->first_child('reputation');
	if( $c ) {
		$self->{rep}->{up}	= $c->{att}->{up};
		$self->{rep}->{down}	= $c->{att}->{down};
		$self->{rep}->{cast}	= $c->{att}->{cast};
		$self->{rep}->{total}	= $c->text;
	}
	
	@{ $self->{cools} }   = ();
	$self->{cool_count} = 0;
	
	if( my $cools = $b->first_child('cools') ) {
		foreach my $d ( $cools->children('e2link') ) {
			push @{ $self->{cools} }, {
				name => $self->decode_xml( $d->text ),
				id   => $d->{att}->{node_id} 
			};
			$self->{cool_count}++;
		}
	}

	return 1;
}

sub twig_handlers {
	my $self = shift or croak "Usage: twig_handlers E2WRITEUP";

	return (
		'writeup' => sub {
			(my $a, my $b) = @_;
			$self->parse( $b );
		}
	);
}

sub cool {
	my $self = shift	or croak "Usage: cool E2WRITEUP [, NODE_ID ]";
	my $node_id = shift || $self->node_id;

	warn "E2::Writeup::cool\n"	if $DEBUG > 1;

	if( !$self->logged_in ) {
		warn "Unable to cool: not logged in"		if $DEBUG;
		return undef;
	}
	if( !$node_id ) {
		warn "Unable to cool: no node specified"	if $DEBUG;
		return undef;
	}

	return $self->thread_then(
		[
			\&E2::Interface::process_request,
			$self,
			node_id => $node_id,
			op	=> "cool",
			displaytype => "xmltrue"
		],
	sub {
		# FIXME: add check
		return 1;
	});
}

sub vote {
	my ($self, $vote) = @_;
	
	if( $vote != -1 && $vote != 1 ) {
		croak "Usage: vote E2WRITEUP, -1 | 1";
	}

	warn "E2::Writeup::vote\n"	if $DEBUG > 1;
	
	if( !$self->logged_in ) {
		warn "Unable to vote: not logged in"		if $DEBUG;
		return undef;
	}

	if( $self->this_user_id == $self->author_id ) {
		warn "Unable to vote on your own writeup"	if $DEBUG;
		return undef;
	}

	if( $self->rep->{cast} ) {
		warn "Unable to vote on a writeup more than once" if $DEBUG;
		return undef;
	}

	my %req = (
		node_id				=> $self->node_id,
		op				=> 'vote',
		displaytype			=> 'xmltrue',
		'vote__' . $self->node_id	=> $vote
	);

	return $self->thread_then(
		[
			\&E2::Interface::process_request,
			$self,
			%req
		],
	sub {
		my $r = shift;

#		if( !($r =~ /<node /s ) ) {
#			return undef;
#		}

		# Parse, and if it parses, return rep->{cast}.

		return undef if ! $self->load_from_xml( $r );
		return $self->rep->{cast} || 0;
	});
}

sub reply {
	my $self = shift	or croak "Usage: reply E2WRITEUP, TEXT [, CC ]";
	my $text = shift	or croak "Usage: reply E2WRITEUP, TEXT [, CC ]";
	my $cc   = shift;
	
	warn "E2::Writeup::reply\n"	if $DEBUG > 1;

	if( !$self->logged_in ) {
		warn "Unable to reply: not logged in"		if $DEBUG;
		return undef;
	}

	if( !$self->exists ) {
		warn "Unable to reply: no writeup loaded"	if $DEBUG;
		return undef;
	}

	my $id = $self->node_id;
	my %req = (
		node_id		  => $id,
		op		  => 'vote',
		"msgwuauthor_$id" => $text
	);

	$req{"ccmsgwuauthor_$id"} = 1 if $cc;
	
	$self->thread_then(
		[
			\&E2::Interface::process_request,
			$self,
			%req
		],
	sub {
		my $r = shift;

		# Simple test. We can't send messages if we specify
		# displaytype=xmltrue, so we're stuck with the HTML
		# page. Hopefully any page formatting/theme issues
		# won't break this if we keep it small.

		if( ($r =~ /\(sent writeup message/s) &&
		    ($r =~ /you said "re/s) ) {
		    	return 1;
		}

		return 0;
	});
}
	
sub update {
	my $self = shift	or croak "Usage: update_writeup E2WRITEUP, TEXT [ , TYPE ]";
	my $text = shift	or croak "Usage: update_writeup E2WRITEUP, TEXT [ , TYPE ]";
	my $type_s = shift;
	my $type;

	warn "E2::Writeup::update\n"	if $DEBUG > 1;

	# Translate type to code

	my %h = (	person	=> 249,
			thing	=> 250,
			idea	=> 251,
			place	=> 252 );

	# Make sure we are logged-in and this is our writeup

	if( !$self->logged_in ) {
		warn "Unable to update: not logged in"		if $DEBUG;
		return undef;
	}

	if( lc($self->this_username) ne lc($self->author) )	{ 
		warn "Unable to update: not your writeup"	if $DEBUG;
		return undef;
	}

	if( !$type_s ) {
		$type_s = $self->wrtype;
	}
	
	$type = $h{ lc( $type_s ) };
	if( !$type ) {
		croak "Invalid type: $type_s";
	}

	# Request

	$self->thread_then(
		[
			\&E2::Interface::process_request,
			$self,
			node_id 	=> $self->node_id,
			writeup_wrtype_writeuptype => $type,
			displaytype	=> "xmltrue",
			sexisgood	=> "submit",
			writeup_doctext	=> $text
		],
	sub {
		my $r = shift;

		if( !($r =~ /<node /s ) ) {
			return undef;
		}

		return $self->load_from_xml( $r );
	});
}

#---------------
# Access Methods
#---------------

sub wrtype {
	my $self = shift or croak "Usage: wrtype E2WRITEUP";
	return $self->{wrtype};
}

sub parent {
	my $self = shift or croak "Usage: parent E2WRITEUP";
	return $self->{parent};
}

sub parent_id {
	my $self = shift or croak "Usage: parent_id E2WRITEUP";
	return $self->{parent_id};
}

sub marked {
	my $self = shift or croak "Usage: marked E2WRITEUP";
	return $self->{marked};
}

sub rep {
	my $self = shift or croak "Usage: rep E2WRITEUP";

	return $self->{rep};
}

sub text {
	my $self = shift or croak "Usage: text E2WRITEUP";
	return $self->{text};
}

sub cool_count {
	my $self = shift or croak "Usage: cool_count E2WRITEUP";
	return $self->{cool_count};
}

sub cools {
	my $self = shift or croak "Usage: cools E2WRITEUP";
	return () if ! defined $self->{cools};

	return @{ $self->{cools} };
}

1;
__END__
		
=head1 NAME

E2::Writeup - A module for accessing, updating, and cooling writeups.

=head1 SYNOPSIS

	use E2::Writeup;
	use E2::E2Node;  # Used to load the writeup.

	my $e2node = new E2::E2node;

	$e2node->load( "test" ) or die "Unable to load test.";

	my $writeup = $e2node->get_writeup; # Returns an E2::Writeup
	
	# Print writeup info (See E2::Node for these)

	print "Title: . $writeup->title;
	print "\nAuthor: " . $writeup->author;
	print "\nDoctext: " . $writeup->text;

	# Downvote the writeup

	$writeup->vote( -1 );
	
	# Cool the writeup

	$writeup->cool;

	# Reply to the writeup's author

	$writeup->reply( "I just downvoted and cooled your writeup" );

	# Update the writeup

	$writeup->update( 
		$writeup->text . "THIS TEXT APPENDED TO WRITEUP"
	);

=head1 DESCRIPTION

This module is used to load, access, and manipulate writeups on E2. It is probably best used in conjunction with L<E2::E2Node|E2::E2Node>. It inherits L<E2::Node|E2::Node>.

The relationship between writeups and e2nodes is such that e2nodes I<contain> writeups (0 or more writeups, specifically). E2::Writeup defines the operations that can be performed on writeups contained within e2nodes. Technically, we I<could> load a writeup without loading its enclosing e2node (just pass C<load_by_id> the id of a writeup), but doing so would discard much of the information passed to us (softlinks, firmlinks, etc.). If you want access to this sort of information, use E2::E2Node to load the node, then access the writeup using on of its C<get_writeup> methods.
 
=head1 CONSTRUCTOR

=over

=item new

C<new> creates a new C<E2::E2Node> object. Until that object is logged in in one way or another (see L<E2::Interface>), it will use the "Guest User" account, and will be limited in which operations it can perform.

=back

=head1 METHODS

=over

=item $writeup-E<gt>clear

C<clear> clears all the information currently stored in $writeup. It returns true.

=item $writeup-E<gt>wrtype

=item $writeup-E<gt>parent

=item $writeup-E<gt>parent_id

=item $writeup-E<gt>marked

=item $writeup-E<gt>cool_count

=item $writeup-E<gt>text

These methods return, respectively, the writeup's type, its parent's title, its parent's node_id, its "marked for destruction" status (boolean: is it marked for destruction?), the number of C!s it has received, and the text of the writeup. 

=item $writeup-E<gt>cools

This method returns a list of the users who've cooled this writeup. Each item in the list is a hashref with the following keys:

	name
	id

=item $writeup-E<gt>rep

This method returns a hashref concerning the reputation of this writeup. It contains the following keys:

	up	# Upvotes
	down	# Downvotes
	total	# Total rep (should be == to upvotes - downvotes)
	cast	# Have you already cast your vote? (boolean)

=item $writeup-E<gt>cool [ NODE_ID ]

This method attempts to cool (C!) a writeup. If NODE_ID is specified, it attempts to cool the writeup with that id, otherwise it attempts to cool the currently-loaded writeup.

Exceptions: 'Unable to process request'

=item $writeup-E<gt>vote -1 | 1

This method attempts to vote on this writeup (-1 for a downvote, 1 for an upvote).

This method returns C<undef> if unable to vote (if the user is trying to vote on his own writeup, if a writeup hasn't been C<load>ed to vote on, or if the user has already voted on this writeup). It also returns C<undef> if it encounters a server error.

This method returns 1 if the vote "caught," and 0 if it did not (which probably means the user is out of votes).

Exceptions: 'Unable to process request', 'Invalid document', 'Parse error:'

=item $writeup-E<gt>reply TEXT [, CC ]

This method sends a "blab" message reply to the author of the currently-loaded writeup. If CC is true, it sends a copy of the message to you, the sender.

This method returns C<undef> if no writeup is loaded or if we're currently not logged in (Guest User can't send messages). It returns true on success and 0 on failure (0 means it didn't get the response confirmation it expected--the message may have gone through anyway).

There is no guarantee, if either an exception is raised or this method returns 0, that the message didn't go through. There is, however, a guarantee that if it returns C<undef>, it did not. 

One strategy for determining success absolutely would be to (1) always set CC as true, (2) after replying, use E2::Message::list_private to list received messages, and check to make sure the message made it through, and (3) delete the cc'd message.

This, of course, may be a bit drastic.

Exceptions: 'Unable to process request'

=item $writeup-E<gt>update TEXT [ , TYPE ]

C<update> updates the currently-loaded writeup. TYPE, which defaults to the type the writeup was prior to the update, is the type of writeup this is (one of: "person", "place", "thing", or "idea"). During the update, the writeup is re-loaded, so any changes should be immediately visible in this object.

This method returns true on success and C<undef> on failure.

Exceptions: 'Unable to process request', 'Invalid document', 'Parse error:'

=back

=head1 SEE ALSO

L<E2::Interface>,
L<E2::Node>,
L<E2::E2Node>,
L<http://everything2.com>,
L<http://everything2.com/?node=clientdev>

=head1 AUTHOR

Jose M. Weeks E<lt>I<jose@joseweeks.com>E<gt> (I<Simpleton> on E2)

=head1 COPYRIGHT

This software is public domain.

=cut
