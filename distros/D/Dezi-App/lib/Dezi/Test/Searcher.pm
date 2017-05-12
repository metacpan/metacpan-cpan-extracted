package Dezi::Test::Searcher;
use Moose;
extends 'Dezi::Searcher';
use Types::Standard qw( InstanceOf );
use Carp;
use Data::Dump qw( dump );
use Scalar::Util qw( blessed );
use Dezi::Searcher::SearchOpts;
use Dezi::Test::Results;
use Dezi::Test::ResultsPayload;

# need this to build property_map
has 'swish3_config' =>
    ( is => 'rw', isa => InstanceOf ['SWISH::3::Config'], required => 1, );

sub _cache_property_map {
    my $self = shift;
    my %prop_map;
    my $props = $self->swish3_config->get_properties;
    for my $name ( @{ $props->keys } ) {
        my $prop  = $props->get($name);
        my $alias = $prop->alias_for;
        if ($alias) {
            $prop_map{$name} = $alias;
        }
    }
    $self->{property_map} = \%prop_map;
}

sub invindex_class {'Dezi::Test::InvIndex'}

sub search {
    my $self = shift;
    my ( $query, $opts ) = @_;
    if ($opts) {
        $opts = $self->_coerce_search_opts($opts);
    }
    if ( !defined $query ) {
        confess "query required";
    }
    elsif ( !blessed($query) ) {
        $query = $self->qp->parse($query)
            or confess "Invalid query: " . $self->qp->error;
    }

    #dump $self->invindex;

    my $hits = $self->invindex->[0]->search($query);

    # sort by number of matches per doc
    my @urls;
    my %scores;
    for my $url ( sort { $hits->{$b} <=> $hits->{$a} } keys %$hits ) {
        push @urls, $url;
        $scores{$url} = $hits->{$url};
    }

    # look up the doc object for each hit
    my @docs;
    for my $url (@urls) {
        push @docs, $self->invindex->[0]->get_doc($url);
    }

    #dump $self->invindex->[0];
    my $results = Dezi::Test::Results->new(
        query   => $query,
        hits    => scalar(@urls),
        payload => Dezi::Test::ResultsPayload->new(
            docs   => \@docs,
            urls   => \@urls,
            scores => \%scores,
        ),
        property_map => $self->property_map,
    );

    #dump $results;
    return $results;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Dezi::Test::Searcher - test searcher class

=head1 METHODS

=head2 swish3_config

Returns instance of L<SWISH::3::Config>.

=head2 invindex_class

Returns C<Dezi::Test::InvIndex>.

=head2 search( I<query>, I<opts> )

Returns L<Dezi::Test::Results>.

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

