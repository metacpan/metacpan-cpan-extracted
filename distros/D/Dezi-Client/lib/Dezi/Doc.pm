package Dezi::Doc;
use Moo;
use Types::Standard qw( Str Int Num HashRef );
use Carp;
use Search::Tools::XML;
use namespace::autoclean;

our $VERSION = '0.003004';

has 'mime_type' => ( is => 'rw', isa => Str );
has 'summary'   => ( is => 'rw', isa => Str );
has 'title'     => ( is => 'rw', isa => Str );
has 'content'   => ( is => 'rw', isa => Str );
has 'uri'       => ( is => 'rw', isa => Str );
has 'mtime'     => ( is => 'rw', isa => Int );
has 'size'      => ( is => 'rw', isa => Int );
has 'score'     => ( is => 'rw', isa => Num );
has '_fields'   => ( is => 'rw', isa => HashRef );

=pod

=head1 NAME

Dezi::Doc - a Dezi client document

=head1 SYNOPSIS

 # add doc to the index
 use Dezi::Doc;
 my $html = "<html>hello world</html>";
 my $doc = Dezi::Doc->new(
     mime_type => 'text/html',
     uri       => 'foo/bar.html',
     mtime     => time(),
     size      => length $html,
     content   => $html,
 );
 $client->index( $doc );
 
 # construct a document with field/value pairs
 my $doc2 = Dezi::Doc->new(
    uri => 'auto/xml/magic',
 );
 $doc2->set_field('title' => 'ima dezi doc');
 $doc2->set_field('body'  => 'hello world!');
 $client->index( $doc2 );
 
 # search results are also Dezi::Doc objects
 for my $doc (@{ $response->results }) {
     printf("hit: %s %s\n", $doc->score, $doc->uri);
 }

=head1 DESCRIPTION

Dezi::Doc represents one document in a collection.

=head1 METHODS

=head2 new

Create new object. Takes pairs of key/values where the keys are one of:

=over

=item mime_type

Sometimes known as the content type. A MIME type indicates the kind
of document this is.

=item uri

The unique URI for the document.

=item mtime

Last modified time. Should be expressed in Epoch seconds.

=item size

Length in bytes.

=item content

The document's content.

=back

=cut

=head2 score

When returned from a Dezi::Response->results array,
the score attribute is the search ranking score.

=head2 title

When returned from a Dezi::Response->results array,
the title is the document's parsed title.

B<NOTE> you cannot set the title of a doc object when
sending to the index. See set_field() instead.

=head2 summary

When returned from a Dezi::Response->results array,
the summary is the snipped and highlighted extract
from the document showing query terms in context.

B<NOTE> you cannot set the summary of a doc object when
sending to the index. The summary is a result field only.
It typically represents all or snipped part of the
C<swishdescription> field in the index.

=cut

=head2 as_string_ref

Returns a scalar ref pointing at the Dezi::Doc serialized,
either the value of content() or a XML fragment representing
values set with set_field().

=cut

sub as_string_ref {
    my $self = shift;
    if ( exists $self->{_fields} ) {
        my $xml
            = Search::Tools::XML->perl_to_xml( $self->{_fields}, 'doc', 1 );
        return \$xml;
    }
    else {
        my $content = $self->content;
        return \$content;
    }
}

=head2 get_field( I<field_name> )

Returns the value of I<field_name>.

=cut

sub get_field {
    my $self = shift;
    my $name = shift or croak "field_name required";
    if ( !exists $self->{_fields}->{$name} ) {
        return undef;
    }
    return $self->{_fields}->{$name};
}

=head2 set_field( I<field> => I<value> )

Set the I<value> for field I<field>.

This method also sets the mime_type() of the document object
to 'application/xml' since that is how as_string_ref() will
render the object.

=cut

sub set_field {
    my $self  = shift;
    my $field = shift or croak "field_name required";
    my $value = shift;
    croak "value required" unless defined $value;
    $self->{_fields}->{$field} = $value;
    $self->mime_type('application/xml');
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-client at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Client


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-Client>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-Client/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2011 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
