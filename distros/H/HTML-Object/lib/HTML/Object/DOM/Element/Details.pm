##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Details.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/23
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Details;
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
    $self->{tag} = 'details' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

sub open : lvalue { return( shift->_set_get_property( { attribute => 'open', is_boolean => 1 }, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Details - HTML Object DOM Details Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Details;
    my $details = HTML::Object::DOM::Element::Details->new || 
        die( HTML::Object::DOM::Element::Details->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides special properties (beyond the regular L<HTML::Object::Element> interface it also has available to it by inheritance) for manipulating <details> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Details |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 open

Is a boolean value reflecting the C<open> HTML attribute, indicating whether or not the element's contents (not counting the <summary>) is to be shown to the user.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLDetailsElement/open>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLDetailsElement>, L<Mozilla documentation on details element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/details>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
