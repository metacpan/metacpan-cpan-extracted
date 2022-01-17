##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Implementation.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/05
## Modified 2022/01/05
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Implementation;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use HTML::Object::DOM::Declaration;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub createDocument
{
    my $self = shift( @_ );
    return( $self->error({
        message => sprintf( "At least 2 arguments required, but only %d passed: \$document->implementation->createDocument( \$namespaceURI, \$qualifiedNameStr, \$documentType )", scalar( @_ ) ),
        class => 'HTML::Object::TypeError',
    }) ) if( scalar( @_ ) < 2 );
    my( $namespaceURI, $qualifiedNameStr, $documentType ) = @_;
    return( $self->error({
        message => "The second argument, qualified name string, can only be \"html\".",
        class => 'HTML::Object::TypeError',
    }) ) if( lc( $qualifiedNameStr ) ne 'html' );
    return( $self->error({
        message => 'Document type argument provided, but it is not a HTML::Object::DOM::Declaration object.',
        class => 'HTML::Object::TypeError',
    }) ) if( scalar( @_ ) >= 3 && !$self->_is_a( $documentType => 'HTML::Object::DOM::Declaration' ) );
    my $doc = $self->createHTMLDocument || return( $self->pass_error );
    $doc->declaration( $documentType ) if( defined( $documentType ) );
    return( $doc );
}

sub createDocumentType
{
    my $self = shift( @_ );
#     return( $self->error({
#         message => sprintf( "At least 3 arguments required, but only %d passed: \$document->implementation->createDocumentType( \$qualifiedNameStr, \$publicId, \$systemId )", scalar( @_ ) ),
#         class => 'HTML::Object::TypeError',
#     }) ) if( scalar( @_ ) < 3 );
    my( $qualifiedNameStr, $publicId, $systemId ) = @_;
    $qualifiedNameStr = 'html' if( !defined( $qualifiedNameStr ) || !CORE::length( "$qualifiedNameStr" ) );
    my $dtd = HTML::Object::DOM::Declaration->new( name => $qualifiedNameStr ) || 
        return( $self->pass_error( HTML::Object::DOM::Declaration->error ) );
    return( $dtd );
}

sub createHTMLDocument
{
    my $self = shift( @_ );
    my $title;
    $title = shift( @_ ) if( @_ );
    my $html;
    if( defined( $title ) )
    {
        $html = <<EOT;
<!DOCTYPE html>
<html><head><title>${title}<title></head><body></body></html>
EOT
    }
    else
    {
        $html = <<EOT;
<!DOCTYPE html>
<html><head></head><body></body></html>
EOT
    }
    my $p = HTML::Object::DOM->new;
    my $doc = $p->parse_data( $html ) || return( $self->pass_error( $p->error ) );
    return( $doc );
}

sub hasFeature { return(1); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Implementation - HTML Object DOM Implementation

=head1 SYNOPSIS

    use HTML::Object::DOM::Implementation;
    my $impl = HTML::Object::DOM::Implementation->new || 
        die( HTML::Object::DOM::Implementation->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The C<Implementation> interface represents an object providing methods which are not dependent on any particular document. Such an object is returned by the L<HTML::Object::DOM::Document/implementation> property.

=head1 PROPERTIES

There are no properties

=head1 METHODS

=head2 createDocument

Provided with a namespace URI (which could be an empty string) and a qualified name for the top element, which should be C<html> and optionally a L<document type definition object|HTML::Object::DOM::Declaration> and this creates and returns a L<document object|HTML::Object::DOM::Document>.

Normally, this method is used to create an XML document, but we do not support XML, so this is basically an alias for L</createHTMLDocument>

The namespaceURI argument is completely ignored, so do not bother and the qualified name can only be C<html>.

Example:

    my $doc = $doc->implementation->createDocument( $namespaceURI, $qualifiedNameStr, $documentType_object );

    my $doc = $doc->implementation->createDocument( '', 'html' );
    my $body = $doc->createElement( 'body' );
    $body->setAttribute( 'id', 'abc' );
    $doc->documentElement->appendChild( $body );
    say( $doc->getElementById( 'abc') ); # [object HTMLBodyElement]

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation/createDocument>

=head2 createDocumentType

Provided with a qualified name, which should be C<html> and an optional public id and system id, both of which are ignored, and this creates and returns a L<document type object|HTML::Object::DOM::Declaration>.

Example:

    my $doctype = $doc->implementation->createDocumentType( 'html', $publicId, $systemId );

    my $dt = $doc->implementation->createDocumentType( 'svg:svg', '-//W3C//DTD SVG 1.1//EN', 'http://www->w3.org/Graphics/SVG/1.1/DTD/svg11.dtd' );
    my $d = $doc->implementation->createDocument( 'http://www->w3.org/2000/svg', 'svg:svg', $dt );
    say( $d->doctype->publicId); # -//W3C//DTD SVG 1.1//EN

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation/createDocumentType>

=head2 createHTMLDocument

Creates and returns an HTML Document.

Example:

    # Assuming $title is "Demo"
    my $newDoc = $doc->implementation->createHTMLDocument( $title );

Result:

    <!DOCTYPE html>
    <html>
        <head><title>Demo</title></head>
        <body></body>
    </html>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation/createHTMLDocument>

=head2 hasFeature

This always returns true.

Its original purpose is to return a boolean value indicating if a given feature is supported or not. However, this function has been unreliable and kept for compatibility purpose alone: except for SVG-related queries.

Example:

    my $flag = $doc->implementation->hasFeature( $feature, $version );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation/hasFeature>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
