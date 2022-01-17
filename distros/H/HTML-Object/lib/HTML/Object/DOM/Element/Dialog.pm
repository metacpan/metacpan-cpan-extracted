##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Dialog.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/23
## Modified 2021/12/23
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Dialog;
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
    $self->{tag} = 'dialog' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

sub close
{
    my $self = shift( @_ );
    return( $self );
}

# Note: property
sub open : lvalue { return( shift->_set_get_property( { attribute => 'open', is_boolean => 1 }, @_ ) ); }

# Note: property
sub returnValue : lvalue { return( shift->_set_get_property( 'returnvalue', @_ ) ); }

sub show { return; }

sub showModal { return; }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Dialog - HTML Object DOM Dialog Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Dialog;
    my $dialog = HTML::Object::DOM::Element::Dialog->new || 
        die( HTML::Object::DOM::Element::Dialog->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Experimental: This is an experimental technologyCheck the Browser compatibility table carefully before using this in production.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Dialog |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 open

A boolean value reflecting the open HTML attribute, indicating whether the dialog is available for interaction.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement/open>

=head2 returnValue

A string that sets or returns the return value for the dialog.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement/returnValue>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

None of those methods do anything, since it would require interactivity. So, they all return C<undef>.

=head2 close

Returns C<undef> since this feature is unavailable under perl.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement/close>

=head2 show

Returns C<undef> since this feature is unavailable under perl.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement/show>

=head2 showModal

Returns C<undef> since this feature is unavailable under perl.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement/showModal>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement>, L<Mozilla documentation on dialog element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dialog>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
