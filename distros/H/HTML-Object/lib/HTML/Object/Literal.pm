##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Literal.pm
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
package HTML::Object::Literal;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Scalar );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub as_number { return( shift->to_number( @_ ) ); }

sub as_string
{
    my $self = shift( @_ );
    my $txt  = $self->SUPER::as_string;
	# $txt =~ s/'/&apos;/g;
	$txt =~ s/(?<!\\)\'/\\\'/g;
	return( "'$txt'" );
}

sub as_xml
{
    my $self = shift( @_ );
    my $txt  = $self->SUPER::as_string;
    return( "<Literal>$txt</Literal>\n" );
}

sub evaluate { return( shift( @_ ) ); }

sub getAttributes { return( shift->error( 'Cannot get attributes of a literal' ) );  }

sub getChildNodes { return( shift->error( 'Cannot get child nodes of a literal' ) ); }

sub getParentNode { return( shift->error( 'Cannot get parent node of a literal' ) ); }

sub string_value { return( shift->value ); }

# sub to_boolean { return( shift->as_boolean ); }
sub to_boolean
{
    require HTML::Object::Boolean;
    return( shift->as_string ? HTML::Object::Boolean->True : HTML::Object::Boolean->False );
}

sub to_literal { return( shift( @_ ) ); }

# sub to_number { return( shift->as_number ); }
sub to_number
{
    require HTML::Object::Number;
    return( HTML::Object::Number->new( shift->value ) );
}

sub value { return( shift->SUPER::as_string ); }

sub value_as_number { return( shift->as_number ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::Literal - Simple string values

=head1 SYNOPSIS

    use HTML::Object::Literal;
    my $this = HTML::Object::Literal->new || die( HTML::Object::Literal->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

In XPath terms a Literal is what we know as a string.

This module inherits from L<Module::Generic::Scalar>

=head1 METHODS

=head2 new

Provided with a C<string> and this will create a new Literal object with the value in C<string>. Note that &quot; and &apos; will be converted to " and ' respectively. That is not part of the XPath specification, but I consider it useful. Note though that you have to go to extraordinary lengths in an XML template file (be it XSLT or whatever) to make use of this:

	<xsl:value-of select="&quot;I am feeling &amp;quot;sad&amp;quot;&quot;"/>

Which produces a Literal of:

	I am feeling "sad"

=head2 as_string

Returns a string representation of this literal.

=head2 as_xml

Returns a string representation as xml.

=head2 evaluate

Does nothing. Returns the current object.

=head2 getAttributes

If called, this would return an L<error|Module::Generic/error>

=head2 getChildNodes

If called, this would return an L<error|Module::Generic/error>

=head2 getParentNode

If called, this would return an L<error|Module::Generic/error>

=head2 string_value

Returns the current value as-is.

=head2 to_boolean

Returns the current value as a L<boolean|Module::Generic::Boolean>

=head2 to_literal

Returns the current object.

=head2 to_number

Returns the current value as a L<number|Module::Generic::Number>

=head2 value

Also overloaded as stringification, simply returns the literal string value.

=head2 value_as_number

Returns the current value as a L<number|Module::Generic::Number>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object>, L<HTML::Object::Attribute>, L<HTML::Object::Boolean>, L<HTML::Object::Closing>, L<HTML::Object::Collection>, L<HTML::Object::Comment>, L<HTML::Object::Declaration>, L<HTML::Object::Document>, L<HTML::Object::Element>, L<HTML::Object::Exception>, L<HTML::Object::Literal>, L<HTML::Object::Number>, L<HTML::Object::Root>, L<HTML::Object::Space>, L<HTML::Object::Text>, L<HTML::Object::XQuery>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
