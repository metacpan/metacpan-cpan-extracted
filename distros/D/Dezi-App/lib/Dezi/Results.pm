package Dezi::Results;
use Moose;
use MooseX::StrictConstructor;
with 'Dezi::Role';
use Carp;
use namespace::autoclean;

our $VERSION = '0.015';

has 'hits' => ( is => 'ro', isa => 'Int', required => 1 );
has 'query' => ( is => 'ro', isa => 'Search::Query::Dialect', required => 1 );
has 'payload'      => ( is => 'ro', isa => 'Object',  required => 1 );
has 'property_map' => ( is => 'ro', isa => 'HashRef', required => 1 );

=head1 NAME

Dezi::Results - base results class

=head1 SYNOPSIS

 my $searcher = Dezi::Searcher->new(
                    invindex        => 'path/to/index',
                    query_class     => 'Dezi::Query',
                    query_parser    => $swish_prog_queryparser,
                );

 my $results = $searcher->search( 'foo bar' );
 while (my $result = $results->next) {
     printf("%4d %s\n", $result->score, $result->uri);
 }

=head1 DESCRIPTION

Dezi::Results is a base results class. It defines
the APIs that all Dezi storage backends adhere to in
returning results from a Dezi::InvIndex.

=head1 METHODS

=head2 query

Should return the search query as it was evaluated by the Searcher.
Will be a Search::Query::Dialect object.

=head2 hits

Returns the number of matching documents for the query.

=head2 payload

The internal object holding the backend results.

=head2 property_map

Set by the parent Searcher, a hashref of property aliases to real names.

=head2 next

Return the next Result.

=cut

sub next {
    confess "$_[0] must implement next()";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>karpet@dezi.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-app at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Results

You can also look for information at:

=over 4

=item * Website

L<http://dezi.org/>

=item * IRC

#dezisearch at freenode

=item * Mailing list

L<https://groups.google.com/forum/#!forum/dezi-search>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<https://metacpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2015 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://dezi.org/>, L<http://swish-e.org/>, L<http://lucy.apache.org/>

