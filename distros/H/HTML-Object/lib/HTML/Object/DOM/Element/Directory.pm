##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Directory.pm
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
package HTML::Object::DOM::Element::Directory;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :dir );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'dir' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# property compact is inherited

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Directory - HTML Object DOM Directory Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Directory;
    my $dir = HTML::Object::DOM::Element::Directory->new || 
        die( HTML::Object::DOM::Element::Directory->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface provides special properties (beyond the L<HTML::Object::Element> object interface it also has available to it by inheritance) to manipulate C<directory> elements and their content.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +---------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Directory |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +---------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 compact

This boolean HTML attribute hints that the list should be rendered in a compact style. The interpretation of this attribute depends on the user agent and it does not work in all browsers.

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLDirectoryElement>, L<Mozilla documentation on directory element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dir>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
