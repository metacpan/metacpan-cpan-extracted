use utf8;
package HTML::Tabulate::Schema::Result::EmpTabulate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTML::Tabulate::Schema::Result::EmpTabulate

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<emp_tabulate>

=cut

__PACKAGE__->table("emp_tabulate");

=head1 ACCESSORS

=head2 emp_id

  data_type: 'integer unsigned auto_increment'
  is_nullable: 0

=head2 emp_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 emp_title

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 emp_birth_dt

  data_type: 'date'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "emp_id",
  { data_type => "integer unsigned auto_increment", is_nullable => 0 },
  "emp_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "emp_title",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "emp_birth_dt",
  { data_type => "date", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</emp_id>

=back

=cut

__PACKAGE__->set_primary_key("emp_id");


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2013-04-25 13:02:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/RjzMMv+IzWqUJ6+9tVG9A

# Relationships

# Join to self
__PACKAGE__->has_one('self_join', 'HTML::Tabulate::Schema::Result::EmpTabulate', 'emp_id');

# Additional methods

sub name {
  my $self = shift;
  uc $self->emp_name;
}

1;
