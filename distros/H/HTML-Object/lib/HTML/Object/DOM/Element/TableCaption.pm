##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/TableCaption.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/06
## Modified 2022/01/06
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::TableCaption;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :tablecaption );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'caption' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: deprecated property align is inherited

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::TableCaption - HTML Object DOM TableCaption Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::TableCaption;
    my $caption = HTML::Object::DOM::Element::TableCaption->new ||
        die( HTML::Object::DOM::Element::TableCaption->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface special properties (beyond the regular L<HTML::Object::DOM::Element> interface it also has available to it by inheritance) for manipulating table C<caption> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::TableCaption |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 EXAMPLE

    <table>
        <caption>Example Caption</caption>
        <tr>
            <th>Login</th>
            <th>Email</th>
        </tr>
        <tr>
            <td>user1</td>
            <td>user1@sample.com</td>
        </tr>
        <tr>
            <td>user2</td>
            <td>user2@sample.com</td>
        </tr>
    </table>

=head1 DEPRECATED PROPERTIES

=head2 align

Is a string which represents an enumerated attribute indicating alignment of the caption with respect to the table. It may have one of the following values:

=over 4

=item left

The caption is displayed to the left of the table.

=item top

The caption is displayed above the table.

=item right

The caption is displayed to the right of the table.

=item bottom

The caption is displayed below the table.

=back

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCaptionElement/align>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCaptionElement>, L<Mozilla documentation on tablecaption element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/tablecaption>, L<Specifications|https://html.spec.whatwg.org/multipage/tables.html#htmltablecaptionelement>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
