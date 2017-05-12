package Dezi::Searcher;
use Moose;
use MooseX::StrictConstructor;
with 'Dezi::Role';
use Types::Standard qw( InstanceOf HashRef Int );
use Dezi::Types qw( DeziInvIndexArr );
use Dezi::Searcher::SearchOpts;
use Carp;
use Scalar::Util qw( blessed );
use Class::Load;
use Search::Query;
use Search::Query::Parser;
use namespace::autoclean;

our $VERSION = '0.014';

has 'max_hits' => ( is => 'rw', isa => Int, default => 1000 );
has 'invindex' => (
    is       => 'rw',
    isa      => DeziInvIndexArr,
    required => 1,
    coerce   => 1,
);
has 'qp_config' =>
    ( is => 'rw', isa => HashRef, builder => 'init_qp_config', lazy => 1, );
has 'qp' => (
    is      => 'rw',
    isa     => InstanceOf ['Search::Query::Parser'],
    builder => 'init_qp',
    lazy    => 1,
);
has 'property_map' => ( is => 'ro', isa => HashRef );

=head1 NAME

Dezi::Searcher - base searcher class

=head1 SYNOPSIS

 my $searcher = Dezi::Searcher->new(
                    invindex        => 'path/to/index',
                    max_hits        => 1000,
                );
                
 my $results = $searcher->search( 'foo bar' );
 while (my $result = $results->next) {
     printf("%4d %s\n", $result->score, $result->uri);
 }

=head1 DESCRIPTION

Dezi::Searcher is a base searcher class. It defines
the APIs that all Dezi storage backends adhere to in
returning results from a Dezi::InvIndex.

=head1 METHODS

=head2 BUILD

Build searcher object. Called internally by new().

=head2 invindex

A Dezi::InvIndex object or directory path. Required. Set in new().

May be a single value or an array ref of values (for searching multiple
indexes at once).

=head2 max_hits

The maximum number of hits to return. Optional. Default is 1000.

=head2 qp_config

Optional hashref passed to Search::Query::Parser->new().

=cut

sub BUILD {
    my $self = shift;

    for my $invindex ( @{ $self->{invindex} } ) {

        # make sure invindex is blessed into invindex_class
        # and re-bless if necessary
        if ( !blessed $invindex or !$invindex->isa( $self->invindex_class ) )
        {
            Class::Load::load_class( $self->invindex_class );
            $invindex = $self->invindex_class->new( path => "$invindex" );
        }

        $invindex->open_ro;
    }

    # subclasses can cache however they need to. e.g. Test::Searcher
    $self->_cache_property_map();
}

sub _cache_property_map {
    my $self = shift;

    # assumes same for every invindex so grab the first one.
    $self->{property_map}
        = $self->invindex->[0]->get_header->get_property_map();
}

=head2 invindex_class

Returns string 'Dezi::InvIndex'. Override this in a subclass to indicate
the corresponding InvIndex class for your Searcher.

=cut

sub invindex_class {'Dezi::InvIndex'}

=head2 init_qp_config

Returns empty hashref by default. Override this to provide
custom default config for the qp (L<Search::Query::Parser>).

=cut

sub init_qp_config { {} }

=head2 init_qp

Returns Search::Query::Parser->new( $self->init_qp_config )
by default. Override in a subclass to customize the L<Search::Query::Parser>
object.

=cut

sub init_qp {
    my $self = shift;
    my $qp_config = $self->qp_config || {};
    return Search::Query::Parser->new(%$qp_config);
}

=head2 search( I<query>, I<opts> )

Returns a Dezi::Results object.

I<query> should be a L<Search::Query::Dialect> object or a string parse-able
by L<Search::Query::Parser>.

I<opts> should be a Dezi::Searcher::SearchOpts object or a hashref.

=cut

sub search {
    my $self = shift;
    my ( $query, $opts ) = @_;

    confess "$self does not implement search() method";
}

sub _coerce_search_opts {
    my $self = shift;
    my $opts = shift or return Dezi::Searcher::SearchOpts->new();
    if ( !blessed($opts) ) {
        if ( ref $opts ne 'HASH' ) {
            confess "opts must be a hashref";
        }
        $opts = Dezi::Searcher::SearchOpts->new($opts);
    }
    elsif ( !$opts->isa('Dezi::Searcher::SearchOpts') ) {
        confess "opts must be a hashref or Dezi::Searcher::SearchOpts object";
    }
    return $opts;
}

=head2 property_map

Build from the InvIndex::Header, a hashref of property aliases to real names.
A read-only attribute propagated to the Results from search().

=cut

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

    perldoc Dezi::Searcher

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

