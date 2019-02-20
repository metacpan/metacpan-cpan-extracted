use utf8;
package Schema::Result::CurrentDeptEmp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::CurrentDeptEmp - VIEW

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<current_dept_emp>

=cut

__PACKAGE__->table("current_dept_emp");
__PACKAGE__->result_source_instance->view_definition("select `l`.`emp_no` AS `emp_no`,`d`.`dept_no` AS `dept_no`,`l`.`from_date` AS `from_date`,`l`.`to_date` AS `to_date` from (`employees`.`dept_emp` `d` join `employees`.`dept_emp_latest_date` `l` on(((`d`.`emp_no` = `l`.`emp_no`) and (`d`.`from_date` = `l`.`from_date`) and (`l`.`to_date` = `d`.`to_date`))))");

=head1 ACCESSORS

=head2 emp_no

  data_type: 'integer'
  is_nullable: 0

=head2 dept_no

  data_type: 'char'
  is_nullable: 0
  size: 4

=head2 from_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 to_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "emp_no",
  { data_type => "integer", is_nullable => 0 },
  "dept_no",
  { data_type => "char", is_nullable => 0, size => 4 },
  "from_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "to_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-02-20 11:39:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7ivl3rcxM60taKl3jv9hcw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
