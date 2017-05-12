package Elastic::Model::Role::Results;
$Elastic::Model::Role::Results::VERSION = '0.52';
use Carp;
use Moose::Role;

with 'Elastic::Model::Role::Iterator';

use MooseX::Types::Moose qw(HashRef Int Num CodeRef Bool);
use namespace::autoclean;

#===================================
has 'search' => (
#===================================
    isa      => HashRef,
    is       => 'ro',
    required => 1,
);

#===================================
has 'total' => (
#===================================
    isa    => Int,
    is     => 'ro',
    writer => '_set_total',
);

#===================================
has 'max_score' => (
#===================================
    isa    => Num,
    is     => 'ro',
    writer => '_set_max_score',
);

#===================================
has 'facets' => (
#===================================
    isa     => HashRef,
    traits  => ['Hash'],
    is      => 'ro',
    writer  => '_set_facets',
    handles => { facet => 'get' }
);

#===================================
has 'aggs' => (
#===================================
    isa     => HashRef,
    traits  => ['Hash'],
    is      => 'ro',
    writer  => '_set_aggs',
    handles => { agg => 'get' }
);

#===================================
has 'is_partial' => (
#===================================
    isa     => Bool,
    is      => 'ro',
    lazy    => 1,
    builder => '_build_is_partial',
);

#===================================
has '_as_result' => (
#===================================
    isa     => CodeRef,
    is      => 'ro',
    lazy    => 1,
    builder => '_as_result_builder'
);

#===================================
has '_as_results' => (
#===================================
    isa     => CodeRef,
    is      => 'ro',
    lazy    => 1,
    builder => '_as_results_builder'
);

#===================================
has '_as_object' => (
#===================================
    isa     => CodeRef,
    is      => 'ro',
    lazy    => 1,
    builder => '_as_object_builder'
);

#===================================
has '_as_objects' => (
#===================================
    isa     => CodeRef,
    is      => 'ro',
    lazy    => 1,
    builder => '_as_objects_builder'
);

#===================================
has '_as_partial' => (
#===================================
    isa     => CodeRef,
    is      => 'ro',
    lazy    => 1,
    builder => '_as_partial_builder'
);

#===================================
has '_as_partials' => (
#===================================
    isa     => CodeRef,
    is      => 'ro',
    lazy    => 1,
    builder => '_as_partials_builder'
);

no Moose;

#===================================
sub _build_is_partial {
#===================================
    my $self = shift;
    return exists $self->search->{_source};
}

#===================================
sub _as_result_builder {
#===================================
    my $self         = shift;
    my $result_class = $self->model->result_class;
    my $is_partial   = $self->is_partial;
    sub {
        $_[0]
            && $result_class->new(
            result     => $_[0],
            is_partial => $is_partial
            );
        }
}

#===================================
sub _as_results_builder {
#===================================
    my $self         = shift;
    my $result_class = $self->model->result_class;
    my $is_partial   = $self->is_partial;
    sub {
        map { $result_class->new( result => $_, is_partial => $is_partial ) }
            @_;
    };
}

#===================================
sub _as_object_builder {
#===================================
    my $self       = shift;
    my $model      = $self->model;
    my $is_partial = $self->is_partial;
    sub {
        my $raw = shift or return;
        $raw->{_object} ||= do {
            my $uid = Elastic::Model::UID->new_from_store($raw);
            my $source = $is_partial ? undef : $raw->{_source};
            $model->get_doc( uid => $uid, source => $source );
        };
    };
}

#===================================
sub _as_objects_builder {
#===================================
    my $self       = shift;
    my $m          = $self->model;
    my $is_partial = $self->is_partial;
    sub {
        map {
            $_->{_object} ||= do {
                my $uid = Elastic::Model::UID->new_from_store($_);
                my $source = $is_partial ? undef : $_->{_source};
                $m->get_doc( uid => $uid, source => $source );
            };
        } @_;
    };
}

#===================================
sub _as_partial_builder {
#===================================
    my $self  = shift;
    my $model = $self->model;
    sub {
        my $raw = shift or return;
        $raw->{_partial} ||= do {
            my $uid = Elastic::Model::UID->new_partial($raw);
            $model->new_partial_doc(
                uid            => $uid,
                partial_source => $raw->{_source}
            );
            }

    };
}

