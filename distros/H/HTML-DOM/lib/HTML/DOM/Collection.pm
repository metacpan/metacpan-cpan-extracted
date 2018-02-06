package HTML::DOM::Collection;

use strict;
use warnings;

use Scalar::Util 'weaken';

our $VERSION = '0.058';

# Internals: \[$nodelist, $tie]

# Field constants:
sub nodelist(){0}
sub tye(){1}
sub seen(){2}     # whether this key has been seen
sub position(){3} # current (array) position used by NEXTKEY
sub ids(){4}      # whether we are iterating through ids
#  Number 5 is taken by ::Options (inside Element/Form.pm).
{ no warnings 'misc';
  undef &nodelist; undef &tye; undef &seen; undef &position;
}

use overload fallback => 1,
'%{}' => sub {
	my $self = shift;
	$$$self[tye] or
		weaken(tie %{ $$$self[tye] }, __PACKAGE__, $self),
		$$$self[tye];
},
'@{}' => sub { ${+shift}->[nodelist] };


sub new {
	bless \[$_[1]], shift;
}

my %NameableElements = map +($_ => 1), qw/
	a area object param applet input select textarea button frame 
	iframe meta form img map
/;

sub namedItem {
	my($self, $name) = @_;
	my $list = $$self->[nodelist];
	my $named_elem; my $elem;
	for(0..$list->length - 1) {
		no warnings 'uninitialized';
		($elem = $list->item($_))->id eq $name and return $elem;
		exists $NameableElements{$elem->tag} and
			$elem->attr('name') eq $name and
			$named_elem = $elem;
	}
	$named_elem ||()
}

# Delegated methosd
for (qw/length item/) {
	eval "sub $_ { \${+shift}->[" . nodelist . "]->$_(\@_) }"
}


sub TIEHASH { $_[1] }
sub FETCH     { $_[0]->namedItem($_[1]) }
sub EXISTS    { $_[0]->namedItem($_[1]) } # nodes are true, undef is false
sub FIRSTKEY {
	my $self = shift;
	(my $guts = $$self)->[seen] = {};
	my($id,$item);
	$guts->[ids] = 1;
	for (0..$self->length - 1) {
		defined($id = ($item = $self->item($_))->id)
			and ++$guts->[seen]{$id}, $guts->[position] = $_,
			    return($id);
	}
	# If none of the items has an id...
	$guts->[ids] = 0;
	for (0..$self->length - 1) {
		defined($id = ($item = $self->item($_))->attr('name'))
			and ++$guts->[seen]{$id}, $guts->[position] = $_,
			    return($id);
	}
	return; # empty list
}

sub NEXTKEY{
	my $self = shift;
	my $guts = $$self;
	my($id,$item);
	if($guts->[ids]) {
		for ($guts->[position]..$self->length - 1) {
			defined($id = ($item = $self->item($_))->id)
				and !$guts->[seen]{$id}++
				and $guts->[position] = $_,
				    return($id);
		}
	}
	# If we've exhausted all ids...
	$guts->[ids] = 0;
	for (0..$self->length - 1) {
		defined($id = ($item = $self->item($_))->attr('name'))
			and !$guts->[seen]{$id}++
			and $guts->[position] = $_,
			    return($id);
	}
	return;
}

sub SCALAR {
	defined FIRSTKEY @_;
}

sub DDS_freeze { my $self = shift; delete $$$self[tye]; $self }

1

__END__

=head1 NAME

HTML::DOM::Collection - A Perl implementation of the HTMLCollection interface

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;
  $doc->write('<html> ..... </html>');
  $doc->close;
  
  $images = $doc->images; # returns an HTML::DOM::Collection
    
  $images->[0];    # first image
  $images->{logo}; # image named 'logo'
  $images->item(0);
  $images->namedItem('logo');
  
  $images->length; # same as scalar @$images

=head1 DESCRIPTION

This implements the HTMLCollection interface as described in the W3C's DOM 
standard. This class is actually just a wrapper around the NodeList
classes. In addition to the methods below, you can use a collection as a
hash and as an array (both read-only).

=head1 CONSTRUCTOR

Normally you would simply call a method that returns an HTML collection
(as in the L</SYNOPSIS>). But if you wall to call the constructor, here is
the syntax:

  $collection = HTML::DOM::Collection->new($nodelist)

$nodelist should be a node list object.

=head1 OBJECT METHODS

=over 4

=item $collection->length

Returns the number of items in the collection.

=item $collection->item($index)

Returns item number C<$index>, numbered from 0. Note that you call also use
C<< $collection->[$index] >> for short.

=item $collection->namedItem($name)

Returns the item named C<$name>. If an item with an ID of C<$name> exists,
that will be returned. Otherwise the first item whose C<name> attribute is
C<$name> will be returned. You can also write C<< $collection->{$name} >>.

=back

=head1 SEE ALSO

L<HTML::DOM>

L<HTML::DOM::NodeList>
