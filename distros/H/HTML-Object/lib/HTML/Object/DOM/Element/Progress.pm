##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Progress.pm
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
package HTML::Object::DOM::Element::Progress;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :progress );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{max} = '1.0';
    $self->{value} = 0;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'progress' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property labels read-only inherited

# Note: property max
sub max : lvalue { return( shift->_set_get_property( 'max', @_ ) ); }

# Note: property position read-only
sub position
{
    my $self = shift( @_ );
    my $val = $self->value;
    my $max = $self->max;
    return(-1) if( !defined( $max ) || !CORE::length( "$max" ) || int( $max ) == 0 );
    return( $self->new_number( int( $val ) / int( $max ) ) );
}

# Note: property value inherited

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Progress - HTML Object DOM Progress Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Progress;
    my $progress = HTML::Object::DOM::Element::Progress->new || 
        die( HTML::Object::DOM::Element::Progress->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface provides special properties and methods (beyond the regular L<HTML::Object::Element> interface it also has available to it by inheritance) for manipulating the layout and presentation of C<<progress>> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Progress |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 labels

Read-only.

Returns L<NodeList|HTML::Object::DOM::NodeList> containing the list of L<<label>|HTML::Object::DOM::Label> elements that are labels for this element.

Example:

    <label id="label1" for="test">Label 1</label>
    <progress id="test" value="70" max="100">70%</progress>
    <label id="label2" for="test">Label 2</label>

    use HTML::Object::DOM qw( window );
    window->addEventListener( DOMContentLoaded => sub
    {
        my $progress = $doc->getElementById( 'test' );
        for( my $i = 0; $i < $progress->labels->length; $i++ )
        {
            say( $progress->labels->[$i]->textContent ); # "Label 1" and "Label 2"
        }
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLProgressElement/labels>

=head2 max

Is a double value reflecting HTML attribute that describes the content attribute of the same name, limited to numbers greater than zero. Its default value is 1.0.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLProgressElement/max>

=head2 position

Read-only.

Returns a double value returning the result of dividing the current value (value) by the maximum value (max); if the progress bar is an indeterminate progress bar, it returns C<-1>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLProgressElement/position>

=head2 value

Is a double value reflecting the HTML attribute that describes the current value; if the progress bar is an indeterminate progress bar, it returns C<0>.

    my $progress = $doc->createElement( 'progress' );
    $progress->value = 2; # <progress value="2"></progress>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLProgressElement/value>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLProgressElement>, L<Mozilla documentation on progress element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/progress>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
