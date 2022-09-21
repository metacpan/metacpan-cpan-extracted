##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Slot.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/06
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Slot;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :slot );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'slot' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

sub assign { return; }

sub assignedElements { return; }

sub assignedNodes { return; }

# Note: property name is inherited

sub onslotchange : lvalue { return( shift->on( 'slotchange', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Slot - HTML Object DOM Slot Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Slot;
    my $slot = HTML::Object::DOM::Element::Slot->new ||
        die( HTML::Object::DOM::Element::Slot->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface of the Shadow DOM API enables access to the name and assigned nodes of an HTML C<slot> element.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Slot |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 name

A string used to get and set the slot's name.

Example:

    my $slots = this->shadowRoot->querySelectorAll('slot');
    $slots->[1]->addEventListener( slotchange => sub
    {
        my $nodes = $slots->[1]->assignedNodes();
        say( 'Element in Slot "' . $slots->[1]->name . '" changed to "' . $nodes->[0]->outerHTML . '".');
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSlotElement/name>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head2 assign

Under perl environment, this always returns C<undef>.

Under JavaScript, this sets the manually assigned nodes for this slot to the given nodes.

Example:

    sub UpdateDisplayTab
    {
        my( $elem, $tabIdx ) = @_;
        my $shadow = $elem->shadowRoot;
        my $slot = $shadow->querySelector( 'slot' );
        my $panels = $elem->querySelectorAll( 'tab-panel' );
        if( $panels->length && $tabIdx && $tabIdx <= $panels->length )
        {
            $slot->assign( $panels->[ $tabIdx - 1 ] );
        }
        else
        {
            $slot->assign();
        }
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSlotElement/assign>

=head2 assignedElements

Under perl environment, this always returns C<undef>.

Under JavaScript, this returns a sequence of the elements assigned to this slot (and no other nodes). If the flatten option is set to true, it also returns the assigned elements of any other slots that are descendants of this slot. If no assigned nodes are found, it returns the slot's fallback content.

Example:

    my $slots = this->shadowRoot->querySelector('slot');
    my $elements = $slots->assignedElements({ flatten => 1 });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSlotElement/assignedElements>

=head2 assignedNodes

Under perl environment, this always returns C<undef>.

Under JavaScript, this returns a sequence of the nodes assigned to this slot, and if the flatten option is set to true, the assigned nodes of any other slots that are descendants of this slot. If no assigned nodes are found, it returns the slot's fallback content.

Example:

    my $slots = this->shadowRoot->querySelectorAll('slot');
    $slots->[1]->addEventListener( slotchange => sub
    {
        my $nodes = $slots->[1]->assignedNodes();
        say( 'Element in Slot "' . $slots->[1]->name . '" changed to "' . $nodes->[0]->outerHTML . '".' );
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSlotElement/assignedNodes>

=head1 EVENTS

Event listeners for those events can also be found by prepending C<on> before the event type:

For example, C<slotchange> event listeners can be set also with C<onslotchange> method:

    $e->onslotchange(sub{ # do something });
    # or as an lvalue method
    $e->onslotchange = sub{ # do something };

=head2 slotchange

Fired on an HTMLSlotElement instance (<slot> element) when the node(s) contained in that slot change.

Example:

    my $slots = this->shadowRoot->querySelectorAll('slot');
    $slots->[1]->addEventListener( slotchange => sub
    {
        my $nodes = $slots->[1]->assignedNodes();
        say( 'Element in Slot "' . $slots->[1]->name . '" changed to "' . $nodes->[0]->outerHTML . '".' );
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSlotElement/slotchange_event>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSlotElement>, L<Mozilla documentation on slot element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/slot>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
