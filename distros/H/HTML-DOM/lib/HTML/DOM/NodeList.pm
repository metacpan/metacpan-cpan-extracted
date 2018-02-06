package HTML::DOM::NodeList;

use strict;
use warnings;
use overload fallback => 1, '@{}' => sub { ${$_[0]} };

use Scalar::Util 'weaken';

our $VERSION = '0.058';


# new NodeList \@array;

sub new {
	bless do {\(my $x = $_[1])}, shift;
}

sub item {
	${$_[0]}[$_[1]] || ()
}

sub length {
	scalar @${$_[0]}
}

1 __END__

=head1 NAME

HTML::DOM::NodeList - Simple node list class for HTML::DOM

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;

  $list = $doc->body->childNodes; # returns an HTML::DOM::NodeList
    
  $list->[0];     # first node
  $list->item(0); # same
  
  $list->length; # same as scalar @$list

=head1 DESCRIPTION

This implements the NodeList interface as described in the W3C's DOM 
standard. In addition to the methods below, you can use a node list object
as an array.

This class actually only implements those node lists that are based on
array references (as returned by C<childNodes> methods). The 
L<HTML::DOM::NodeList::Magic> class is used for more
complex node lists that call a code ref to update themselves. This is an
implementation detail though, that you shouldn't have to worry about.

=head1 OBJECT METHODS

=over 4

=item $list->length

Returns the number of items in the array.

=item $list->item($index)

Returns item number C<$index>, numbered from 0. Note that you can also use
C<< $list->[$index] >> for short.

=back

=head1 SEE ALSO

L<HTML::DOM>

L<HTML::DOM::NodeList::Magic>

L<HTML::DOM::Node>

L<HTML::DOM::Collection>
