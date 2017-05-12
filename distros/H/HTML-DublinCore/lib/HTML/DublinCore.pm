package HTML::DublinCore;

use strict;
use warnings;

use Carp qw( croak );
use base qw( DublinCore::Record HTML::Parser );

use DublinCore::Element;

our $VERSION = .4;

=head1 NAME

HTML::DublinCore - Extract Dublin Core metadata from HTML 

=head1 SYNOPSIS

  use HTML::DublinCore;

  ## pass HTML to constructor
  my $dc = HTML::DublinCore->new( $html );

  ## get the title element and print it's content
  my $title = $dc->element( 'Title' );
  print "title: ", $title->content(), "\n";

  ## get the same title content in one step
  print "title: ", $dc->element( 'Title' )->content(), "\n";

  ## list context will retrieve all of a particular element 
  foreach my $element ( $dc->element( 'Creator' ) ) {
      print "creator: ",$element->content(),"\n";
  }

  ## qualified dublin core
  my $creation = $dc->element( 'Date.created' )->content();

=head1 DESCRIPTION

HTML::DublinCore is a module for easily extracting Dublin Core metadata
that is embedded in HTML documents. The Dublin Core is a small set of metadata 
elements for describing information resources. Dublin Core is typically 
stored in the E<lt>HEADE<gt> of and HTML document using the E<lt>METAE<gt> tag.
For more information on embedding DublinCore in HTML see RFC 2731 
L<http://www.ietf.org/rfc/rfc2731>. For a definition of the 
meaning of various Dublin Core elements please see 
L<http://www.dublincore.org/documents/dces/>.

HTML::DublinCore actually extends Brian Cassidy's excellent DublinCore::Record
framework by adding some asHTML() methods, and a new constructor.

=head1 METHODS

=cut

## valid dublin core elements

=head2 new()

Constructor which you pass HTML content.

    $dc = HTML::DublinCore->new( $html );

=cut 

sub new {
    my ( $class, $html ) = @_;

    my $self = $class->SUPER::new;

    bless $self, $class;

    croak( "please supply string of HTML as argument to new()" ) if !$html;
    $self->{ "DC_errors" } = [];

    ## initialize our parser, and parse
    $self->init();
    $self->parse( $html );

}

=head2 asHtml() 

Serialize your Dublin Core metadata as HTML E<lt>METAE<gt> tags.

    print $dc->asHtml();

=cut

sub asHtml {
    my $self = shift;
    my $html = '';

    foreach my $element ( $self->elements ) {
        $html .= $element->asHtml() . "\n";
    }

    return( $html );
}

=head1 TODO

=over 4

=item * More comprehensive tests.

=item * Handle HTML entities properly.

=item * Collect error messages so they can be reported out of the object.

=back

=head1 SEE ALSO

=over 4 

=item * DublinCore::Record

=item * Dublin Core L<http://www.dublincore.org/>

=item * RFC 2731 L<http://www.ietf.org/rfc/rfc2731>

=item * HTML::Parser

=item * perl4lib L<http://perl4lib.perl.org/>

=back

=head1 AUTHORS

=over 4

=item * Ed Summers E<lt>ehs@pobox.comE<gt>

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Ed Summers, Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

## start tag hander. This automatically gets called in new() when we 
## parse HTML since HTML::DublinCore inherits from HTML::Parser.

sub start {
    my ( $self, $tagname, $attr, $attrseq, $origtext ) = @_;
    return if ( $tagname ne 'meta' );

    ## lowercase keys
    my %attributes = map { lc($_) => $attr->{$_} } keys( %$attr );

    ## parse name attribute (eg. DC.Identifier.ISBN )
    return( undef ) if ! exists( $attributes{ name } );
    my ( $namespace, $element, $qualifier ) = 
        split /\./, lc( $attributes{ name } );

    ## ignore non-DublinCore data 
    return( undef ) if $namespace ne 'dc';
    
    ## make sure element is dublin core
    if ( ! grep { $element } @DublinCore::Record::VALID_ELEMENTS ) {
        $self->_error( "invalid element: $element found" );
        return( undef );
    }

    ## return if we don't have a content attribute
    if ( ! exists( $attributes{ content } ) ) {
        $self->_error( "element $element lacks content" );
        return( undef );
    }

    ## create a new HTML::DublinCore::Element object 
    my $dc = DublinCore::Element->new();
    $dc->name( $element );
    $dc->qualifier( $qualifier );
    $dc->content( $attributes{ content } );
    if ( exists( $attributes{ scheme } ) ) {
        $dc->scheme( $attributes{ scheme } );
    } 
    if ( exists( $attributes{ lang } ) ) {
        $dc->language( $attributes{ lang } );
    }
   
    ## stash it for later
    $self->add( $dc );
}

sub _error {
    my ( $self, $msg ) = @_;
    push( @{ $self->{ DC_errors } }, $msg );
    return( 1 );
}

# add in a method to write DC elements as HTML meta tags.

package DublinCore::Element;

sub asHtml {
    my $self = shift;
    my $name = ucfirst( $self->name() );
    if ( $self->qualifier() ) { $name .= '.' . $self->qualifier(); }
    my $content = $self->content();
    my $scheme = $self->scheme();
    my $lang = $self->language();

    my $html = qq(<meta name="DC.$name" content="$content");
    if ( $scheme ) { 
        $html .= qq( scheme="$scheme"); 
    }
    if ( $lang ) { 
        $html .= qq( lang="$lang");
    } 
    $html .= '>';
    return ( $html );
}

1;
