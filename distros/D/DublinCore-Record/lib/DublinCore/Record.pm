package DublinCore::Record;

=head1 NAME

DublinCore::Record - Container for Dublin Core metadata elements

=head1 SYNOPSIS

    use DublinCore::Record;
    
    my $record = DublinCore::Record->new();
    
    # later ...

    # print the title
    print $record->element( 'title' )->content;

    ## list context will retrieve all of a particular element 
    foreach my $element ( $record->element( 'Creator' ) ) {
        print "creator: ", $element->content(), "\n";
    }

    ## qualified dublin core
    my $creation = $record->element( 'Date.created' )->content();

=head1 DESCRIPTION

DublinCore::Record is an abstract class for manipulating DublinCore metadata.
The Dublin Core is a small set of metadata elements for describing information
resources. For more information on embedding DublinCore in HTML see RFC 2731 
L<http://www.ietf.org/rfc/rfc2731> or L<http://www.dublincore.org/documents/dces/>

=cut

use strict;
use warnings;

use Carp qw( croak );
use DublinCore::Element;

our $VERSION        = '0.03';
our @VALID_ELEMENTS = qw(
    title
    creator
    subject
    description
    publisher
    contributor
    date
    type
    format
    identifier
    source
    language
    relation
    coverage
    rights
);

=head1 METHODS

=head2 new()

The constructor. Takes no arguments.

    $record = DublinCore::Record->new();

=cut 

sub new {
    my $class = shift;
    my $self  = {};

    $self->{ "DC_$_" } = [] for @VALID_ELEMENTS;

    bless $self, $class;

    $self->add( @_ );

    return $self;
}

=head2 add( @elements )

Adds valid DublinCore::Element objects to the record.

=cut

sub add {
    my $self = shift;

    for my $element ( @_ ) {
        push @{ $self->{ 'DC_' . lc( $element->name ) } }, $element;
    }
}

=head2 remove( @elements )

Removes valid DublinCore::Element object from the record.

=cut

sub remove {
    my $self = shift;

    for my $element ( @_ ) {
        my $name = 'DC_' . lc( $element->name );
        $self->{ $name } = [
            grep { $element ne $_ } @{ $self->{ $name } }
        ];
    }
}

=head2 element() 

This method will return a relevant DublinCore::Element object. When 
called in a scalar context element() will return the first relevant element
found, and when called in a list context it will return all the relevant 
elements (since Dublin Core elements are repeatable).

    ## retrieve first title element
    my $element = $record->element( 'Title' );
    my $title = $element->content();
    
    ## shorthand object chaining to extract element content
    my $title = $record->element( 'Title' )->content();
    
    ## retrieve all creator elements
    @creators = $record->element( 'Creator' );

You can also retrieve qualified elements in a similar fashion. 

    my $date = $record->element( 'Date.created' )->content();

In order to fascilitate chaining element() will return an empty 
DublinCore::Element object when the requested element does not
exist. You can check if you're getting an empty empty back by using
the is_empty() method.

    if( $record->element( 'title' )->is_empty ) {
        # no title
    }

=cut

sub element {
    my ( $self, $name ) = @_;
    $name = lc( $name );

    ## must be a valid DC element (with additional qualifier)
    croak( "invalid Dublin Core element: $name" ) 
        if ! grep { $name =~ /^$_/ } @VALID_ELEMENTS;

    ## extract qualifier if present
    my $qualifier; 
    ( $name, $qualifier ) = split /\./, $name;

    my @elements = ();
    foreach my $element ( @{ $self->{ "DC_$name" } } ) {
        if ( $qualifier and $element->qualifier() =~ /$qualifier/i ) {
            push( @elements, $element );
        } elsif ( !$qualifier ) {
            push( @elements, $element );
        }
    }

    if ( wantarray ) { return @elements };
    return( $elements[ 0 ] ) if $elements[ 0 ];

    ## otherwise return an empty element object to fascilitate
    ## chaining when the element doesn't exist :
    ## $dc->element( 'Title' )->content().

    return( DublinCore::Element->new() );
}

=head2 elements()

Returns all the Dublin Core elements found as DublinCore::Element
objects which you can then manipulate further.

    foreach my $element ( $record->elements() ) {
        print "name=", $element->name(), "\n";
        print "content=", $element->content(), "\n";
    }

