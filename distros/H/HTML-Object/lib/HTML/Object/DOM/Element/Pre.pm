##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Pre.pm
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
package HTML::Object::DOM::Element::Pre;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :pre );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'pre' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property width inherited

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Pre - HTML Object DOM Pre Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Pre;
    my $pre = HTML::Object::DOM::Element::Pre->new || 
        die( HTML::Object::DOM::Element::Pre->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface exposes specific properties and methods (beyond those of the L<HTML::Object::DOM::Element> interface it also has available to it by inheritance) for manipulating a block of preformatted text (<pre>).

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +---------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Pre |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +---------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 width

Is a long value reflecting the obsolete width attribute, containing a fixed-size length for the <pre> element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLPreElement/width>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLPreElement>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
