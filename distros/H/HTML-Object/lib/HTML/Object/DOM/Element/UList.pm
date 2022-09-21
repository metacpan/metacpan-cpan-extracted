##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/UList.pm
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
package HTML::Object::DOM::Element::UList;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :ulist );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'ul' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property compact is inherited

# Note: property type is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::UList - HTML Object DOM UList Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::UList;
    my $ul = HTML::Object::DOM::Element::UList->new ||
        die( HTML::Object::DOM::Element::UList->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides special properties (beyond those defined on the regular L<HTML::Object::DOM::Element> interface it also has available to it by inheritance) for manipulating unordered list elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::UList |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 compact

Is a boolean value indicating that spacing between list items should be reduced. This property reflects the compact HTML attribute only, it does not consider the line-height CSS property used for that behavior in modern pages.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLUListElement/compact>

=head2 type

Is a string value reflecting the HTML attribute representing the type and defining the kind of marker to be used to display. The values are browser dependent and have never been standardized.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLUListElement/type>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLUListElement>, L<Mozilla documentation on ulist element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ul>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
