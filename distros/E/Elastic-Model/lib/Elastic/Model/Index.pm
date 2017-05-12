package Elastic::Model::Index;
$Elastic::Model::Index::VERSION = '0.52';
use Carp;
use Moose;
with 'Elastic::Model::Role::Index';

use namespace::autoclean;

no Moose;

#===================================
sub create {
#===================================
    my $self   = shift;
    my $params = $self->index_config(@_);
    $self->model->store->create_index(%$params);
    return $self;
}

#===================================
sub reindex {
#===================================
    my $self   = shift;
    my $domain = shift
        or croak "No (domain) passed to reindex()";

    my %args       = ( repoint_uids => 1, @_ );
    my $verbose    = !$args{quiet};
    my $scan       = $args{scan} || '2m';
    my $size       = $args{size} || 1000;
    my $bulk_size  = $args{bulk_size} || $size;
    my $dest_index = $self->name;
    my $model      = $self->model;
    my $transform  = $args{transform} || sub {@_};

    printf "Reindexing domain ($domain) to index ($dest_index)\n" if $verbose;

    if ( $self->exists ) {
        print "Index ($dest_index) already exists.\n" if $verbose;
    }
    else {
        print "Creating index ($dest_index)\n" if $verbose;
        $self->create();
    }

    # store all changed UIDs so that we can repoint them
    # later, when they're used in docs that aren't being reindexed
    my %uids;
    my $doc_updater = sub {
        my ($doc) = $transform->(@_);
        $uids{ $doc->{_index} }{ $doc->{_type} }{ $doc->{_id} } = 1;
        $doc->{_index} = $dest_index;
        return $doc;
    };

    # Map all indices that 'domain' points to, to $index->name
    my $old = $model->domain($domain)->namespace->alias($domain);
    my %map
        = map { $_ => 1 } $old->is_alias
        ? keys %{ $old->aliased_to }
        : ($domain);

    my $uid_updater = sub {
        my $uid = shift;
        $uid->{index} = $dest_index
            if $map{ $uid->{index} };
    };

    my $updater = $self->doc_updater( $doc_updater, $uid_updater );

    my $source = $model->view->domain($domain)->size($size)->scan($scan);
    $model->store->reindex(
        source      => sub { $source->shift_element },
        verbose     => $verbose,
        transform   => $updater,
        bulk_size   => $bulk_size,
        on_conflict => $args{on_conflict},
        on_error    => $args{on_error},
    );

    return 1 unless $args{repoint_uids};

    $self->repoint_uids(
        uids        => \%uids,
        verbose     => $verbose,
        exclude     => [ keys %map ],
        size        => $size,
        bulk_size   => $bulk_size,
        scan        => $scan,
        on_conflict => $args{uid_on_conflict},
        on_error    => $args{uid_on_error},
    );
}

#===================================
sub repoint_uids {
#===================================
    my ( $self, %args ) = @_;

    my $verbose    = $args{verbose};
    my $scan       = $args{scan} || '2m';
    my $size       = $args{size} || 1000;
    my $bulk_size  = $args{bulk_size} || $size;
    my $model      = $self->model;
    my $index_name = $self->name;
    my $uids       = $args{uids} || {};

    unless (%$uids) {
        print "No UIDs to repoint\n" if $verbose;
        return 1;
    }

    my %exclude = map { $_ => 1 } ( $index_name, @{ $args{exclude} || [] } );
    my @indices = grep { not $exclude{$_} } $model->all_live_indices;

    unless (@indices) {
        print "No UIDs to repoint\n" if $verbose;
        return 1;
    }

    my @uid_attrs = $self->_uid_attrs_for_indices(@indices);
    unless (@uid_attrs) {
        print "No UIDs to repoint\n" if $verbose;
        return 1;
    }

    my $view = $model->view->domain( \@indices )->size($size);

    my $doc_updater = sub {
        my $doc = shift;
        $doc->{_version}++;
        return $doc;
    };

    my %map;
    my $uid_updater = sub {
        my $uid = shift;
        return unless $uids->{ $uid->{index} }{ $uid->{type} }{ $uid->{id} };
        $uid->{index} = $index_name;
    };

    my $updater = $self->doc_updater( $doc_updater, $uid_updater );

    for my $index ( keys %$uids ) {
        my $types = $uids->{$index};
        for my $type ( keys %$types ) {
            my @ids = keys %{ $types->{$type} };

            printf( "Repointing %d UIDs from %s/%s\n",
                0 + @ids, $index, $type )
                if $verbose;

            while (@ids) {

                my $clauses
                    = $self->_build_uid_clauses( \@uid_attrs, $index, $type,
                    [ splice @ids, 0, $size ] );

                my $source = $view->filter( or => $clauses )->scan($scan);
                $model->store->reindex(
                    source => sub {
                        $source->shift_element;
                    },
                    bulk_size   => $bulk_size,
                    quiet       => 1,
                    transform   => $updater,
                    on_conflict => $args{on_conflict},
                    on_error    => $args{on_error},
                );
            }
            print "\n" if $verbose;
        }
    }

    print "\nDone\n" if $verbose;
    return 1;
}

