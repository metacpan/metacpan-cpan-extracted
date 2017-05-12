use utf8;
package HPC::Runner::Command::Plugin::Logger::Sqlite::Schema::Result::Submission;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HPC::Runner::Command::Plugin::Logger::Sqlite::Schema::Result::Submission

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<submission>

=cut

__PACKAGE__->table("submission");

=head1 ACCESSORS

=head2 submission_pi

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 project

  data_type: 'text'
  is_nullable: 1

=head2 submission_meta

  data_type: 'text'
  is_nullable: 1

=head2 total_processes

  data_type: 'integer'
  is_nullable: 0

=head2 total_batches

  data_type: 'integet'
  is_nullable: 0

=head2 submission_time

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "submission_pi",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "project",
  { data_type => "text", is_nullable => 1 },
  "submission_meta",
  { data_type => "text", is_nullable => 1 },
  "total_processes",
  { data_type => "integer", is_nullable => 0 },
  "total_batches",
  { data_type => "integet", is_nullable => 0 },
  "submission_time",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</submission_pi>

=back

=cut

__PACKAGE__->set_primary_key("submission_pi");

=head1 RELATIONS

=head2 jobs

Type: has_many

Related object: L<HPC::Runner::Command::Plugin::Logger::Sqlite::Schema::Result::Job>

=cut

__PACKAGE__->has_many(
  "jobs",
  "HPC::Runner::Command::Plugin::Logger::Sqlite::Schema::Result::Job",
  { "foreign.submission_fk" => "self.submission_pi" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-03-28 14:40:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e9yr8/SPDCmvVbTqLXW6PA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
