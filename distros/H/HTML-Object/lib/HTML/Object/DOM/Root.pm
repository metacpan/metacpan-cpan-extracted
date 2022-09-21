##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Root.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/13
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Root;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::Root HTML::Object::DOM::Node );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->HTML::Object::Root::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub cmp
{
    my( $self, $this ) = @_;
    return( $self->_is_a( $this => 'HTML::Object::Root' ) ? 0 : 1 );
}

sub getAttributes { return( wantarray() ? () : [] ); }

sub getChildNodes { return( shift->root ); }

sub getName { return; }

sub getNextSibling { return; }

sub getParentNode { return; }

sub getPreviousSibling { return; }

sub getRootNode { return( shift( @_ ) ); }

sub is_inside { return( 0 ); }

sub isDocumentNode { return( 1 ); }

sub root { return( shift->_set_get_object( 'root', 'HTML::Object::DOM::Node', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Root - HTML Object

=head1 SYNOPSIS

    use HTML::Object::DOM::Root;
    my $this = HTML::Object::DOM::Root->new || die( HTML::Object::DOM::Root->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This module implements a Root in DOM. It inherits from L<HTML::Object::Root> and L<HTML::Object::DOM::Node>

=head1 INHERITANCE

    +---------------------------+     +-------------------------+     +--------------------+     +-------------------------+
    |   HTML::Object::Element   | --> | HTML::Object::Document  | --> | HTML::Object::Root | --> | HTML::Object::DOM::Root |
    +---------------------------+     +-------------------------+     +--------------------+     +-------------------------+
      |                                                                                            ^
      |                                                                                            |
      v                                                                                            |
    +---------------------------+     +-------------------------+                                  |
    | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | ---------------------------------+
    +---------------------------+     +-------------------------+

=head1 METHODS

=head2 cmp

Provided with another object and this returns true if the other object is a L<HTML::Object::Root> object or false otherwise.

=head2 getAttributes

Returns an empty list in list context, or an empty array reference in scalar context.

=head2 getChildNodes

Returns the L</root> element.

=head2 getName

Returns an empty list in list context, or C<undef> in scalar context.

=head2 getNextSibling

Returns an empty list in list context, or C<undef> in scalar context.

=head2 getParentNode

Returns an empty list in list context, or C<undef> in scalar context.

=head2 getPreviousSibling

Returns an empty list in list context, or C<undef> in scalar context.

=head2 getRootNode

Returns itself.

=head2 is_inside

Returns false.

=head2 isDocumentNode

Returns true.

=head2 root

Sets or gets a L<root node|HTML::Object::DOM::Node>, which should be a L<HTML::Object::DOM::Element::HTML> object.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::DOM::Element::HTML>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
