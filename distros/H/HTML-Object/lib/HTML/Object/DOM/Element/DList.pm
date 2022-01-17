##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/DList.pm
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
package HTML::Object::DOM::Element::DList;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :dl );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'dl' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# property compact is inherited

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::DList - HTML Object DOM DL List Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::DList;
    my $list = HTML::Object::DOM::Element::DList->new || 
        die( HTML::Object::DOM::Element::DList->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface provides special properties (beyond those of the regular L<HTML::Object::Element> interface it also has available to it by inheritance) for manipulating definition list (<dl>) elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::DList |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 compact

Is a boolean value indicating that spacing between list items should be reduced.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLDListElement/compact>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLDListElement>, L<Mozilla documentation on dl element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dl>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
