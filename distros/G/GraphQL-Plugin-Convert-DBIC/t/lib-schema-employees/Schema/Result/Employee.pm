use utf8;
package Schema::Result::Employee;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::Employee

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<employees>

=cut

__PACKAGE__->table("employees");

=head1 ACCESSORS

=head2 emp_no

  data_type: 'integer'
  is_nullable: 0

=head2 birth_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 first_name

  data_type: 'varchar'
  is_nullable: 0
  size: 14

=head2 last_name

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 gender

  data_type: 'enum'
  extra: {list => ["M","F"]}
  is_nullable: 0

=head2 hire_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "emp_no",
  { data_type => "integer", is_nullable => 0 },
  "birth_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "first_name",
  { data_type => "varchar", is_nullable => 0, size => 14 },
  "last_name",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "gender",
  { data_type => "enum", extra => { list => ["M", "F"] }, is_nullable => 0 },
  "hire_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</emp_no>

=back

=cut

__PACKAGE__->set_primary_key("emp_no");

=head1 RELATIONS

=head2 dept_emps

Type: has_many

Related object: L<Schema::Result::DeptEmp>

=cut

__PACKAGE__->has_many(
  "dept_emps",
  "Schema::Result::DeptEmp",
  { "foreign.emp_no" => "self.emp_no" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 dept_managers

Type: has_many

Related object: L<Schema::Result::DeptManager>

=cut

__PACKAGE__->has_many(
  "dept_managers",
  "Schema::Result::DeptManager",
  { "foreign.emp_no" => "self.emp_no" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 salaries

Type: has_many

Related object: L<Schema::Result::Salary>

=cut

__PACKAGE__->has_many(
  "salaries",
  "Schema::Result::Salary",
  { "foreign.emp_no" => "self.emp_no" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 titles

Type: has_many

Related object: L<Schema::Result::Title>

=cut

__PACKAGE__->has_many(
  "titles",
  "Schema::Result::Title",
  { "foreign.emp_no" => "self.emp_no" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-02-20 11:39:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bMu2wxJIvtJ1YtescnvT8w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
