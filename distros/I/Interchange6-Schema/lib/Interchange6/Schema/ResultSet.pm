package Interchange6::Schema::ResultSet;

=head1 NAME

Interchange6::Schema::ResultSet - the default resultset class for Interchange6

=cut

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

=head1 DESCRIPTION

This is the default resultset class from which all custom ResultSet classes
should inherit.

It is defined as the default resultset class in L<Interchange6::Schema>.
We use this class to load components that we want to make available to all
of our resultsets. Current the following components are loaded:

=over

=item * L<DBIx::Class::Helper::ResultSet::CorrelateRelationship>

=item * L<DBIx::Class::Helper::ResultSet::Me>

=item * L<DBIx::Class::Helper::ResultSet::Random>

=item * L<DBIx::Class::Helper::ResultSet::SetOperations>

=item * L<DBIx::Class::Helper::ResultSet::Shortcut>

=back

=cut
 
__PACKAGE__->load_components(
    'Helper::ResultSet::CorrelateRelationship',
    'Helper::ResultSet::Me',
    'Helper::ResultSet::Random',
    'Helper::ResultSet::SetOperations',
    'Helper::ResultSet::Shortcut'
);
 
1;
