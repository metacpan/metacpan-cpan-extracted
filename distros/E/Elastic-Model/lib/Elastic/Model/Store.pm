package Elastic::Model::Store;
$Elastic::Model::Store::VERSION = '0.52';
use Moose;
with 'Elastic::Model::Role::Store';
use namespace::autoclean;

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Store - A default implementation of the Elasticsearch backend

=head1 VERSION

version 0.52

=head1 DESCRIPTION

This is an empty class which provides the default implementation of
the Elasticsearch backend as implemented in L<Elastic::Model::Role::Store>.

=head1 IMPORTED ATTRIBUTES

=head2 L<es|Elastic::Model::Role::Store/es>

=head1 IMPORTED METHODS

=head2 L<get_doc()|Elastic::Model::Role::Store/get_doc()>

=head2 L<doc_exists()|Elastic::Model::Role::Store/doc_exists()>

=head2 L<create_doc()|Elastic::Model::Role::Store/create_doc()>

=head2 L<index_doc()|Elastic::Model::Role::Store/index_doc()>

=head2 L<delete_doc()|Elastic::Model::Role::Store/delete_doc()>

=head2 L<bulk()|Elastic::Model::Role::Store/bulk()>

=head2 L<search()|Elastic::Model::Role::Store/search()>

=head2 L<scrolled_search()|Elastic::Model::Role::Store/scrolled_search()>

=head2 L<delete_by_query()|Elastic::Model::Role::Store/delete_by_query()>

=head2 L<index_exists()|Elastic::Model::Role::Store/index_exists()>

=head2 L<create_index()|Elastic::Model::Role::Store/create_index()>

=head2 L<delete_index()|Elastic::Model::Role::Store/delete_index()>

=head2 L<refresh_index()|Elastic::Model::Role::Store/refresh_index()>

=head2 L<open_index()|Elastic::Model::Role::Store/open_index()>

=head2 L<close_index()|Elastic::Model::Role::Store/close_index()>

=head2 L<update_index_settings()|Elastic::Model::Role::Store/update_index_settings()>

=head2 L<get_aliases()|Elastic::Model::Role::Store/get_aliases()>

=head2 L<put_aliases()|Elastic::Model::Role::Store/put_aliases()>

=head2 L<get_mapping()|Elastic::Model::Role::Store/get_mapping()>

=head2 L<put_mapping()|Elastic::Model::Role::Store/put_mapping()>

=head2 L<delete_mapping()|Elastic::Model::Role::Store/delete_mapping()>

=head2 L<reindex()|Elastic::Model::Role::Store/reindex()>

=head2 L<bootstrap_uniques()|Elastic::Model::Role::Store/bootstrap_uniques()>

=head2 L<create_unique_keys()|Elastic::Model::Role::Store/create_unique_keys()>

=head2 L<delete_unique_keys()|Elastic::Model::Role::Store/delete_unique_keys()>

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A default implementation of the Elasticsearch backend

