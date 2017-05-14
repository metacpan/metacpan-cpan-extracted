package Hopkins::Store::Schema;

use strict;

=head1 NAME

Hopkins::Schema - DBIx::Class schema for Hopkins

=head1 DESCRIPTION

Hopkins consists of the following object classes:

Hopkins::Task

=cut

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces(result_namespace => 'Row');

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

=cut

1;
