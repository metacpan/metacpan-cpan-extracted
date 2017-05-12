use utf8;
package HPC::Runner::Command::Plugin::Logger::Sqlite::Schema::Result::Job;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HPC::Runner::Command::Plugin::Logger::Sqlite::Schema::Result::Job

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<jobs>

=cut

__PACKAGE__->table("jobs");

=head1 ACCESSORS

=head2 job_pi

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 submission_fk

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 job_scheduler_id

  data_type: 'text'
  is_nullable: 1

=head2 start_time

  data_type: 'text'
  is_nullable: 0

=head2 exit_time

  data_type: 'text'
  is_nullable: 0

=head2 duration

  data_type: 'text'
  is_nullable: 1

=head2 jobs_meta

  data_type: 'text'
  is_nullable: 1

=head2 job_name

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "job_pi",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "submission_fk",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "job_scheduler_id",
  { data_type => "text", is_nullable => 1 },
  "start_time",
  { data_type => "text", is_nullable => 0 },
  "exit_time",
  { data_type => "text", is_nullable => 0 },
  "duration",
  { data_type => "text", is_nullable => 1 },
  "jobs_meta",
  { data_type => "text", is_nullable => 1 },
  "job_name",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</job_pi>

=back

=cut

__PACKAGE__->set_primary_key("job_pi");

=head1 RELATIONS

=head2 submission_fk

Type: belongs_to

Related object: L<HPC::Runner::Command::Plugin::Logger::Sqlite::Schema::Result::Submission>

=cut

__PACKAGE__->belongs_to(
  "submission_fk",
  "HPC::Runner::Command::Plugin::Logger::Sqlite::Schema::Result::Submission",
  { submission_pi => "submission_fk" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 tasks

Type: has_many

Related object: L<HPC::Runner::Command::Plugin::Logger::Sqlite::Schema::Result::Task>

=cut

__PACKAGE__->has_many(
  "tasks",
  "HPC::Runner::Command::Plugin::Logger::Sqlite::Schema::Result::Task",
  { "foreign.job_fk" => "self.job_pi" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-03-28 14:40:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/WroaV1KhFwIpCDL7UwNmA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
