##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/TextArea.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/09
## Modified 2022/01/09
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::TextArea;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'textarea' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

sub oninput : lvalue { return( shift->on( 'input', @_ ) ); }

sub onselectionchange : lvalue { return( shift->on( 'selectionchange', @_ ) ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::TextArea - HTML Object DOM TextArea Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::TextArea;
    my $textarea = HTML::Object::DOM::Element::TextArea->new || 
        die( HTML::Object::DOM::Element::TextArea->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface provides special properties and methods for manipulating the layout and presentation of <textarea> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::TextArea |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 EVENTS

Event listeners for those events can also be found by prepending C<on> before the event type:

C<click> event listeners can be set also with C<onclick> method:

    $e->onclick(sub{ # do something });
    # or as an lvalue method
    $e->onclick = sub{ # do something };

=head2 input

Fires when the value of an L<input|HTML::Object::DOM::Element::Input>, L<select|HTML::Object::DOM::Element::Select>, or L<textarea|HTML::Object::DOM::Element::TextArea> element has been changed.

Example:

    <input placeholder="Enter some text" name="name"/>
    <p id="values"></p>

    my $input = $doc->querySelector('$input');
    my $log = $doc->getElementById('values');

    $input->addEventListener( input => \&updateValue );

    sub updateValue
    {
        my $e = shift( @_ );
        $log->textContent = $e->target->value;
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/input_event>

=head2 selectionchange

Under perl, this does not do anything of course, but you can fire yourself the event.

Under JavaScript, this fires when the text selection in a L<textarea|HTML::Object::DOM::Element::TextArea> element has been changed.

Example:

    <div>Enter and select text here:<br><textarea id="mytext" rows="2" cols="20"></textarea></div>
    <div>selectionStart: <span id="start"></span></div>
    <div>selectionEnd: <span id="end"></span></div>
    <div>selectionDirection: <span id="direction"></span></div>

    my $myinput = $doc->getElementById( 'mytext' );

    $myinput->addEventListener( selectionchange => sub
    {
        $doc->getElementById( 'start' )->textContent = $mytext->selectionStart;
        $doc->getElementById( 'end' )->textContent = $mytext->selectionEnd;
        $doc->getElementById( 'direction' )->textContent = $mytext->selectionDirection;
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTextAreaElement/selectionchange_event>

=head2 EVENT HANDLERS

=head2 oninput

Property to handle event of type C<input>. Those events are not automatically fired, but you can trigger them yourself.

=head2 onselectionchange

Property to handle event of type C<selectionchange>. Those events are not automatically fired, but you can trigger them yourself.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTextAreaElement>, L<Mozilla documentation on textarea element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/textarea>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

