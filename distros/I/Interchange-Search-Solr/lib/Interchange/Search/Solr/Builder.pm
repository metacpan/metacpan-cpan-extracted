package Interchange::Search::Solr::Builder;

use strict;
use warnings;

use Moo;
use Types::Standard qw/ArrayRef HashRef Int/;

=head1 NAME

Interchange::Search::Solr::Builder

=head1 DESCRIPTION

L<WebService::Solr::Response> subclass for building url.

=head1 ACCESSORS

=head2 terms

An arrayref contains search terms

=cut

has terms => (
    is  => 'rw',
    isa => ArrayRef
);

=head2 filters

A hashref which key is a feild of data and the value is keyword 
that needs to filter.

=cut

has filters => (
    is  => 'rw',
    isa => HashRef
);

=head2 facets

A string or an arrayref with the fields which will generate a facet.
Defaults to
    [qw/suchbegriffe manufacturer/]

=cut

has facets => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub {
         return [qw/suchbegriffe manufacturer/];
    }
);

=head2 page

A number of page and must be positive number (>= 1)

=cut

has page => (
    is  => 'rw',
    isa => sub {
        if (defined $_[0]){ 
            die "$_[0] is not integer" if $_[0] !~ /^\d+$/;
            die "must be positive number" unless $_[0] >= 1
        }
    }
);

=head1 METHODS

In addition to all the L<WebService::Solr::Response> methods this
class have the following methods:

=head2 url_builder;

Build a query url with the parameter passed

=cut

sub url_builder {
    my $self = shift;

    my @fragments;
    if (@{$self->terms}) {
        push @fragments, 'words', @{$self->terms};
    }

    if (%{$self->filters}) {
        foreach my $facet (@{ $self->facets }) {
            if (my $terms = $self->filters->{$facet}) {
                push @fragments, $facet, @$terms;
            }
        }
    }
    if ($self->page and $self->page > 1) {
        push @fragments, page => $self->page;
    }
    return join ('/', @fragments);
}

1;