=cut 

sub elements {
    my $self = shift;
    my @elements = ();
    foreach my $type ( @VALID_ELEMENTS ) {
        push( @elements, @{ $self->{ "DC_$type" } } );
    }
    return( @elements );
}

=head2 title()

Returns a DublinCore::Element object for the title element. You can then 
retrieve content, qualifier, scheme, lang attributes like so. 

    my $title = $record->title();
    print "content:   ", $title->content(), "\n";
    print "qualifier: ", $title->qualifier(), "\n";
    print "scheme:    ", $title->scheme(), "\n";
    print "language:  ", $title->language(), "\n";

Since there can be multiple instances of a particular element type (title,
creator, subject, etc) you can retrieve multiple title elements by calling
title() in a list context.

    my @titles = $record->title();
    foreach my $title ( @titles ) {
        print "title: ", $title->content(), "\n";
    }

=cut

sub title {
    my $self = shift;
    return( $self->_getElement( 'title', wantarray ) );
}

=head2 creator()

Retrieve creator information in the same manner as title().

=cut

sub creator {
    my $self = shift;
    return( $self->_getElement( 'creator', wantarray ) );
}

=head2 subject()

Retrieve subject information in the same manner as title().

=cut

sub subject {
    my $self = shift;
    return( $self->_getElement( 'subject', wantarray ) );
}

=head2 description()

Retrieve description information in the same manner as title().

=cut

sub description {
    my $self = shift;
    return( $self->_getElement( 'description', wantarray ) );
}

=head2 publisher()

Retrieve publisher  information in the same manner as title().

=cut

sub publisher {
    my $self = shift;
    return( $self->_getElement( 'publisher', wantarray ) );
}

=head2 contributor()

Retrieve contributor information in the same manner as title().

=cut

sub contributor {
    my $self = shift;
    return( $self->_getElement( 'contributor', wantarray ) );
}

=head2 date()

Retrieve date information in the same manner as title().

=cut

sub date {
    my $self = shift;
    return( $self->_getElement( 'date', wantarray ) );
}

=head2 type()

Retrieve type information in the same manner as title().

=cut

sub type {
    my $self = shift;
    return( $self->_getElement( 'type', wantarray ) );
}

=head2 format()

Retrieve format information in the same manner as title().

=cut

sub format {
    my $self = shift;
    return( $self->_getElement( 'format', wantarray ) );
}

=head2 identifier()

Retrieve identifier information in the same manner as title().

=cut

sub identifier {
    my $self = shift;
    return( $self->_getElement( 'identifier', wantarray ) );
}

=head2 source()

Retrieve source information in the same manner as title().

=cut

sub source {
    my $self = shift;
    return( $self->_getElement( 'source', wantarray ) );
}

=head2 language()

Retrieve language information in the same manner as title().

=cut

sub language {
    my $self = shift;
    return( $self->_getElement( 'language', wantarray ) );
}

=head2 relation()

Retrieve relation information in the same manner as title().

=cut

sub relation {
    my $self = shift;
    return( $self->_getElement( 'relation', wantarray ) );
}

=head2 coverage()

Retrieve coverage information in the same manner as title().

=cut

sub coverage {
    my $self = shift;
    return( $self->_getElement( 'coverage', wantarray ) );
}

=head2 rights()

Retrieve rights information in the same manner as title().

=cut

sub rights {
    my $self = shift;
    return( $self->_getElement( 'rights', wantarray ) );
}

sub _getElement {
    my ( $self, $element, $wantarray ) = @_;
    my $contents = $self->{ "DC_$element" };

    if ( $wantarray ) {
        return( @$contents );
    }
    elsif ( scalar( @$contents ) > 0 ) {
        return( $contents->[ 0 ] );
    }

    return DublinCore::Element->new();
}

=head1 SEE ALSO

=over 4 

=item * DublinCore::Element

=item * Dublin Core L<http://www.dublincore.org/>

=item * RFC 2731 L<http://www.ietf.org/rfc/rfc2731>

=item * perl4lib L<http://www.rice.edu/perl4lib>

=back

=head1 AUTHOR

=over 4

=item * Ed Summers E<lt>ehs@pobox.comE<gt>

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Ed Summers, Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