#===================================
sub _as_partials_builder {
#===================================
    my $self = shift;
    my $m    = $self->model;
    sub {
        map {
            $_->{_partial} ||= do {
                my $uid = Elastic::Model::UID->new_partial($_);
                $m->new_partial_doc(
                    uid            => $uid,
                    partial_source => $_->{_source}
                );
                }
        } @_;
    };
}

#===================================
sub as_results {
#===================================
    my $self = shift;
    $self->wrapper( $self->_as_result );
    $self->multi_wrapper( $self->_as_results );
    $self;
}

#===================================
sub as_objects {
#===================================
    my $self = shift;
    $self->wrapper( $self->_as_object );
    $self->multi_wrapper( $self->_as_objects );
    $self;
}

#===================================
sub as_partials {
#===================================
    my $self = shift;
    $self->wrapper( $self->_as_partial );
    $self->multi_wrapper( $self->_as_partials );
    $self;
}

#===================================
sub first_result     { $_[0]->_as_result->( $_[0]->first_element ) }
sub last_result      { $_[0]->_as_result->( $_[0]->last_element ) }
sub next_result      { $_[0]->_as_result->( $_[0]->next_element ) }
sub prev_result      { $_[0]->_as_result->( $_[0]->prev_element ) }
sub current_result   { $_[0]->_as_result->( $_[0]->current_element ) }
sub peek_next_result { $_[0]->_as_result->( $_[0]->peek_next_element ) }
sub peek_prev_result { $_[0]->_as_result->( $_[0]->peek_prev_element ) }
sub shift_result     { $_[0]->_as_result->( $_[0]->shift_element ) }
sub all_results      { $_[0]->_as_results->( $_[0]->all_elements ) }
#===================================

#===================================
sub slice_results {
#===================================
    my $self = shift;
    $self->_as_results->( $self->slice_elements(@_) );
}

#===================================
sub first_object     { $_[0]->_as_object->( $_[0]->first_element ) }
sub last_object      { $_[0]->_as_object->( $_[0]->last_element ) }
sub next_object      { $_[0]->_as_object->( $_[0]->next_element ) }
sub prev_object      { $_[0]->_as_object->( $_[0]->prev_element ) }
sub current_object   { $_[0]->_as_object->( $_[0]->current_element ) }
sub peek_next_object { $_[0]->_as_object->( $_[0]->peek_next_element ) }
sub peek_prev_object { $_[0]->_as_object->( $_[0]->peek_prev_element ) }
sub shift_object     { $_[0]->_as_object->( $_[0]->shift_element ) }
sub all_objects      { $_[0]->_as_objects->( $_[0]->all_elements ) }
#===================================

#===================================
sub slice_objects {
#===================================
    my $self = shift;
    $self->_as_objects->( $self->slice_elements(@_) );
}

#===================================
sub first_partial     { $_[0]->_as_partial->( $_[0]->first_element ) }
sub last_partial      { $_[0]->_as_partial->( $_[0]->last_element ) }
sub next_partial      { $_[0]->_as_partial->( $_[0]->next_element ) }
sub prev_partial      { $_[0]->_as_partial->( $_[0]->prev_element ) }
sub current_partial   { $_[0]->_as_partial->( $_[0]->current_element ) }
sub peek_next_partial { $_[0]->_as_partial->( $_[0]->peek_next_element ) }
sub peek_prev_partial { $_[0]->_as_partial->( $_[0]->peek_prev_element ) }
sub shift_partial     { $_[0]->_as_partial->( $_[0]->shift_element ) }
sub all_partials      { $_[0]->_as_partials->( $_[0]->all_elements ) }
#===================================

#===================================
sub slice_partials {
#===================================
    my $self = shift;
    $self->_as_partials->( $self->slice_elements(@_) );
}

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Role::Results - An iterator role for search results

=head1 VERSION

version 0.52

=head1 DESCRIPTION

