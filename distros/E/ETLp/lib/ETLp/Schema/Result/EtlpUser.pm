package ETLp::Schema::Result::EtlpUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ETLp::Schema::Result::EtlpUser

=cut

__PACKAGE__->table("etlp_user");

=head1 ACCESSORS

=head2 user_id

  is_auto_increment: 1

=head2 username

  data_type: 'varchar2'
  is_nullable: 0
  size: 30

=head2 first_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 50

=head2 last_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 30

=head2 password

  data_type: 'varchar2'
  is_nullable: 0
  size: 40

=head2 email_address

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 admin

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 active

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=cut

__PACKAGE__->add_columns(
  "user_id",
  { is_auto_increment => 1 },
  "username",
  { data_type => "varchar2", is_nullable => 0, size => 30 },
  "first_name",
  { data_type => "varchar2", is_nullable => 0, size => 50 },
  "last_name",
  { data_type => "varchar2", is_nullable => 0, size => 30 },
  "password",
  { data_type => "varchar2", is_nullable => 0, size => 40 },
  "email_address",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "admin",
  {
    data_type     => "integer",
    default_value => 0,
    is_nullable   => 0,
    original      => { data_type => "number", size => [38, 0] },
  },
  "active",
  {
    data_type     => "integer",
    default_value => 1,
    is_nullable   => 0,
    original      => { data_type => "number", size => [38, 0] },
  },
);
__PACKAGE__->set_primary_key("user_id");
__PACKAGE__->add_unique_constraint("etlp_user_u1", ["username"]);

=head1 RELATIONS

=head2 etlp_schedule_users_created

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpSchedule>

=cut

__PACKAGE__->has_many(
  "etlp_schedule_users_created",
  "ETLp::Schema::Result::EtlpSchedule",
  { "foreign.user_created" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 etlp_schedule_users_updated

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpSchedule>

=cut

__PACKAGE__->has_many(
  "etlp_schedule_users_updated",
  "ETLp::Schema::Result::EtlpSchedule",
  { "foreign.user_updated" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-05-12 15:25:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ISVhuUynNKwcBjx+Z4WcgA

use Data::Page::Navigation;
# You can replace this text with custom content, and it will be preserved on regeneration
1;
# End of lines loaded from '/usr/local/lib/perl5/site_perl/5.10.0/ETLp/Schema/Result/EtlpUser.pm' 

