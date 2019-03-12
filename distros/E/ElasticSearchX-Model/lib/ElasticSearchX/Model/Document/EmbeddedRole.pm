#
# This file is part of ElasticSearchX-Model
#
# This software is Copyright (c) 2019 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package ElasticSearchX::Model::Document::EmbeddedRole;
$ElasticSearchX::Model::Document::EmbeddedRole::VERSION = '2.0.1';
# Mark a Document class for use as an embedded object only
# Classes which do this role will not create their own mapping
# in Elasticsearch

use Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ElasticSearchX::Model::Document::EmbeddedRole

=head1 VERSION

version 2.0.1

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
