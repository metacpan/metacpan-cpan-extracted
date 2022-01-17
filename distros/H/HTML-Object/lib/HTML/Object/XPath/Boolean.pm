##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/XPath/Boolean.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/05
## Modified 2021/12/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::XPath::Boolean;
BEGIN
{
    use strict;
    use warnings;
    use overload (
        '""'  => \&value,
        '<=>' => \&cmp
    );
    our $DEBUG = 0;
    our $VERSION = 'v0.1.0';
};

sub cmp
{
    my $self = shift( @_ );
    my( $other, $swap ) = @_;
    if( $swap )
    {
        return( $other <=> $$self );
    }
    return( $$self <=> $other );
}

sub False
{
    my $this = shift( @_ );
    my $val  = 0;
    return( bless( \$val => ( ref( $this ) || $this ) ) );
}

sub getAttributes { return( wantarray() ? () : [] ); }

sub getChildNodes { return( wantarray() ? () : [] ); }

sub string_value { return( $_[0]->to_literal->value ); }

sub to_boolean { return( $_[0] ); }

sub to_literal
{
    require HTML::Object::XPath::Literal;
    return( HTML::Object::XPath::Literal->new( $_[0]->value ? 'true' : 'false' ) );
}

sub to_number
{
    require HTML::Object::XPath::Number;
    return( HTML::Object::XPath::Number->new( $_[0]->value ) );
}

sub True
{
    my $this = shift( @_ );
    my $val  = 1;
    return( bless( \$val => ( ref( $this ) || $this ) ) );
}

sub value
{
    my $self = shift( @_ );
    return( $$self );
}

1;

__END__

=encoding utf-8

=head1 NAME

HTML::Object::XPath::Boolean - HTML Object

=head1 SYNOPSIS

    use HTML::Object::XPath::Boolean;
    my $this = HTML::Object::XPath::Boolean->new || die( HTML::Object::XPath::Boolean->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module implements simple boolean true/false objects.

=head1 METHODS

=head2 cmp

This method is called for overloading the comparison operator.

It takes another element and it returns true if the two elements are same or false otherwise.

=head2 getAttributes

Returns an empty list in list context and an empty array reference in scalar context.

=head2 getChildNodes

Returns an empty list in list context and an empty array reference in scalar context.

=head2 string_value

Returns the current value as a L<literal|HTML::Object::XPath::Literal>

=head2 to_boolean

Returns the current object.

=head2 to_literal

Returns C<true> if true, or C<false> otherwise, as a L<literal object|HTML::Object::XPath::Literal>

=head2 to_number

Returns the current value as a L<number object|HTML::Object::XPath::Number>

=head2 True

Creates a new Boolean object with a true value.

    HTML::Object::XPath::Boolean->True;

=head2 False

Creates a new Boolean object with a false value.

    HTML::Object::XPath::Boolean->False;

=head2 value

Returns true or false.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::XPath>, L<HTML::Object::XPath::Boolean>, L<HTML::Object::XPath::Expr>, L<HTML::Object::XPath::Function>, L<HTML::Object::XPath::Literal>, L<HTML::Object::XPath::LocationPath>, L<HTML::Object::XPath::NodeSet>, L<HTML::Object::XPath::Number>, L<HTML::Object::XPath::Root>, L<HTML::Object::XPath::Step>, L<HTML::Object::XPath::Variable>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
