##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/ElementDataMap.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/12
## Modified 2021/12/12
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::ElementDataMap;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    my $elem = shift( @_ ) || return( $self->error( "No HTML::Object::Element was provided." ) );
    return( $self->error( "Element object provided is not a HTML::Object::Element" ) ) if( !$self->_is_a( $elem => 'HTML::Object::Element' ) );
    $self->{element} = $elem;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

AUTOLOAD
{
    my( $name ) = our $AUTOLOAD =~ /([^:]+)$/;
    my $self = shift( @_ );
    my $elem = $self->{element} || die( "No element object set!\n" );
    ( my $copy = $name ) =~ s/^([A-Z])/\L$1\E/;
    my $att = 'data-' . join( '-', map( lc( $_ ), split( /(?=[A-Z])/, $copy ) ) );
    if( @_ )
    {
        my $val = shift( @_ );
        if( !$elem->attributes->has( $att ) )
        {
            $elem->setAttribute( $att => $val );
        }
        else
        {
            $elem->attributes->set( $att => $val );
        }
        $elem->reset(1);
        return( $self );
    }
    else
    {
        return( $elem->attributes->get( $att ) );
    }
};


1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::ElementDataMap - HTML Object Element Data Map Class

=head1 SYNOPSIS

    use HTML::Object::ElementDataMap;
    my $map = HTML::Object::ElementDataMap->new( $html_element_object ) || 
        die( HTML::Object::ElementDataMap->error, "\n" );
    $map->dateOfBirth( '1989-12-01' );
    # Related html element would now have an attribute data-date-of-birth set to 1989-12-01

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module implements a L<data map|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/dataset> for L<HTML element|HTML::Object::Element> objects.

It provides read/write access to custom data attributes (data-*) on L<elements|HTML::Object::Element>. It provides a map of strings with an entry for each data-* attribute.

Those class objects are instantiated from L<HTML::Object::Element/dataset>

=head1 Name conversion

=head2 dash-style to camelCase conversion

A custom data attribute name is transformed to a key for the element data entry by the following:

=over 4

=item 1. Lowercase all ASCII capital letters (A to Z);

=item 2. Remove the prefix data- (including the dash);

=item 3. For any dash (U+002D) followed by an ASCII lowercase letter a to z, remove the dash and uppercase the letter;

=item 4. Other characters (including other dashes) are left unchanged.

=back

=head2 camelCase to dash-style conversion

The opposite transformation, which maps a key to an attribute name, uses the following:

=over 4

=item 1. Restriction: Before transformation, a dash must not be immediately followed by an ASCII lowercase letter a to z;

=item 2. Add the data- prefix;

=item 3. Add a dash before any ASCII uppercase letter A to Z, then lowercase the letter;

=item 4. Other characters are left unchanged.

=back

For example, a data-abc-def attribute corresponds to dataset.abcDef. 

=head1 Accessing values

=over 4

=item * Attributes can be set and read by the camelCase name/key as an object property of the dataset: C<$element->dataset->keyname>

=item * Attributes can also be set and read using variable: C<$element->dataset->$keyname>

=item * You can check if a given attribute exists like so: C<$element->attributes->exists( 'data-keyname' )>

=back

=head1 Setting values

=over 4

=item * When the attribute is set, its value is always stored as is, which means you can set reference and access them later.

=item * To remove an attribute, you can use the L<HTML::Object::Element/removeAttribute> method: C<$element->removeAttribute( 'data-keyname' )>

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/dataset>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
