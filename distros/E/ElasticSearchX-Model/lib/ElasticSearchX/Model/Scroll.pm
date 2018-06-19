#
# This file is part of ElasticSearchX-Model
#
# This software is Copyright (c) 2018 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package ElasticSearchX::Model::Scroll;
$ElasticSearchX::Model::Scroll::VERSION = '2.0.0';
use Moose;

use ElasticSearchX::Model::Document::Types qw(ESScroll);

has scroll => ( is => 'ro', isa => 'Str', required => 1, default => '1m' );

has set => (
    is       => 'ro',
    isa      => 'ElasticSearchX::Model::Document::Set',
    required => 1,
    handles  => [qw(type index inflate inflate_result)],
);

has _scrolled_search => (
    is         => 'ro',
    isa        => ESScroll,
    lazy_build => 1,
    handles    => {
        _next     => 'next',
        total     => 'total',
        max_score => 'max_score'
    }
);

has qs => (
    is  => 'ro',
    isa => 'HashRef',
);

sub _build__scrolled_search {
    my $self = shift;
    $self->set->es->scroll_helper(
        body   => $self->set->_build_query,
        scroll => $self->scroll,
        index  => $self->index->name,
        type   => $self->type->short_name,
        %{ $self->qs || {} },
    );
}

sub next {
    my $self = shift;
    return undef unless ( my $next = $self->_next );
    return $next unless ( $self->inflate );
    return $self->inflate_result($next);
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

ElasticSearchX::Model::Scroll

=head1 VERSION

version 2.0.0

=head1 SYNOPSIS

 my $iterator = $twitter->type('tweet')->scroll( '5m' );
 while(my $tweet = $iterator->next) {
     # do something with $tweet
 }
 
 my $iterator = $twitter->type('tweet')->raw->scroll;
 $iterator->max_score;
 $iterator->total;

=head1 ATTRIBUTES

=head2 scroll

This string indicated how long ElasticSearch should keep the scrolled
search around. This attribute is set by passing it to
L<ElasticSearchX::Model::Document::Set/scroll>.

=head2 set

The L<ElasticSearchX::Model::Document::Set> this instance was build
from.

=head1 METHODS

=head2 total

=head2 eof

=head2 max_score

Delegates to L<Elasticsearch::Scroll>.

=head2 next

Returns the next result in the search. If you set the query to not
inflate the results (e.g. using L<ElasticSearchX::Model::Document::Set/raw>)
it returns the raw HashRef, otherwise the result is inflated to
the correct document class.

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
