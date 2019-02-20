use utf8;
package Schema::Result::DeptEmpLatestDate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::DeptEmpLatestDate - VIEW

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<dept_emp_latest_date>

=cut

__PACKAGE__->table("dept_emp_latest_date");
__PACKAGE__->result_source_instance->view_definition("select `employees`.`dept_emp`.`emp_no` AS `emp_no`,max(`employees`.`dept_emp`.`from_date`) AS `from_date`,max(`employees`.`dept_emp`.`to_date`) AS `to_date` from `employees`.`dept_emp` group by `employees`.`dept_emp`.`emp_no`");

=head1 ACCESSORS

=head2 emp_no

  data_type: 'integer'
  is_nullable: 0

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
  "from_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "to_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-02-20 11:39:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9rhF4iHJwSl3uf9BZeheZg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
