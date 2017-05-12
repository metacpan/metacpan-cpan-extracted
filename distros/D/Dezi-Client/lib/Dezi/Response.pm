package Dezi::Response;
use Moo;
use Types::Standard qw( Str Num Int ArrayRef HashRef InstanceOf Maybe );
use Carp;
use JSON;
use Dezi::Doc;
use namespace::autoclean;

our $VERSION = '0.003004';

has 'http_response' => ( is => 'ro', isa => InstanceOf ['HTTP::Response'] );
has 'results'       => ( is => 'rw', isa => Maybe      [ArrayRef] );
has 'total'         => ( is => 'rw', isa => Int );
has 'search_time'   => ( is => 'rw', isa => Num );
has 'build_time'    => ( is => 'rw', isa => Num );
has 'query'         => ( is => 'rw', isa => Str );
has 'fields'        => ( is => 'rw', isa => Maybe      [ArrayRef] );
has 'facets'        => ( is => 'rw', isa => Maybe      [HashRef] );
has 'suggestions'   => ( is => 'rw', isa => Maybe      [ArrayRef] );

=pod

=head1 NAME

Dezi::Response - Dezi search server response

=head1 SYNOPSIS

 use Dezi::Client;
 my $client = Dezi::Client->new('http://localhost:5000');
 
 my $response = $client->search( q => 'foo' );
 # $response isa Dezi::Response
 
 # iterate over results
 for my $result (@{ $response->results }) {
     printf("--\n uri: %s\n title: %s\n score: %s\n",
        $result->uri, $result->title, $result->score);
 }
 
 # print stats
 printf("       hits: %d\n", $response->total);
 printf("search time: %s\n", $response->search_time);
 printf(" build time: %s\n", $response->build_time);
 printf("      query: %s\n", $response->query);

=head1 DESCRIPTION

Dezi::Response represents a Dezi server response.

This class is used internally by Dezi::Client.

=head1 METHODS

=head2 new( I<http_response> )

Returns a new response. I<http_response> should be a HTTP::Response
object from a Dezi JSON response.

=head2 BUILDARGS

Allows for single argument I<http_response> instead of named pair.

=head2 BUILD

Initializes objects.

=cut

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 ) {
        return $class->$orig( http_response => $_[0] );
    }
    else {
        return $class->$orig(@_);
    }
};

sub BUILD {
    my $self = shift;
    my $json = from_json( $self->http_response->decoded_content );

    # inflate json into self, except results
    for my $attr ( keys %$json ) {
        next if $attr eq 'results';

        # set in hash directly if we have no method (yet)
        if ( $self->can($attr) ) {
            $self->$attr( $json->{$attr} );
        }
        else {
            $self->{$attr} = $json->{$attr};
        }
    }
    my @res;
    my @fields;
    for my $r ( @{ $json->{results} } ) {
        if ( !@fields ) {
            for my $k ( keys %$r ) {
                if ( !Dezi::Doc->can($k) ) {
                    push @fields, $k;
                }
            }
        }
        my %fields = map { $_ => $r->{$_} } @fields;
        push @res, Dezi::Doc->new( %$r, _fields => \%fields );
    }

    # overwrite with objects
    $self->{results} = \@res;
}

=head2 results

Returns array ref of Dezi::Doc objects.

=head2 total 

Returns integer of hit count.

=head2 search_time 

Returns string of floating point time Dezi server took to search.

=head2 build_time 

Returns string of floating point time Dezi server took to build
response.

=head2 query 

Returns the query string.

=head2 fields 

Returns array ref of field names.

=head2 facets

Returns array ref of facet objects.

B<Facet objects are currently hashrefs. This may change in future.>

=head2 suggestions

Returns array ref of query suggestions.

=head2 http_response

Returns raw HTTP:Response object.

=cut

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

=head1 COPYRIGHT & LICENSE

Copyright 2011 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
