package Elastic::Model::SearchBuilder;
$Elastic::Model::SearchBuilder::VERSION = '0.52';
use strict;
use warnings;
use ElasticSearch::SearchBuilder 0.18;
use parent 'ElasticSearch::SearchBuilder';
use Carp;

#===================================
sub _hashpair_ElasticDocREF {
#===================================
    my ( $self, $type, $k, $v ) = @_;
    $self->_uid_to_terms( $type, $k, $v->uid );
}

#===================================
sub _hashpair_ElasticUIDREF {
#===================================
    my ( $self, $type, $k, $v ) = @_;
    $self->_uid_to_terms( $type, $k, $v );
}

#===================================
sub _filter_field_terms {
#===================================
    my ( $self, $k, $op, $val ) = @_;

    return $self->_SWITCH_refkind(
        "Filter field operator -$op",
        $val,
        {   ElasticDocREF =>
                sub { $self->_uid_to_terms( 'filter', $k, $val->uid ) },
            ElasticUIDREF =>
                sub { $self->_uid_to_terms( 'filter', $k, $val ) },
            FALLBACK => sub {
                $self->SUPER::_filter_field_terms( $k, $op, $val );
            },
        }
    );
}

#===================================
sub _query_field_match {
#===================================
    my $self = shift;
    my ( $k, $op, $val ) = @_;

    return $self->_SWITCH_refkind(
        "Query field operator -$op",
        $val,
        {   ElasticDocREF =>
                sub { $self->_uid_to_terms( 'query', $k, $val->uid ) },
            ElasticUIDREF =>
                sub { $self->_uid_to_terms( 'query', $k, $val ) },
            FALLBACK => sub {
                $self->SUPER::_query_field_match( $k, $op, $val );
            },
        }
    );
}

#===================================
sub _uid_to_terms {
#===================================
    my ( $self, $type, $k, $uid ) = @_;
    my @clauses;
    for (qw(index type id)) {
        my $val = $uid->$_ or croak "UID missing ($_)";
        push @clauses, { term => { "${k}.uid.$_" => $val } };
    }
    return $type eq 'query'
        ? { bool => { must => \@clauses } }
        : { and => \@clauses }

}

#===================================
sub _refkind {
#===================================
    my ( $self, $data ) = @_;

    return 'UNDEF' unless defined $data;

    my $ref
        = !Scalar::Util::blessed($data)            ? ref $data
        : !$data->can('does')                      ? ''
        : $data->does('Elastic::Model::Role::Doc') ? 'ElasticDoc'
        : $data->isa('Elastic::Model::UID')        ? 'ElasticUID'
        :                                            '';

    return 'SCALAR' unless $ref;

    my $n_steps = 1;
    while ( $ref eq 'REF' ) {
        $data = $$data;
        $ref
            = !Scalar::Util::blessed($data)            ? ref $data
            : !$data->can('does')                      ? ''
            : $data->does('Elastic::Model::Role::Doc') ? 'ElasticDoc'
            : $data->isa('Elastic::Model::UID')        ? 'ElasticUID'
            :                                            '';
        $n_steps++ if $ref;
    }

    return ( $ref || 'SCALAR' ) . ( 'REF' x $n_steps );
}

1;

# ABSTRACT: An Elastic::Model specific subclass of L<ElasticSearch::SearchBuilder>

__END__

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::SearchBuilder - An Elastic::Model specific subclass of L<ElasticSearch::SearchBuilder>

=head1 VERSION

version 0.52

=head1 DESCRIPTION

L<Elastic::Model::SearchBuilder> is a sub-class of L<ElasticSearch::SearchBuilder>
to add automatic handling of L<Elastic::Doc> and L<Elastic::Model::UID>
values.

This document just explains the functionality that
L<Elastic::Model::SearchBuilder> adds.

B<For the full SearchBuilder docs, see L<ElasticSearch::SearchBuilder>>.

=head1 THE PROBLEM

Consider this class (where C<MyApp::User> is also an
L<Elastic::Doc> class):

    package MyApp::Comment;

    use Elastic::Doc;

    has 'user' => (
        is     => 'ro',
        isa    => 'MyApp::User,
    );

    has 'text' => (
        is     => 'ro',
        isa    => 'Str',
    );

We can create a comment as follows:

    $domain->create(
        comment => {
            text => 'I like Elastic::Model',
            user => $user,
        }
    );

The C<comment> object would be stored in Elasticsearch as something like this:

    {
        text    => "I like Elastic::Model",
        user    => {
            uid => {
                index   => 'myapp',
                type    => 'user',
                id      => 'abcdefg',
            },
            .... any other user fields....
        }
    }

In order to search for any comments by user C<$user>, you would need to do this:

    $view->type('comment')
         ->filterb(
                'user.uid.index' => $user->uid->index,
                'user.uid.type'  => $user->uid->type,
                'user.uid.id'    => $user->uid->id,
           )
         ->search;

=head1 THE SOLUTION

With L<Elastic::Model::SearchBuilder>, you can do it as follows:

    $view->type('comment')
         ->filterb( user => $user )
         ->search;

Or with the C<UID>:

    $view->type('comment')
         ->filterb( user => $user->uid )
         ->search;

=head1 FURTHER EXAMPLES

=head2 Query or Filter

This works for both queries and filters, eg:

    $view->queryb ( user => $user )->search;
    $view->filterb( user => $user )->search;

=head2 Doc or UID

You can use either the doc/object itself, or an L<Elastic::Model::UID> object:

    $uid = $user->uid;
    $view->queryb ( user => $uid )->search;
    $view->filterb( user => $uid )->search;

=head2 Negating queries:

    $view->queryb ( user => { '!=' => $user })->search;
    $view->filterb( user => { '!=' => $user })->search;

=head2 "IN" queries

    $view->queryb ( user => \@users )->search;
    $view->filterb( user => \@users )->search;

=head2 "NOT IN" queries

    $view->queryb ( user => { '!=' => \@users })->search;
    $view->filterb( user => { '!=' => \@users })->search;

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
