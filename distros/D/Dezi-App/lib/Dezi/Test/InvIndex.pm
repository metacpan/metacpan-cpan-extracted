package Dezi::Test::InvIndex;
use Moose;
extends 'Dezi::InvIndex';
use Types::Standard qw( InstanceOf );
use Carp;
use Dezi::Cache;
use Data::Dump qw( dump );

=head1 NAME

Dezi::Test::InvIndex - test in-memory invindex

=head1 METHODS

=head2 term_cache

=head2 doc_cache

=head2 open

=head2 search

=head2 put_doc

=head2 get_doc

=cut

# in memory invindex
has 'term_cache' => (
    is      => 'rw',
    isa     => InstanceOf ['Dezi::Cache'],
    default => sub { Dezi::Cache->new },
);
has 'doc_cache' => (
    is      => 'rw',
    isa     => InstanceOf ['Dezi::Cache'],
    default => sub { Dezi::Cache->new },
);

sub open {
    my $self = shift;

    # no-op
}

sub search {
    my $self = shift;
    my ( $query, $opts ) = @_;
    if ( !defined $query ) {
        confess "query required";
    }
    my %hits;
    my $term_cache = $self->term_cache;

    # walk the query, matching terms against our cache
    $query->walk(
        sub {
            my ( $clause, $dialect, $sub, $prefix ) = @_;

            #dump $clause;
            return if $clause->is_tree;    # skip parents
            return unless $term_cache->has( $clause->value );
            if ( $clause->op eq "" or $clause->op eq "+" ) {

                # include
                for my $uri ( keys %{ $term_cache->get( $clause->value ) } ) {
                    $hits{$uri}++;
                }
            }
            else {

                # exclude
                for my $uri ( keys %{ $term_cache->get( $clause->value ) } ) {
                    delete $hits{$uri};
                }
            }
        }
    );

    #dump \%hits;

    return \%hits;
}

sub put_doc {
    my $self = shift;
    my $doc = shift or confess "doc required";
    $self->doc_cache->add( $doc->uri => $doc );
    return $doc;
}

sub get_doc {
    my $self = shift;
    my $uri = shift or confess "uri required";
    return $self->doc_cache->get($uri);
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

