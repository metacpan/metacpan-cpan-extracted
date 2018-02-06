package HTML::DOM::NodeList::Magic;

use strict;
use warnings;
use overload fallback => 1, '@{}' => \&_get_tie;

use Scalar::Util 'weaken';

our $VERSION = '0.058';

# Innards: {
#	get => sub { ... }, # sub that gets the list
#	list => [ ... ], # the list, or undef
#	tie => \@tied_array, # or undef, if the array has not been
#	                     # accessed yet
# }


# new NodeList sub { ... }
# new NodeList sub { ... }, $doc
# The sub needs to return the list of nodes.

sub new {
	my $self = bless {get => $_[1]}, shift;
	($_[1]||return $self)->_register_magic_node_list($self);
	$self;
}

sub item {
	my $self = shift;
	# Oh boy! Look at these brackets!
	${$$self{list} ||= [&{$$self{get}}]}[$_[0]];
}

sub length {
	my $self = shift;
	# Oh no, here we go again.
	scalar @{$$self{list} ||= [&{$$self{get}}]};
}

sub _you_are_stale {
	delete $_[0]{list};
}

sub DOES {
	return !0 if $_[1] eq 'HTML::DOM::NodeList';
	eval { shift->SUPER::DOES(@_) } || !1
}

# ---------- TIES --------- # 

sub _get_tie {
	my $self = shift;
	$$self{tie} or
		weaken(tie @{ $$self{tie} }, __PACKAGE__, $self),
		$$self{tie};
}

sub TIEARRAY  { $_[1] }
sub FETCH     { $_[0]->item($_[1]) }
sub FETCHSIZE { $_[0]->length }
sub EXISTS    { $_[0]->item($_[1]) } # nodes are true, undef is false
sub DDS_freeze { my $self = shift; delete $$self{tie}; $self }

# These are here solely to make HTML::DOM::Collection::Options work:
sub STORE {
	my($self,$indx,$val) = @_;
	if(defined $val) {
		if(my $deletee = $self->item($indx)) {
			$deletee->replace_with($val)->delete;
		}
		else {
			$self->item($self->length-1)->parentElement
				->appendChild($val);
		}
	}
	else {
		(my $thing = $self->item($indx))->ownerDocument;
		$self->item($indx)->detach
	}
	$self->_you_are_stale;
}
sub DELETE {
	for(shift) {
		$_->item(shift)->detach;
		$_->_you_are_stale;
	}
}

1;

__END__

=head1 NAME

HTML::DOM::NodeList::Magic - Magical node list class for HTML::DOM

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;

  $list = $doc->getElementsByTagName('p');
    # returns an HTML::DOM::NodeList::Magic object

  # OR:
  use HTML::DOM::NodeList::Magic;
  $list = new HTML::DOM::NodeList::Magic::
      sub {
          # ... return a list of items ...
      },
      $doc;
    
  $list->[0];     # first node
  $list->item(0); # same
  
  $list->length; # same as scalar @$list

=head1 DESCRIPTION

See L<HTML::DOM::NodeList> both for a description and the API.

There is one difference, though: If you want to create a NodeList yourself,
for whatever reason, you can call the constructor shown in the synopsis.
The subroutine has to return the entire list that the node list is supposed
to contain.  The second argument is the document to which the node belongs.
If the document is modified, the node list is automatically notified, and
calls the subroutine again the next time it is accessed, to reset itself.
If you don't provide the document, the node list will never be updated
after the first time an element is accessed.

=head1 SEE ALSO

L<HTML::DOM>

L<HTML::DOM::NodeList>
