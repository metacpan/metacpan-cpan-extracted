##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Boolean.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/04/22
## Modified 2022/09/18
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::Boolean;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'HTML::Object' );
    use parent qw( Module::Generic::Boolean );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub getChildNodes { return( shift->new_array ); }

sub getAttributes { return( shift->new_array ); }

sub False { return( shift->false ); }

sub string_value { return( shift->to_literal->value ); }

sub to_boolean { return( $_[0] ); }

sub to_literal
{
    require HTML::Object::Literal;
    return( HTML::Object::Literal->new( shift->value ? 'true' : 'false' ) );
}

sub to_number
{
    require HTML::Object::Number;
    return( HTML::Object::Number->new( shift->value ) );
}

sub True { return( shift->true ); }

sub value { return( ${$_[0]} ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

HTML::Object::Boolean - HTML Object Boolean Class

=head1 SYNOPSIS

    use HTML::Object::Boolean;

    my $true  = HTML::Object::Boolean->True;
    my $false = HTML::Object::Boolean->False;

    print $true->value;           # 1
    print $false->string_value;   # false
    print $true->to_literal;      # true

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This module implements simple boolean true/false value objects for use within the L<HTML::Object> framework, notably by the XPath and XQuery subsystems.

It inherits from L<Module::Generic::Boolean> and adds DOM- and XPath-oriented coercion methods so that boolean values can be converted to literals, numbers, or string representations in a uniform way.

The object itself is a blessed scalar reference. L</value> dereferences it and returns the raw Perl value: C<1> for true, C<0> for false.

=head1 METHODS

head2 False

    my $false = HTML::Object::Boolean->False;
    # or
    my $false = $bool->False;

Returns a new C<HTML::Object::Boolean> object whose value is false (C<0>).

This method can be called on the class or on an existing instance; in both cases it always returns a new object.

See also L<Module::Generic::Boolean/false>.

=head2 True

    my $true = HTML::Object::Boolean->True;
    # or
    my $true = $bool->True;

Returns a new C<HTML::Object::Boolean> object whose value is true (C<1>).

This method can be called on the class or on an existing instance; in both cases it always returns a new object.

See also L<Module::Generic::Boolean/true>.

=head2 getAttributes

    my $attrs = $bool->getAttributes;

Returns an empty L<array object|Module::Generic::Array>.
Boolean values carry no attributes in the DOM model.

=head2 getChildNodes

    my $children = $bool->getChildNodes;

Returns an empty L<array object|Module::Generic::Array>.
Boolean values are leaf nodes and have no children in the DOM model.

=head2 False

Creates a new Boolean object with a false value.

=head2 string_value

    my $str = $bool->string_value;  # 'true' or 'false'

Returns the string representation of the boolean value: C<true> if the value is true, C<false> otherwise. This is a plain Perl string, not an object.

Internally this delegates to L</to_literal> and then calls C<value> on the resulting L<HTML::Object::Literal> object.

=head2 to_boolean

    my $same = $bool->to_boolean;

Returns the current object unchanged. This method exists for interface uniformity with other XPath value types (L<HTML::Object::Literal>, L<HTML::Object::Number>) which must each implement C<to_boolean>.

=head2 to_literal

    my $literal = $bool->to_literal;

Returns a new L<HTML::Object::Literal> object whose string value is C<true> if the boolean is true, or C<false> otherwise.

=head2 to_number

    my $num = $bool->to_number;

Returns a new L<HTML::Object::Number> object constructed from the raw boolean value: C<1> for true, C<0> for false.

=head2 value

    my $val = $bool->value;  # 1 or 0

Returns the raw Perl scalar stored inside the object: C<1> for true, C<0> for false. The object is internally a blessed scalar reference, and this method dereferences it.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object>, L<HTML::Object::Attribute>, L<HTML::Object::Boolean>, L<HTML::Object::Closing>, L<HTML::Object::Collection>, L<HTML::Object::Comment>, L<HTML::Object::Declaration>, L<HTML::Object::Document>, L<HTML::Object::Element>, L<HTML::Object::Exception>, L<HTML::Object::Literal>, L<HTML::Object::Number>, L<HTML::Object::Root>, L<HTML::Object::Space>, L<HTML::Object::Text>, L<HTML::Object::XQuery>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
