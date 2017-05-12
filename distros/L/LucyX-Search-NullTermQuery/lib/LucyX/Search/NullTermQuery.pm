package LucyX::Search::NullTermQuery;
use strict;
use warnings;
use base qw( Lucy::Search::NOTQuery );
use Carp;
use LucyX::Search::AnyTermQuery;

our $VERSION = '0.006';

=head1 NAME

LucyX::Search::NullTermQuery - Lucy query extension for NULL values

=head1 SYNOPSIS


 my $query = LucyX::Search::NullTermQuery->new(
    field   => 'color',
 );
 my $hits = $searcher->hits( query => $query );
 
=head1 DESCRIPTION

NullTermQuery is for matching documents in a Lucy index
that have no value for a field.

NullTermQuery isa NOTQuery negating an AnyTermQuery.

=head1 METHODS

This class isa Lucy::Search::NOTQuery subclass.
Only new or overridden methods are documented.

=head2 new( field => $field )

Returns a NullTermQuery.

=cut

sub new {
    my ( $class, %args ) = @_;
    my $any_term_query = LucyX::Search::AnyTermQuery->new(%args);
    return $class->SUPER::new( negated_query => $any_term_query, );
}

=head2 to_string

Returns the query clause the object represents.

=cut

sub to_string {
    my $self = shift;
    return sprintf( "(%s:NULL)", $self->get_negated_query->get_field() );
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lucyx-search-wildcardquery at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LucyX-Search-NullTermQuery>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LucyX::Search::NullTermQuery


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LucyX-Search-NullTermQuery>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LucyX-Search-NullTermQuery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LucyX-Search-NullTermQuery>

=item * Search CPAN

L<http://search.cpan.org/dist/LucyX-Search-NullTermQuery/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
