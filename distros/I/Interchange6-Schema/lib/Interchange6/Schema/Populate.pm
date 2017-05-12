package Interchange6::Schema::Populate;

=head1 NAME

Interchange6::Schema::Populate - populates a website with various fixtures

=cut

use Moo;
with 'Interchange6::Schema::Populate::CountryLocale',
  'Interchange6::Schema::Populate::MessageType',
  'Interchange6::Schema::Populate::Role',
  'Interchange6::Schema::Populate::StateLocale',
  'Interchange6::Schema::Populate::Zone';
#  'Interchange6::Schema::Populate::Currency',

=head1 ATTRIBUTES

=head2 schema

A connected schema. Required.

=cut

has schema => (
    is => 'ro',
    required => 1,
);

=head1 METHODS

=head2 populate

The following classes are populated:

=over

=item * L<Interchange6::Schema::Result::Country>

See: L<Interchange6::Schema::Populate::CountryLocale>

#=item * L<Interchange6::Schema::Result::Currency>
#
#See: L<Interchange6::Schema::Populate::Currency>

=item * L<Interchange6::Schema::Result::MessageType>

See: L<Interchange6::Schema::Populate::MessageType>

=item * L<Interchange6::Schema::Result::Role>

See: L<Interchange6::Schema::Populate::Role>

=item * L<Interchange6::Schema::Result::State>

See: L<Interchange6::Schema::Populate::StateLocale>

=item * L<Interchange6::Schema::Result::Zone>

See: L<Interchange6::Schema::Populate::Zone>

=back

=cut

sub populate {
    my $self = shift;
    $self->populate_countries;
#    $self->populate_currencies;
    $self->populate_message_types;
    $self->populate_roles;
    $self->populate_states;
    $self->populate_zones;
};

1;
