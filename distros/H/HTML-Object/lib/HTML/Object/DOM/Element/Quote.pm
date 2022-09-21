##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Quote.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/28
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Quote;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# Note: property cite
sub cite : lvalue { return( shift->_set_get_property({ attribute => 'cite', is_uri => 1 }, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Quote - HTML Object DOM Blockquote Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Quote;
    my $quote = HTML::Object::DOM::Element::Quote->new || 
        die( HTML::Object::DOM::Element::Quote->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides special properties and methods (beyond the regular L<HTML::Object::Element> interface it also has available to it by inheritance) for manipulating quoting elements, like C<<blockquote>> and C<<q>>, but not the C<<cite>> element.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Quote |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 cite

Is a string reflecting the cite HTML attribute, containing a URL for the source of the quotation. You can set or get an L<URI> with this method.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLQuoteElement/cite>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLQuoteElement>, L<Mozilla documentation on blockquote element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/blockquote>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
