##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Mod.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/10
## Modified 2022/01/10
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Mod;
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
    $self->{tag} = 'mod' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property cite
sub cite : lvalue { return( shift->_set_get_property( 'cite', @_ ) ); }

# Note: property dateTime
sub dateTime : lvalue { return( shift->_set_get_property({ attribute => 'datetime', is_datetime => 1 }, @_ ) ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Mod - HTML Object DOM Mod Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Mod;
    my $mod = HTML::Object::DOM::Element::Mod->new || 
        die( HTML::Object::DOM::Element::Mod->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface provides special properties (beyond the regular methods and properties available through the L<HTML::Object::DOM::Element> interface they also have available to them by inheritance) for manipulating modification elements, that is <del> and <ins>.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +---------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Mod |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +---------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 cite

Is a string reflecting the cite HTML attribute, containing a URI of a resource explaining the change.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLModElement/cite>

=head2 dateTime

Is a string reflecting the datetime HTML attribute, containing a date-and-time string representing a timestamp for the change.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLModElement/dateTime>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLModElement>, L<Mozilla documentation on mod element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/mod>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

