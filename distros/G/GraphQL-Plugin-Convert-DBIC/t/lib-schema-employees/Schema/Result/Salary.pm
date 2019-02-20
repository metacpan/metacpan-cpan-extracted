use utf8;
package Schema::Result::Salary;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::Salary

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<salaries>

=cut

__PACKAGE__->table("salaries");

=head1 ACCESSORS

=head2 emp_no

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 salary

  data_type: 'integer'
  is_nullable: 0

=head2 from_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 to_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "emp_no",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "salary",
  { data_type => "integer", is_nullable => 0 },
  "from_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "to_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</emp_no>

=item * L</from_date>

=back

=cut

__PACKAGE__->set_primary_key("emp_no", "from_date");

=head1 RELATIONS

=head2 emp_no

Type: belongs_to

Related object: L<Schema::Result::Employee>

=cut

__PACKAGE__->belongs_to(
  "emp_no",
  "Schema::Result::Employee",
  { emp_no => "emp_no" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-02-20 11:39:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WnX3M4zyDhVgs429XG7Ckg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