#===================================
sub _uid_attrs_for_indices {
#===================================
    my $self    = shift;
    my @indices = @_;
    my $mapping = $self->model->store->get_mapping( index => \@indices );
    my %attrs   = map { $_ => 1 }
        map { _find_uid_attrs( $_->{properties} ) }
        map { values %{ $_->{mappings} } } values %$mapping;
    return keys %attrs;

}

#===================================
sub _find_uid_attrs {
#===================================
    my ( $mapping, $level ) = @_;

    my @attrs;
    $level = '' unless $level;

    keys %$mapping;
    while ( my ( $k, $v ) = each %$mapping ) {
        next unless $v->{properties};
        my $attr = $level ? "$level.$k" : $k;

        if ( $k eq 'uid' and $v->{properties} and $v->{properties}{index} ) {
            push @attrs, $attr;
            next;
        }
        push @attrs, _find_uid_attrs( $v->{properties} || {}, $attr );
    }
    return @attrs;
}

#===================================
sub _build_uid_clauses {
#===================================
    my ( $self, $uid_attrs, $index, $type, $ids ) = @_;
    my @clauses;
    for my $id (@$ids) {
        push @clauses, map {
            +{  and => [
                    { term => { "$_.index" => $index } },
                    { term => { "$_.type"  => $type } },
                    { term => { "$_.id"    => $id } }
                ]
                }
        } @$uid_attrs;
    }
    return \@clauses;
}

