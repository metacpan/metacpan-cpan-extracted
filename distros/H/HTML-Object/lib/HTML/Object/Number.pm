##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Number.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/04/22
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::Number;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Number );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub as_xml
{
    my $self = shift( @_ );
    my $n = $self->as_string;
    return( "<Number>" . ( defined( $n ) ? $n : 'NaN' ) . "</Number>\n" );
}

sub evaluate { return( $_[0] ); }

# Return an empty hash
sub getAttributes { return( shift->new_hash ); }

# Return an empty array
sub getChildNodes { return( shift->new_array ); }

sub isEqualNode
{
    my $self = shift( @_ );
    my $e = shift( @_ ) || return( $self->error( "No html element was provided to insert." ) );
    return( $self->error( "Element provided (", overload::StrVal( $e ), ") is not an HTML::Object::Element." ) ) if( !$self->_is_a( $e => 'HTML::Object::Element' ) );
    return(0) if( !$self->_is_a( $e => 'HTML::Object::Number' ) );
    return( $self->value eq $e->value );
}

sub string_value { return( $_[0]->value ); }

sub to_boolean
{
    require HTML::Object::Boolean;
    return( shift->as_string ? HTML::Object::Boolean->True : HTML::Object::Boolean->False );
}

sub to_number { return( $_[0] ); }

sub to_literal
{
    require HTML::Object::Literal;
    return( HTML::Object::Literal->new( shift->as_string ) );
}

sub value { return( shift->as_string ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::Number - Simple numeric values

=head1 SYNOPSIS

    use HTML::Object::Number;
    my $this = HTML::Object::Number->new || 
        die( HTML::Object::Number->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This class holds simple numeric values. It does not support -0, +/- Infinity, or NaN, as the XPath spec says it should, but I am not hurting anyone I do not think.

=head1 METHODS

=head2 new

Provided with a C<number> and this creates a new L<HTML::Object::Number> object. Does some rudimentary numeric checking on the C<number> to ensure it actually is a number.

=head2 as_xml

Returns a string representation of the current value as xml.

=head2 evaluate

Returns the current object.

=head2 getAttributes

Returns an empty L<hash object|Module::Generic::Hash>

=head2 getChildNodes

Returns an empty L<array object|Module::Generic::Array>

=head2 isEqualNode

Returns a boolean value which indicates whether or not two elements are of the same type and all their defining data points match.

Two elements are equal when they have the same type, defining characteristics (this would be their ID, number of children, and so forth), its attributes match, and so on. The specific set of data points that must match varies depending on the types of the elements. 

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/isEqualNode>

=head2 string_value

Returns the current value.

=head2 to_boolean

Returns the current value as a L<boolean|HTML::Object::Boolean> object.

=head2 to_literal

Returns the current value as a L<literal object|HTML::Object::Literal>.

=head2 to_number

Returns the current object.

=head2 value

Also as overloaded stringification. Returns the numeric value held.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object>, L<HTML::Object::Attribute>, L<HTML::Object::Boolean>, L<HTML::Object::Closing>, L<HTML::Object::Collection>, L<HTML::Object::Comment>, L<HTML::Object::Declaration>, L<HTML::Object::Document>, L<HTML::Object::Element>, L<HTML::Object::Exception>, L<HTML::Object::Literal>, L<HTML::Object::Number>, L<HTML::Object::Root>, L<HTML::Object::Space>, L<HTML::Object::Text>, L<HTML::Object::XQuery>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
