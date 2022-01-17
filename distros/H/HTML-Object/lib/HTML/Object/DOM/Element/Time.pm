##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Time.pm
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
package HTML::Object::DOM::Element::Time;
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
    $self->{tag} = 'time' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property dateTime
sub dateTime : lvalue { return( shift->_set_get_property( 'datetime', @_ ) ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Time - HTML Object DOM Time Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Time;
    my $time = HTML::Object::DOM::Element::Time->new || 
        die( HTML::Object::DOM::Element::Time->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface provides special properties (beyond the regular L<HTML::Object::DOM::Element> interface it also has available to it by inheritance) for manipulating <time> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Time |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 dateTime

Is a string that reflects the datetime HTML attribute, containing a machine-readable form of the element's date and time value.

Example:

    # Assumes there is <time id="t"> element in the HTML

    my $t = $doc->getElementById( 't' );
    $t->dateTime = "6w 5h 34m 5s";

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTimeElement/dateTime>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTimeElement>, L<Mozilla documentation on time element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/time>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

