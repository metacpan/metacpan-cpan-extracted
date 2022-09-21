##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/XPath/Number.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/05
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::XPath::Number;
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
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub new
{
    my $this = shift( @_ );
    my $number = shift( @_ );
    if( $number !~ /^[[:blank:]\h]*[+-]?(\d+(\.\d*)?|\.\d+)[[:blank:]\h]*$/ )
    {
        $number = undef;
    }
    else
    {
        $number =~ s/^[[:blank:]\h]*(.*)[[:blank:]\h]*$/$1/;
    }
    return( bless( \$number => ( ref( $this ) || $this ) ) );
}

sub as_string
{
    my $self = shift( @_ );
    return( defined( $$self ) ? $$self : 'NaN' );
}

sub as_xml
{
    my $self = shift( @_ );
    return( "<Number>" . ( defined( $$self ) ? $$self : 'NaN' ) . "</Number>\n" );
}

sub cmp
{
    my $self = shift( @_ );
    my( $other, $swap ) = @_;
    return( $swap ? $other <=> $$self : $$self <=> $other );
}

sub evaluate { return( $_[0] ); }

sub getAttributes { return( wantarray() ? () : [] ); }

sub getChildNodes { return( wantarray() ? () : [] ); }

sub new_literal { return( shift->_class_for( 'Literal' )->new( @_ ) ); }

sub string_value { return $_[0]->value }

sub to_boolean { return( ${$_[0]} ? $TRUE : $FALSE ); }

sub to_literal { $_[0]->new_literal( $_[0]->as_string ); }

sub to_number { $_[0]; }

sub value { return( ${$_[0]} ); }

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

HTML::Object::XPath::Number - HTML Object XPath Number Class

=head1 SYNOPSIS

    use HTML::Object::XPath::Number;
    my $num = HTML::Object::XPath::Number->new || 
        die( HTML::Object::XPath::Number->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This module holds simple numeric values. It doesn't support -0, +/- Infinity, or NaN, as the XPath spec says it should.

=head1 METHODS

=head2 new

Provided with a C<number> and this creates a new L<HTML::Object::XPath::Number> object, with the value in C<number>. Does some
rudimentary numeric checking on C<number> to ensure it actually is a number.

=head2 as_string

Returns a string representation of the number, or C<NaN> is undefined.

=head2 as_xml

Same as L</as_string>, but in xml format.

=head2 cmp

Returns the equivalent of perl's own L<perlop/cmp> operation.

=head2 evaluate

Returns the current object.

=head2 getAttributes

Returns an empty array reference in scalar context and an empty list in list context.

=head2 getChildNodes

Returns an empty array reference in scalar context and an empty list in list context.

=head2 new_literal

Returns a new L<HTML::Object::XPath::Literal> object, passing it whatever arguments was provided.

=head2 string_value

Returns the value of the current object by calling L</value>

=head2 to_boolean

Returns true if the current object has a L<true|HTML::Object::XPath::Boolean> value, or L<false|HTML::Object::XPath::Boolean> otherwise.

=head2 to_literal

Returns a new L<HTML::Object::XPath::Litteral> object of the stringification of the current object.

=head2 to_number

Returns the current object.

=head2 value

This returns the numeric value held. This is also the method used to return the value from strinfgification.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::XPath>, L<HTML::Object::XPath::Boolean>, L<HTML::Object::XPath::Expr>, L<HTML::Object::XPath::Function>, L<HTML::Object::XPath::Literal>, L<HTML::Object::XPath::LocationPath>, L<HTML::Object::XPath::NodeSet>, L<HTML::Object::XPath::Number>, L<HTML::Object::XPath::Root>, L<HTML::Object::XPath::Step>, L<HTML::Object::XPath::Variable>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
