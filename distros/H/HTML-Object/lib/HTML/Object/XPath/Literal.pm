##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/XPath/Literal.pm
## Version v0.2.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/05
## Modified 2022/11/11
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::XPath::Literal;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $TRUE $FALSE $BASE_CLASS $DEBUG $VERSION );
    use HTML::Object::XPath::Boolean;
    our $TRUE  = HTML::Object::XPath::Boolean->True;
    our $FALSE = HTML::Object::XPath::Boolean->False;
    our $BASE_CLASS = 'HTML::Object::XPath';
    our $DEBUG = 0;
    use overload (
        '""'  => \&value,
        'cmp' => \&cmp
    );
    our $VERSION = 'v0.2.1';
};

use strict;
use warnings;

sub new
{
    my $this = shift( @_ );
    my $str  = shift( @_ );
    return( bless( \$str => ( ref( $this ) || $this ) ) );
}

sub as_string
{
    my $self = shift( @_ );
    my $string = $$self;
    $string =~ s/'/&apos;/g;
    return( "'$string'" );
}

sub as_xml
{
    my $self = shift( @_ );
    my $string = $$self;
    return( "<Literal>$string</Literal>\n" );
}

sub cmp
{
    my $self = shift( @_ );
    my( $cmp, $swap ) = @_;
    return( $swap ? $cmp cmp $$self : $$self cmp $cmp );
}

sub evaluate
{
    my $self = shift( @_ );
    return( $self );
}

sub getChildNodes { die( "cannot get child nodes of a literal" ); }

sub getAttributes { die( "cannot get attributes of a literal" );  }

sub getParentNode { die( "cannot get parent node of a literal" ); }

sub new_number { return( shift->_class_for( 'Number' )->new( @_ ) ); }

sub string_value { return( $_[0]->value ); }

sub to_boolean
{
    my $self = shift( @_ );
    return( ( length( $$self ) > 0 ) ? $TRUE : $FALSE );
}

sub to_literal { return( $_[0] ); }

sub to_number { return( $_[0]->new_number( $_[0]->value ) ); }

sub value
{
    my $self = shift( @_ );
    return( $$self );
}

sub value_as_number
{
    my $self = shift( @_ );
    warnings::warn( "numifying '" . $$self . "' to '" . +$$self . "'\n" ) if( warnings::enabled( $BASE_CLASS ) );
    return( +$$self );
}

sub _class_for
{
    my( $self, $mod ) = @_;
    eval( "require ${BASE_CLASS}\::${mod};" );
    die( $@ ) if( $@ );
    # ${"${BASE_CLASS}\::${mod}\::DEBUG"} = $DEBUG;
    eval( "\$${BASE_CLASS}\::${mod}\::DEBUG = " . ( $DEBUG // 0 ) );
    return( "${BASE_CLASS}::${mod}" );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::XPath::Literal - HTML Object XPath Literal

=head1 SYNOPSIS

    use HTML::Object::XPath::Literal;
    my $this = HTML::Object::XPath::Literal->new || 
        die( HTML::Object::XPath::Literal->error, "\n" );

=head1 VERSION

    v0.2.1

=head1 DESCRIPTION

This module implements the equivalent of a string in XPath parlance.

=head1 METHODS

=head2 new

Provided with a C<string> and this creates a new L<HTML::Object::XPath::Literal> object with the value providedd. Note that &quot; and
&apos; will be converted to " and ' respectively. That is not part of the XPath specification, but I consider it useful. Note though that you have to go to extraordinary lengths in an XML template file (be it XSLT or whatever) to
make use of this:

    <input type="text" value="&quot;I am feeling &amp;quot;perplex&amp;quot;&quot;" />

Which produces a Literal of:

    I am feeling "perplex"

=head2 as_string

Returns a string representation of the literal.

=head2 as_xml

Returns a string representation of the literal as xml.

=head2 cmp

This is a method used for overload. Provided with another object or string and this will return the same value as L<perlop/cmp>, that is it "returns -1, 0, or 1 depending on whether the left argument is stringwise less than, equal to, or greater than the right argument".

=head2 evaluate

It returns the current object.

=head2 getChildNodes

This raises an exception, as it cannot be used.

=head2 getAttributes

This raises an exception, as it cannot be used.

=head2 getParentNode

This raises an exception, as it cannot be used.

=head2 new_number

Returns a new L<number object|HTML::Object::XPath::Number> based on the value provided.

=head2 string_value

Returns the value of the literal as returned by L</value>

=head2 to_boolean

Returns L<true|HTML::Object::XPath::Boolean> if the literal value is true, or L<false|HTML::Object::XPath::Boolean> otherwise.

=head2 to_literal

Returns the current object.

=head2 to_number

Returns a new L<number object|HTML::Object::XPath::Number> from the value of the literal.

=head2 value

This returns the literal string value. It is also called upon stringification.

=head2 value_as_number

Returns the literal value as a number (not a number object), but forcing perl to treat it as a number, i.e. prepending it with a plus sign.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::XPath>, L<HTML::Object::XPath::Boolean>, L<HTML::Object::XPath::Expr>, L<HTML::Object::XPath::Function>, L<HTML::Object::XPath::Literal>, L<HTML::Object::XPath::LocationPath>, L<HTML::Object::XPath::NodeSet>, L<HTML::Object::XPath::Number>, L<HTML::Object::XPath::Root>, L<HTML::Object::XPath::Step>, L<HTML::Object::XPath::Variable>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
