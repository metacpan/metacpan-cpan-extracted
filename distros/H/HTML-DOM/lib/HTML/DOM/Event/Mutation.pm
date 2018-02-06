package HTML::DOM::Event::Mutation;

our $VERSION = '0.058';

use warnings; no warnings qw 'utf8 parenthesis';
use strict;

require HTML::DOM::Event;
our @ISA = HTML::DOM::Event::;

use constant 1.03 { ADDITION=>2, MODIFICATION=>1, REMOVAL=>3 };

use Exporter 5.57 'import';
our @EXPORT_OK = qw 'ADDITION MODIFICATION REMOVAL';
our %EXPORT_TAGS = (all => \@EXPORT_OK);


sub relatedNode          { $_[0]{rel_node      }||() }
sub prevValue        { $_[0]{prev_value    } }
sub newValue          { $_[0]{new_value      } }
sub attrName        { $_[0]{attr_name   } }
sub attrChange        { $_[0]{attr_change_type    } }

sub initMutationEvent {
	my $self = $_[0];
	my $x;
	$self->init(map +($_ => $_[++$x]),
		qw( type propagates_up cancellable rel_node prev_value
                    new_value attr_name attr_change_type )
	);
	return;
}

sub init {
	my $self = shift;
	my %args = @_;
	my %my_args = map +($_ => delete $args{$_}),
		qw( rel_node prev_value new_value attr_name
		    attr_change_type );
	$self->SUPER::init(%args);
	%$self = (%$self, %my_args);
	return;
}


*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|

__END__

=head1 NAME

HTML::DOM::Event::Mutation - A Perl class for HTML DOM mutation event objects

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  # ...

=head1 DESCRIPTION

This class provides MutationEvent objects for L<HTML::DOM>, which objects 
are
passed to event handlers for certain event types when they are invoked.
It inherits from L<HTML::DOM::Event>.

=head1 METHODS

See also those inherited from L<HTML::DOM::Event>.

=head2 DOM Attributes

These are all read-only and ignore their arguments.

=over

=item relatedNode

This holds the parent node for DOMNodeInserted and DOMNodeRemoved events,
and the Attr node involved for a DOMAttrModified event.

=item prevValue

The previous value for DOMAttrModified and DOMCharacterDataModified events.

=item newValue

The new value for the same two event types.

=item attrName

The name of the affected attribute for DOMAttrModified events.

=item attrChange

=back

=head2 Other Methods

=over

=item initMutationEvent ( $name, $propagates_up, $cancellable, $rel_node, $prev_value, $new_value, $attr_name, $attr_change_type )

This initialises the event object. See L<HTML::DOM::Event/initEvent> for
more detail.

=item init ( ... )

Alternative to C<initMutationEvent> that's easier to use:

  init $event
      type => $type,
      propagates_up => 1,
      cancellable => 1,
      rel_node => $node,
      new_value => $foo,
      prev_value => $bar,
      attr_name => $name,
      attr_change_type => HTML::DOM::Event::Mutation::REMOVAL,
  ;

=back

=head1 EXPORTS

The following constants are exported upon request, either individually or
with the ':all' tag. They indicated the type of change that a 
DOMAttrModified event represents.

=over

=item *

ADDITION

=item *

MODIFICATION

=item *

REMOVAL

=back

=head1 SEE ALSO

=over 4

L<HTML::DOM>

L<HTML::DOM::Event>

L<HTML::DOM::Event::Mouse>
