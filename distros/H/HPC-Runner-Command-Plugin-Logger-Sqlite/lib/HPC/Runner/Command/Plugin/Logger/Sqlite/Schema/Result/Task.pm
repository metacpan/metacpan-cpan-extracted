use utf8;
package HPC::Runner::Command::Plugin::Logger::Sqlite::Schema::Result::Task;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HPC::Runner::Command::Plugin::Logger::Sqlite::Schema::Result::Task

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<tasks>

=cut

__PACKAGE__->table("tasks");

=head1 ACCESSORS

=head2 task_pi

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 job_fk

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pid

  data_type: 'integer'
  is_nullable: 0

=head2 start_time

  data_type: 'text'
  is_nullable: 0

=head2 exit_time

  data_type: 'text'
  is_nullable: 1

=head2 duration

  data_type: 'text'
  is_nullable: 1

=head2 exit_code

  data_type: 'integer'
  is_nullable: 1

=head2 tasks_meta

  data_type: 'text'
  is_nullable: 1

=head2 task_tags

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "task_pi",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "job_fk",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pid",
  { data_type => "integer", is_nullable => 0 },
  "start_time",
  { data_type => "text", is_nullable => 0 },
  "exit_time",
  { data_type => "text", is_nullable => 1 },
  "duration",
  { data_type => "text", is_nullable => 1 },
  "exit_code",
  { data_type => "integer", is_nullable => 1 },
  "tasks_meta",
  { data_type => "text", is_nullable => 1 },
  "task_tags",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</task_pi>

=back

=cut

__PACKAGE__->set_primary_key("task_pi");

=head1 RELATIONS

=head2 job_fk

Type: belongs_to

Related object: L<HPC::Runner::Command::Plugin::Logger::Sqlite::Schema::Result::Job>

=cut

__PACKAGE__->belongs_to(
  "job_fk",
  "HPC::Runner::Command::Plugin::Logger::Sqlite::Schema::Result::Job",
  { job_pi => "job_fk" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-03-28 14:40:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:R31ymUSo+XWr/fK3t2c9nw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
