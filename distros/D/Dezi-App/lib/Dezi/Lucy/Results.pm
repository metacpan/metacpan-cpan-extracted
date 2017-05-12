package Dezi::Lucy::Results;
use Moose;
extends 'Dezi::Results';
use Dezi::Lucy::Result;
use namespace::autoclean;

our $VERSION = '0.014';

has 'find_relevant_fields' =>
    ( is => 'rw', isa => 'Bool', default => sub {0} );

=head1 NAME

Dezi::Lucy::Results - search results for Dezi::Lucy::Searcher

=head1 SYNOPSIS

  my $results = $searcher->search($query);
  $results->find_relevant_fields(1);
  while ( my $result = $results->next ) {
      my $fields = $result->relevant_fields;
      for my $f (@$fields) {
          printf("%s matched %s\n", $result->uri, $f);
      }
  }

=head1 DESCRIPTION

Dezi::Lucy::Results is an Apache Lucy based Results
class for Dezi::App.

=head1 METHODS

Only new and overridden methods are documented here. See
the L<Dezi::Results> documentation.

=head2 find_relevant_fields I<1|0>

Set to true (1) to locate the fields the query matched
for each result. Default is false (0).

NOTE that the Indexer must have had highlightable_fields set
to true (1) in order for find_relevant_fields to work.

=head2 next

Returns the next Dezi::Lucy::Result object from the result set.

=cut

sub next {
    my $hit = $_[0]->payload->next or return;

    # see http://markmail.org/message/xoqwxofwphlowqxf
    my @relevant_fields;
    if ( $_[0]->find_relevant_fields ) {
        my $searcher = $_[0]->{_searcher};
        my $compiler = $_[0]->{_compiler};
        my $doc_vec  = $searcher->fetch_doc_vec( $hit->get_doc_id );
        my $schema   = $searcher->get_schema();
        for my $field ( @{ $schema->all_fields } ) {
            my $spans = $compiler->highlight_spans(
                searcher => $searcher,
                doc_vec  => $doc_vec,
                field    => $field,
            );
            if (@$spans) {
                push @relevant_fields, $field;
            }
        }
    }
    return Dezi::Lucy::Result->new(
        relevant_fields => \@relevant_fields,
        doc             => $hit,
        property_map    => $_[0]->{property_map},

        # scale like xapian, swish-e
        score => ( int( $hit->get_score * 1000 ) || 1 ),
    );
}

__PACKAGE__->meta->make_immutable;

1;

=head1 AUTHOR

Peter Karman, E<lt>karpet@dezi.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-app at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::App

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

Copyright 2014 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL v2 or later.

=head1 SEE ALSO

L<http://dezi.org/>, L<http://swish-e.org/>, L<http://lucy.apache.org/>

