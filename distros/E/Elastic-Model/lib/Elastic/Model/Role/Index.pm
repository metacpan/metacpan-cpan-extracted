package Elastic::Model::Role::Index;
$Elastic::Model::Role::Index::VERSION = '0.52';
use Moose::Role;
use MooseX::Types::Moose qw(Str);
use Carp;

use namespace::autoclean;

#===================================
has 'name' => (
#===================================
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#===================================
has 'namespace' => (
#===================================
    is      => 'ro',
    isa     => 'Elastic::Model::Namespace',
    handles => [ 'model', 'mappings' ]
);

no Moose::Role;

#===================================
sub index_config {
#===================================
    my ( $self, %args ) = @_;
    my %settings = %{ $args{settings} || {} };

    my @types    = @{ $args{types} || [] };
    my $mappings = $self->mappings(@types);
    my $meta     = Class::MOP::class_of( $self->model );
    if ( my $analysis = $meta->analysis_for_mappings($mappings) ) {
        $settings{analysis} = $analysis;
    }

    return {
        index    => $self->name,
        settings => \%settings,
        mappings => $mappings
    };
}

#===================================
sub delete  { shift->_index_action( 'delete_index',  @_ ) }
sub refresh { shift->_index_action( 'refresh_index', @_ ) }
sub open    { shift->_index_action( 'open_index',    @_ ) }
sub close   { shift->_index_action( 'close_index',   @_ ) }
sub exists { !!$_[0]->model->store->index_exists( index => $_[0]->name ) }
#===================================

#===================================
sub _index_action {
#===================================
    my $self   = shift;
    my $action = shift;
    my %args   = @_;
    $self->model->store->$action( %args, index => $self->name );
    return $self;
}

#===================================
sub update_settings {
#===================================
    my $self = shift;
    $self->model->store->update_index_settings(
        index    => $self->name,
        settings => {@_}
    );
    return $self;
}

#===================================
sub update_analyzers {
#===================================
    my $self   = shift;
    my $params = $self->index_config(@_);
    delete $params->{mappings};
    $self->model->store->update_index_settings(%$params);
    return $self;
}

#===================================
sub is_alias {
#===================================
    my $self    = shift;
    my $name    = $self->name;
    my $indices = $self->model->store->get_aliases( index => $name );
    return !!( %$indices && !$indices->{$name} );
}

#===================================
sub is_index {
#===================================
    my $self    = shift;
    my $name    = $self->name;
    my $indices = $self->model->store->get_aliases( index => $name );
    return !!$indices->{$name};
}

#===================================
sub update_mapping {
#===================================
    my $self     = shift;
    my %args     = ref $_[-1] eq 'HASH' ? %{ pop() } : ();
    my $mappings = $self->mappings(@_);
    my $store    = $self->model->store;
    my $name     = $self->name;
    for my $type ( keys %$mappings ) {
        $store->put_mapping(
            index   => $name,
            type    => $type,
            mapping => $mappings->{$type},
            %args,
        );
    }
    return $self;
}

#===================================
sub delete_mapping {
#===================================
    my $self  = shift;
    my %args  = ref $_[-1] eq 'HASH' ? %{ pop() } : ();
    my $store = $self->model->store;
    my $name  = $self->name;
    $store->delete_mapping( index => $name, type => $_, %args ) for @_;
    return $self;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Role::Index - Provides admin methods common to indices and aliases

=head1 VERSION

version 0.52

=head1 SYNOPSIS

    $admin->close();
    $admin->open();
    $admin->delete();
    $admin->refresh();

    $admin->update_mapping(@types);
    $admin->delete_mapping(@types);

    $admin->update_analyzers();
    $admin->update_settings(%settings);

    $bool = $admin->is_alias;
    $bool = $admin->is_index;
    $bool = $admin->exists;

=head1 DESCRIPTION

L<Elastic::Model::Role::Index> is a role which provides admin methods
common to indices and aliases.  It is consumed by L<Elastic::Model::Index>
and L<Elastic::Model::Alias>.

See L<Elastic::Manual::Scaling> for more about how domains, indices and aliases
relate to each other.

=head1 ATTRIBUTES

=head2 name

    $name = $admin->name;

The name of the index or alias to be administered. This defaults to the
L<name|Elastic::Model::Namespace/name>
of the L</namespace> but can be overridden when creating a new
L<Elastic::Model::Index> or L<Elastic::Model::Alias> object, eg:

    $index = $namesapace->index('index_name')

=head2 namespace

The L<Elastic::Model::Namespace> object used to create the
L<Elastic::Model::Index> or L<Elastic::Model::Alias> object.

=head2 es

The same L<Search::Elasticsearch> connection as L<Elastic::Model::Role::Model/es>.

=head1 METHODS

=head2 delete()

    $admin = $admin->delete();
    $admin = $admin->delete( %args );

Deletes the index (or indices pointed to by alias ) L</name>. Any
C<%args> are passed directly to L<Search::Elasticsearch::Client::Direct::Indices/delete()>.
For example:

    $admin->delete( ignore => 404 );

=head2 refresh()

    $admin = $admin->refresh();

Forces the the index (or indices pointed to by alias ) L</name> to be refreshed,
ie all changes to the docs in the index become visible to search.  By default,
indices are refreshed once every second anyway. You shouldn't abuse this option
as it will have a performance impact.

=head2 open()

    $admin = $admin->open();

Opens the index (or the SINGLE index pointed to by alias ) L</name>.

=head2 close()

    $admin = $admin->close();

Closes the index (or the SINGLE index pointed to by alias ) L</name>.

=head2 index_config()

    $config = $admin->index_config( settings=> \%settings, types=> \@types );

Returns a hashref containing the index/alias L</name>, the settings, and the
mappings for the current namespace.  The generated analysis settings are merged
into any C<%settings> that you provide. Mappings and analysis settings will be
for all C<@types> known to the L</namespace> unless specified.

This method is used by L</update_analyzers()> and
L<Elastic::Model::Index/create_index()>.

=head2 update_settings()

    $admin = $admin->update_settings( %settings );

Updates the L<index settings|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/indices-update-settings.html>
for the the index (or indices pointed to by alias ) L</name>.

For example, if you want to rebuild an index, you could disable refresh
until you are finished indexing:

    $admin->update_settings( refresh_interval => -1 );
    populate_index();
    $admin->update_settings( refresh_interval => '1s' );

=head2 update_analyzers()

    $admin = $admin->update_analyzers( types => \@types );

Mostly, analyzers can't be changed on an existing index, but new analyzers
can be added.  L</update_analyzers()> will generate a new analyzer configuration
and try to update index (or the indices pointed to by alias) L</name>.

You can limit the analyzers to those required for a specific list of C<@types>,
otherwise it calculates the analyzer configuration for all types known to the
L</namespace>.

=head2 update_mapping()

    $admin = $admin->update_mapping();
    $admin = $admin->update_mapping( @type_names );
    $admin = $admin->update_mapping( @type_names, { ignore_conflicts=> 1 } );

Type mappings B<cannot be changed> on an existing index, but they B<can be
added to>.  L</update_mapping()> will generate a new type mapping from your
doc classes, and try to update index (or the indices pointed to by alias)
L</name>.

You can optionally specify a list of types to update, otherwise it will
update all types known to the L</namespace>.

    $admin->update_mapping( 'user','post');

Any optional args passed
as a hashref as the final parameter will be passed to
L<Search::Elasticsearch::Client::Direct::Indices/put_mapping()>

=head2 delete_mapping();

    $admin = $admin->delete_mapping( @types );
    $admin = $admin->delete_mapping( @types, { ignore => 404 });

Deletes the type mapping B<AND THE DOCUMENTS> for the listed types in the index
(or the indices pointed to by alias) L</name>. Any optional args passed
as a hashref as the final parameter will be passed to
L<Search::Elasticsearch::Client::Direct::Indices/delete_mapping()>.

=head2 exists()

    $bool = $admin->exists();

Checks whether the index (or ALL the indices pointed to by alias ) L</name>
exist.

=head2 is_alias()

    $bool = $admin->is_alias();

Returns true if L</name> is an alias.

=head2 is_index()

    $bool = $admin->is_index();

Returns true if L</name> is an index.

=head1 SEE ALSO

=over

=item *

L<Elastic::Model::Index>

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

# ABSTRACT: Provides admin methods common to indices and aliases