#===================================
sub doc_updater {
#===================================
    my ( $self, $doc_updater, $uid_updater ) = @_;
    return sub {
        my $doc   = $doc_updater->(@_);
        my @stack = values %{ $doc->{_source} };

        while ( my $val = shift @stack ) {
            unless ( ref $val eq 'HASH' ) {
                push @stack, @$val if ref $val eq 'ARRAY';
                next;
            }
            my $uid = $val->{uid};
            if (    $uid
                and ref $uid eq 'HASH'
                and $uid->{index}
                and $uid->{type} )
            {
                $uid_updater->($uid);
            }
            else {
                push @stack, values %$val;
            }
        }
        return $doc;
    };
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Index - Create and administer indices in Elasticsearch

=head1 VERSION

version 0.52

=head1 SYNOPSIS

    $index = $model->namespace('myapp')->index;
    $index = $model->namespace('myapp')->index('index_name');

    $index->create( settings => \%settings );

    $index->reindex( 'old_index' );

See also L<Elastic::Model::Role::Index/SYNOPSIS>.

=head1 DESCRIPTION

L<Elastic::Model::Index> objects are used to create and administer indices
in an Elasticsearch cluster.

See L<Elastic::Model::Role::Index> for more about usage.
See L<Elastic::Manual::Scaling> for more about how indices can be used in your
application.

=head1 METHODS

=head2 create()

    $index = $index->create();
    $index = $index->create( settings => \%settings, types => \@types );

Creates an index called L<name|Elastic::Role::Model::Index/name> (which
defaults to C<< $namespace->name >>).

The L<type mapping|Elastic::Manual::Terminology/Mapping> is automatically
generated from the attributes of your doc classes listed in the
L<namespace|Elastic::Model::Namespace>.  Similarly, any
L<custom analyzers|Elastic::Model/"Custom analyzers"> required
by your classes are added to the index
L<\%settings|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/indices-update-settings.html>
that you pass in:

    $index->create( settings => {number_of_shards => 1} );

To create an index with a sub-set of the types known to the
L<namespace|Elastic::Model::Namespace>, pass in a list of C<@types>.

    $index->create( types => ['user','post' ]);

=head2 reindex()

    # reindex $domain_name to $index->name
    $index->reindex( $domain_name );

    # more options
    $index->reindex(
        $domain,

        repoint_uids    => 1,
        size            => 1000,
        bulk_size       => 1000,
        scan            => '2m',
        quiet           => 0,

        transform       => sub {...},

        on_conflict     => sub {...} | 'IGNORE'
        on_error        => sub {...} | 'IGNORE'
        uid_on_conflict => sub {...} | 'IGNORE'
        uid_on_error    => sub {...} | 'IGNORE'
    );

While you can add to the L<mapping|Elastic::Manual::Terminology/Mapping> of
an index, you can't change what is already there. Especially during development,
you will need to reindex your data to a new index.

L</reindex()> reindexes your data from L<domain|Elastic::Manual::Terminology/Domain>
C<$domain_name> into an index called C<< $index->name >>. The new index is
created if it doesn't already exist.

See L<Elastic::Manual::Reindex> for more about reindexing strategies. The
documentation below explains what each parameter does:

=over

=item size

The C<size> parameter defaults to 1,000 and controls how many documents
are pulled from C<$domain> in each request.  See L<Elastic::Model::View/size>.

B<Note:> documents are pulled from the C<domain>/C<view> using
L<Elastic::Model::View/scan()>, which can pull a maximum of
L<size|Elastic::Model::View/size> C<* number_of_primary_shards> in a single
request.  If you have large docs or underpowered servers, you may want to
change the C<size> parameter.

=item bulk_size

The C<bulk_size> parameter defaults to C<size> and controls how many documents
are indexed into the new domain in a single bulk-indexing request.

=item scan

C<scan> is the same as L<Elastic::Model::View/scan> - it controls how long
Elasticsearch should keep the "scroll" live between requests.  Defaults to
'2m'.  Increase this if the reindexing process is slow and you get
scroll timeouts.

=item repoint_uids

If true (the default), L</repoint_uids()> will be called automatically to
update any L<UIDs|Elastic::Model::UID> (which point at the old index) in
indices other than the ones currently being reindexed.

=item transform

If you need to change the structure/data of your doc while reindexing, you
can pass a C<transform> coderef.  This will be called before any changes
have been made to the doc, and should return the new doc. For instance,
to convert the single-value C<tag> field to an array of C<tags>:

    $index->reindex(
        'new_index',
        'transform' => sub {
            my $doc = shift;
            $doc->{_source}{tags} = [ delete $doc->{_source}{tag} ];
            return $doc
        }
    );

=item on_conflict / on_error

If you are indexing to the new index at the same time as you
are reindexing, you may get document conflicts.  You can handle the conflicts
with a coderef callback, or ignore them by by setting C<on_conflict> to
C<'IGNORE'>:

    $index->reindex( 'myapp_v2', on_conflict => 'IGNORE' );

Similarly, you can pass an C<on_error> handler which will handle other errors,
or all errors if no C<on_conflict> handler is defined.

See L<Search::Elasticsearch::Bulk/Using-callbacks> for more.

=item uid_on_conflict / uid_on_error

These work in the same way as the C<on_conflict> or C<on_error> handlers,
but are passed to L</repoint_uids()> if C<repoint_uids> is true.

=item quiet

By default, L</reindex()> prints out progress information.  To silence this,
set C<quiet> to true:

    $index->reindex( 'myapp_v2', quiet   => 1 );

=back

=head2 repoint_uids()

    $index->repoint_uids(
        uids        => [ ['myapp_v1','user',10],['myapp_v1','user',12]...],
        exclude     => ['myapp_v2'],
        scan        => '2m',
        size        => 1000,
        bulk_size   => 1000,
        quiet       => 0,

        on_conflict => sub {...} | 'IGNORE'
        on_error    => sub {...} | 'IGNORE'
    );

The purpose of L</repoint_uids()> is to update stale L<UID|Elastic::Model::UID>
attributes to point to a new index. It is called automatically from
L</reindex()>.

Parameters:

=over

=item uids

C<uids> is a hash ref the stale L<UIDs|Elastic::Model::UID> which should be
updated.

For instance: you have reindexed C<myapp_v1> to C<myapp_v2>, but domain
C<other> has documents with UIDs which point to C<myapp_v1>. You
can updated these by passing a list of the old UIDs, as follows:

    $index = $namespace->index('myapp_v2');
    $index->repoint_uids(
        uids    => {                        # index
            myapp_v1 => {                   # type
                user => {
                    1 => 1,                 # ids
                    2 => 1,
                }
            }
        }
    );

=item exclude

By default, all indices known to the L<model|Elastic::Model::Role::Model> are
updated. You can exclude indices with:

    $index->repoint_uids(
        uids    => \@uids,
        exclude => ['index_1', ...]
    );

=item size

This is the same as the C<size> parameter to L</reindex()>.

=item bulk_size

This is the same as the C<bulk_size> parameter to L</reindex()>.

=item scan

This is the same as the C<scan> parameter to L</reindex()>.

=item quiet

This is the same as the C<quiet> parameter to L</reindex()>.

=item on_conflict / on_error

These are the same as the C<uid_on_conflict> and C<uid_on_error> handlers
in L</reindex()>.

=back

=head2 doc_updater()

    $coderef = $index->doc_updater( $doc_updater, $uid_updater );

L</doc_updater()> is used by L</reindex()> and L</repoint_uids()> to update
the top-level doc and any UID attributes with callbacks.

The C<$doc_updater> receives the C<$doc> as its only attribute, and should
return the C<$doc> after making any changes:

    $doc_updater = sub {
        my ($doc) = @_;
        $doc->{_index} = 'foo';
        return $doc
    };

The C<$uid_updater> receives the UID as its only attribute:

    $uid_updater = sub {
        my ($uid) = @_;
        $uid->{index} = 'foo'
    };

=head1 IMPORTED ATTRIBUTES

Attributes imported from L<Elastic::Model::Role::Index>

=head2 L<namespace|Elastic::Model::Role::Index/namespace>

=head2 L<name|Elastic::Model::Role::Index/name>

=head1 IMPORTED METHODS

Methods imported from L<Elastic::Model::Role::Index>

=head2 L<close()|Elastic::Model::Role::Index/close()>

=head2 L<open()|Elastic::Model::Role::Index/open()>

=head2 L<refresh()|Elastic::Model::Role::Index/refresh()>

=head2 L<delete()|Elastic::Model::Role::Index/delete()>

=head2 L<update_analyzers()|Elastic::Model::Role::Index/update_analyzers()>

=head2 L<update_settings()|Elastic::Model::Role::Index/update_settings()>

=head2 L<delete_mapping()|Elastic::Model::Role::Index/delete_mapping()>

=head2 L<is_alias()|Elastic::Model::Role::Index/is_alias()>

=head2 L<is_index()|Elastic::Model::Role::Index/is_index()>

=head1 SEE ALSO

=over

=item *

L<Elastic::Model::Role::Index>

=item *

L<Elastic::Model::Alias>

=item *

L<Elastic::Model::Namespace>

=item *

L<Elastic::Manual::Scaling>

=back

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Create and administer indices in Elasticsearch

