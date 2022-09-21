##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Boolean.pm
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
package HTML::Object::Boolean;
BEGIN
{
    use strict;
    use warnings;
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

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This module implements simple boolean true/false objects.

It inherits from L<Module::Generic::Boolean>

=head1 METHODS

=head2 getChildNodes

Returns and empty L<array object|Module::Generic::Array>

=head2 getAttributes

Returns and empty L<array object|Module::Generic::Array>

=head2 False

Creates a new Boolean object with a false value.

=head2 string_value

Returns C<true> if true, or C<false> if false

=head2 to_boolean

Returns the current boolean object it was called on.

=head2 to_literal

Returns the string "true" or "false".

=head2 to_number

Returns a new L<HTML::Object::Number> object based on the current boolean value.

=head2 True

Creates a new Boolean object with a true value.

=head2 value

Returns true or false.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object>, L<HTML::Object::Attribute>, L<HTML::Object::Boolean>, L<HTML::Object::Closing>, L<HTML::Object::Collection>, L<HTML::Object::Comment>, L<HTML::Object::Declaration>, L<HTML::Object::Document>, L<HTML::Object::Element>, L<HTML::Object::Exception>, L<HTML::Object::Literal>, L<HTML::Object::Number>, L<HTML::Object::Root>, L<HTML::Object::Space>, L<HTML::Object::Text>, L<HTML::Object::XQuery>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