L<Elastic::Model::Role::Results> adds a number of methods and attributes
to those provided by L<Elastic::Model::Role::Iterator> to better handle
result sets from Elasticsearch.  It is used by L<Elastic::Model::Results>,
L<Elastic::Model::Results::Cached> and by L<Elastic::Model::Results::Scrolled>.

See those modules for more complete documentation. This module just
documents the attributes and methods added in L<Elastic::Model::Role::Results>

=head1 ATTRIBUTES

=head2 size

    $size = $results->size

The number of L</elements> in the C<$results> object;

=head2 total

    $total_matching = $results->total

The total number of matching docs found by Elasticsearch.  This is
distinct from the L</size> which contains the number of results RETURNED
by Elasticsearch.

=head2 max_score

    $max_score = $results->max_score

The highest score (relevance) found by Elasticsearch. B<Note:> if you
are sorting by a field other than C<_score> then you will need
to set L<Elastic::Model::View/track_scores> to true to retrieve the
L</max_score>.

=head2 aggs

=head2 agg

    $aggs = $results->aggs
    $agg  = $results->agg($agg_name)

Aggregation results, if any were requested with L<Elastic::Model::View/aggs>.

=head2 facets

=head2 facet

    $facets = $results->facets
    $facet  = $results->facet($facet_name)

Facet results, if any were requested with L<Elastic::Model::View/facets>.

=head2 elements

    \@elements = $results->elements;

An array ref containing all of the data structures that we can iterate over.

=head2 search

    \%search_args = $results->search

Contains the hash ref of the search request passed to
L<Elastic::Model::Role::Store/search()>

=head2 is_partial

    $bool = $result->is_partial

Returns C<true> or C<false> to indicate whether the specified search
returns full or partial results.

=head1 WRAPPERS

=head2 as_results()

    $results = $results->as_results;

Sets the "short" accessors (eg L<Elastic::Model::Role::Iterator/next> or
L<Elastic::Model::Role::Iterator/prev>) to return
L<Elastic::Model::Result> objects.

=head2 as_objects()

    $objects = $objects->as_objects;

Sets the "short" accessors (eg L<Elastic::Model::Role::Iterator/next> or
L<Elastic::Model::Role::Iterator/prev>) to return the object itself,
eg C<MyApp::User>

=head2 as_partials()

    $results->as_partials()

Sets the "short" accessors (eg L<Elastic::Model::Role::Iterator/next> or
L<Elastic::Model::Role::Iterator/prev>) to return partial objects
as specified by L<Elastic::Model::View/"include_paths / exclude_paths">.

=head1 RESULT ACCESSORS

Each of the methods listed below takes the result of the related
C<_element> accessor in L<Elastic::Model::Role::Iterator> and wrap it
in an L<Elastic::Model::Result> object. For instance:

    $result = $results->next_result;

=head2 first_result

=head2 last_result

=head2 next_result

=head2 prev_result

=head2 current_result

=head2 peek_next_result

=head2 peek_prev_result

=head2 shift_result

=head2 all_results

=head2 slice_results

=head1 OBJECT ACCESSORS

Each of the methods listed below takes the result of the related
C<_element> accessor in L<Elastic::Model::Role::Iterator> and inflates the
related object (eg a C<MyApp::User> object). For instance:

    $object = $results->next_object;

=head2 first_object

=head2 last_object

=head2 next_object

=head2 prev_object

=head2 current_object

=head2 peek_next_object

=head2 peek_prev_object

=head2 shift_object

=head2 all_objects

=head2 slice_objects

=head1 PARTIAL OBJECT ACCESSORS

Each of the methods listed below takes the result of the related
C<_element> accessor in L<Elastic::Model::Role::Iterator> and inflates the
related partial object as specified by
L<Elastic::Model::View/"include_paths / exclude_paths">. For instance:

    $object = $results->next_partial;

=head2 first_partial

=head2 last_partial

=head2 next_partial

=head2 prev_partial

=head2 current_partial

=head2 peek_next_partial

=head2 peek_prev_partial

=head2 shift_partial

=head2 all_partials

=head2 slice_partials

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: An iterator role for search results

