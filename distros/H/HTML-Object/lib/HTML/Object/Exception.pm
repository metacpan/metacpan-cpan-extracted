##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Exception.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/11/27
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::Exception;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Exception );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub columnNumber { return( shift->_set_get_number( 'column', @_ ) ); }

sub colno { return( shift->columnNumber( @_ ) ); }

sub fileName { return( shift->file( @_ ) ); }

sub filename { return( shift->file( @_ ) ); }

sub lineNumber { return( shift->line( @_ ) ); }

sub lineno { return( shift->line( @_ ) ); }

sub name { return( ref( $_[0] ) || $_[0] ); }

sub stack { return( shift->trace ); }

sub toLocalString { return( shift->as_string ); }

sub toString { return( shift->as_string ); }

{
    package
        HTML::Object::HierarchyRequestError;
    BEGIN
    {
        use parent -norequire, qw( HTML::Object::Exception );
    };
    
    package HTML::Object::IndexSizeError;
    BEGIN
    {
        use parent -norequire, qw( HTML::Object::Exception );
    };
    
    package
        HTML::Object::InvalidCharacterError;
    BEGIN
    {
        use parent -norequire, qw( HTML::Object::Exception );
    };
    
    package
        HTML::Object::InvalidStateError;
    BEGIN
    {
        use parent -norequire, qw( HTML::Object::Exception );
    };
    
    package HTML::Object::MediaError;
    BEGIN
    {
        use parent -norequire, qw( HTML::Object::Exception );
    };
    
    package HTML::Object::NotFoundError;
    BEGIN
    {
        use parent -norequire, qw( HTML::Object::Exception );
    };
    
    package
        HTML::Object::SyntaxError;
    BEGIN
    {
        use parent -norequire, qw( HTML::Object::Exception );
    };
    
    package
        HTML::Object::TypeError;
    BEGIN
    {
        use parent -norequire, qw( HTML::Object::Exception );
    };
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::Exception - HTML Object

=head1 SYNOPSIS

    use HTML::Object::Exception;
    my $this = HTML::Object::Exception->new || 
        die( HTML::Object::Exception->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This class inherits all its features and methods from L<Module::Generic::Exception>, and implements the following additional methods:

=head1 METHODS

=head2 colno

An alias for L</columnNumber>

=head2 columnNumber

Returns the column number, which usually returns C<undef>, because this is not set.

=head2 fileName

The file name where the error occurred. This is an alias for L<Module::Generic::Exception/file>

=head2 filename

An alias for L</fileName>

=head2 lineno

=head2 lineNumber

The line number where the error occurred. This is an alias for L<Module::Generic::Exception/line>

=head2 name

Returns the class name. For example: C<HTML::Object::Exception>

=head2 stack

Returns the stack trace object. This is an alias for L<Module::Generic::Exception/trace>

=head2 toLocalString

This is an alias for L<Module::Generic::Exception/as_string>

=head2 toString

This is an alias for L<Module::Generic::Exception/as_string>

=head2 OTHER EXCEPTION CLASSES

This module also implements the following exception classes used predominantly by L<HTML::Object::DOM>

=over 4

=item HTML::Object::ErrorEvent

The L<HTML::Object::ErrorEvent> object represents an error triggered and captured by a global error in the L<HTML::Object::DOM::Document> object.

It is used by properties like L<HTML::Object::DOM::Document/onabort> or L<HTML::Object::DOM::Document/onerror>

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/ErrorEvent>

=item HTML::Object::HierarchyRequestError

The C<HTML::Object::HierarchyRequestError> object represents an error when the node tree hierarchy is not correct.

=item HTML::Object::IndexSizeError

The C<HTML::Object::IndexSizeError> object representations an error that occurs when an index is not in the allowed range.

For example, in L<HTML::Object::DOM::CharacterData/substringData>

=item HTML::Object::InvalidCharacterError

The C<HTML::Object::InvalidCharacterError> object represents an error when a given named parameter contains one or more characters which are not valid.

=item HTML::Object::InvalidStateError

The C<HTML::Object::InvalidStateError> object represents an error when there is in an invalid state.

=item HTML::Object::MediaError

The C<HTML::Object::MediaError> object represents a L<HTML::Object::DOM::Element::Media> error.

=item HTML::Object::NotFoundError

The C<HTML::Object::NotFoundError> object represents an error when the object cannot be found here.

=item HTML::Object::SyntaxError

The C<HTML::Object::SyntaxError> object represents an error when trying to interpret syntactically invalid code. 

=item HTML::Object::TypeError

The C<HTML::Object::TypeError> object represents an error when an operation could not be performed, typically (but not exclusively) when a value is not of the expected type.

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::HierarchyRequestError>, L<Module::Generic::Exception>, L<Module::Generic/error>

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DOMException>

L<HTML::Object>, L<HTML::Object::Attribute>, L<HTML::Object::Boolean>, L<HTML::Object::Closing>, L<HTML::Object::Collection>, L<HTML::Object::Comment>, L<HTML::Object::Declaration>, L<HTML::Object::Document>, L<HTML::Object::Element>, L<HTML::Object::Exception>, L<HTML::Object::Literal>, L<HTML::Object::Number>, L<HTML::Object::Root>, L<HTML::Object::Space>, L<HTML::Object::Text>, L<HTML::Object::XQuery>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
