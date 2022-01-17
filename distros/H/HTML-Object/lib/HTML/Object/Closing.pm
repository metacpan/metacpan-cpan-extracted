##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Closing.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/04/19
## Modified 2021/08/23
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::Closing;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( HTML::Object::Element );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{is_empty} = 1;
    $self->{tag} = '_closing';
    $self->{_init_strict_use_sub} = 1;
    $this->{_exception_class} = 'HTML::Object::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $tag  = $self->tag;
    return( $self->original->length ? $self->original : $self->new_scalar( "</${tag}>" ) );
}

sub as_xml { return( shift->as_string( @_ ) ); }

sub checksum { return( '' ); }

sub set_checksum {}

1;
# XXX POD
__END__

=encoding utf8

=head1 NAME

HTML::Object::Closing - HTML Object Closing Tag Class

=head1 SYNOPSIS

    use HTML::Object::Closing;
    my $close = HTML::Object::Closing->new(
        tag => 'div',
    );
    # My opening div tag object
    $elem->close_tag( $close );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module represents the end of a tag for tags that are not empty. Thos objects are in the dom by necessity, but are not used directly. They are always attached to the object of another L<HTML element|HTML::Object::Element>

This module inherits from L<HTML::Object::Element>

=head1 INHERITANCE

    +-----------------------+     +-----------------------+
    | HTML::Object::Element | --> | HTML::Object::Closing |
    +-----------------------+     +-----------------------+

=head1 CONSTRUCTOR

=head2 new

Creates and returns a new tag closing object.

Creates a new C<HTML::Object::Closing> objects.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

On top of the methods inherited from L<HTML::Object::Element>, this module implements also the following methods:

=head2 as_string

Returns a string version of this closing tag. Unless it was modified, it will return the version exactly the same as when it was parsed from some HTML data, if any.

=head2 as_xml

This is an alias for L</as_string>

=head2 checksum

Returns an empty string.

=head2 set_checksum

Does absolutely nothing and is here to prevent the inherited method from being triggered.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object>, L<HTML::Object::Attribute>, L<HTML::Object::Boolean>, L<HTML::Object::Closing>, L<HTML::Object::Collection>, L<HTML::Object::Comment>, L<HTML::Object::Declaration>, L<HTML::Object::Document>, L<HTML::Object::Element>, L<HTML::Object::Exception>, L<HTML::Object::Literal>, L<HTML::Object::Number>, L<HTML::Object::Root>, L<HTML::Object::Space>, L<HTML::Object::Text>, L<HTML::Object::XQuery>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


