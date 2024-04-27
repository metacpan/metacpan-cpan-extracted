##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Collection.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/04/28
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::Collection;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

# Purpose of this class is to serve as a distinctive class for search result from find()
sub init
{
    my $self = shift( @_ );
    $self->{end} = '';
    $self->{tag} = '_collection';
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'HTML::Object::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    my $class = ref( $self );
    # To make collection exception also available as $HTML::Object::ERROR
    $self->{_error_handler} = sub
    {
        my $ex = shift( @_ );
        # ${"${class}\::ERROR"} = $ex;
        no warnings 'once';
        $HTML::Object::ERROR = $ex;
        warnings::warn( $ex ) if( warnings::enabled( 'HTML::Object' ) );
    };
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{all} = 0 if( !CORE::exists( $opts->{all} ) );
    $opts->{all} //= 0;
    # In conformity with jQuery, we return the stringified version of the first object in our set
    # unless the 'all' option is provided and true. This is a divergence
    if( $opts->{all} )
    {
        my $res = $self->new_array;
        $self->children->foreach(sub
        {
            my $child = shift( @_ );
            # This will instruct the HTML::Object::Element to automatically close
            my $str = $_->as_string( inside_collection => 1 );
            $res->push( $str );
        });
        return( $res->join( '' ) );
    }
    else
    {
        my $first = $self->children->first;
        # If there is no element object in our collection, we return an empty scalar object
        # to avoid a potential perl error of "called on undefined value"
        # The user can then easily check if anything was provided with:
        # $e->as_string->length
        return( $self->new_scalar ) if( !$first || !$self->_is_a( $first, 'HTML::Object::Element' ) );
        return( $first->as_string( inside_collection => 1 ) );
    }
}

sub end { return( shift->_set_get_object( 'end', 'HTML::Object::Element', @_ ) ); }

# Note: Property
sub nodeValue { return; }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::Collection - HTML Object XQuery Collection Class

=head1 SYNOPSIS

    use HTML::Object::Collection;
    my $col = HTML::Object::Collection->new || 
        die( HTML::Object::Collection->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This module serves as a collection of L<HTML elements|HTML::Object::Element> and is used by L<XQuery|HTML::Object::XQuery> when a query is made with a selector or other criteria to group several L<HTML objects|HTML::Object::Element> just like jQuery does.

It inherits from L<HTML::Object::Document> and does not do much except for a handful methods.

=head1 INHERITANCE

    +-----------------------+     +----------------------------+     +--------------------------+
    | HTML::Object::Element | --> | HTML::Object::DOM::Element | --> | HTML::Object::Collection |
    +-----------------------+     +----------------------------+     +--------------------------+

=head1 PROPERTIES

=head2 nodeValue

This returns or sets the value of the current node.

For document, element or collection, this returns C<undef> and for attribute, text or comment, this returns the objct value.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeValue>

=head1 METHODS

=head2 as_string

When called, this will return the string representation of the first L<HTML element object|HTML::Object::Element> it contains similar to the behaviour of jQuery. However, as an added feature, if this method is called with C<all> set to 1 or a positive value then, it will return the string representation for all the L<HTML element objects|HTML::Object::Element> it holds.

=head2 end

Set or get the end L<element|HTML::Object::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object>, L<HTML::Object::Attribute>, L<HTML::Object::Boolean>, L<HTML::Object::Closing>, L<HTML::Object::Collection>, L<HTML::Object::Comment>, L<HTML::Object::Declaration>, L<HTML::Object::Document>, L<HTML::Object::Element>, L<HTML::Object::Exception>, L<HTML::Object::Literal>, L<HTML::Object::Number>, L<HTML::Object::Root>, L<HTML::Object::Space>, L<HTML::Object::Text>, L<HTML::Object::XQuery>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
