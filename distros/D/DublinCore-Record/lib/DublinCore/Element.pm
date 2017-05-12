package DublinCore::Element;

=head1 NAME

DublinCore::Element - Class for representing a Dublin Core element

=head1 SYNOPSIS

    my $element = DublinCore::Element->new( \%info );
    print "content:   ", $element->content(), "\n";
    print "qualifier: ", $element->qualifier(), "\n";
    print "language:  ", $element->language(), "\n";
    print "scheme:    ", $element->scheme(), "\n";

=head1 DESCRIPTION

DublinCore::Record methods such as element(), elements(), title(), etc return
DublinCore::Element objects as their result. These can be queried 
further to extract an elements content, qualifier, language, and schema. For a 
definition of these attributes please see RFC 2731 and 
L<http://www.dublincore.org>.

=cut

use base qw( Class::Accessor );

use strict;
use warnings;

our $VERSION = '0.03';

__PACKAGE__->mk_accessors( qw( name qualifier content language scheme is_empty ) );

=head1 METHODS

=head2 new()

The constructor. Take a hashref of input arguments.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new( @_ );

    bless $self, $class;

    $self->is_empty( 1 );

    return $self;
}

=head2 content()

Gets and sets the content of the element.
    
    ## extract the element
    my $title = $record->element( 'title' );
    print $title->content();

    ## or you can chain them together
    print $record->element( 'title' )->content();

=head2 qualifier()

Gets and sets the qualifier used by the element.

=head2 language()

Gets and sets the language of the content in element.

=head2 scheme()

Gets and sets the scheme used by the element. 

=head2 name()

Gets and sets the element name (title, creator, date, etc).

=head2 is_empty()

Gets and sets the "empty" status of an element. This is useful when
using DublinCore::Record's element() method.

To see if the record has an creator elements:

    if( $record->element( 'creator' )->is_empty ) {
        # no creators
    }


=head2 set()

This function overrides the default set() behavior in order to remove the
is_empty flag.

=cut

sub set {
    my $self = shift;
    $self->SUPER::set( 'is_empty' => 0 ) if $self->is_empty;
    $self->SUPER::set( @_ );
}

=head1 SEE ALSO

=over 4 

=item * DublinCore::Record

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
