use utf8;
package Lilith::Schema::Result::CapeAlert;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Lilith::Schema::Result::CapeAlert

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cape_alerts>

=cut

__PACKAGE__->table("cape_alerts");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cape_alerts_id_seq'

=head2 instance

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 target

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 instance_host

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 task

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cape_alerts_task_seq'

=head2 start

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 stop

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 malscore

  data_type: 'double precision'
  is_nullable: 0

=head2 subbed_from_ip

  data_type: 'inet'
  is_nullable: 1

=head2 subbed_from_host

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pkg

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 md5

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 sha1

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 sha256

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 slug

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 url_hostname

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 proto

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 src_ip

  data_type: 'inet'
  is_nullable: 1

=head2 src_port

  data_type: 'integer'
  is_nullable: 1

=head2 dest_ip

  data_type: 'inet'
  is_nullable: 1

=head2 dest_port

  data_type: 'integer'
  is_nullable: 1

=head2 size

  data_type: 'integer'
  is_nullable: 1

=head2 raw

  data_type: 'jsonb'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cape_alerts_id_seq",
  },
  "instance",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "target",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "instance_host",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "task",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cape_alerts_task_seq",
  },
  "start",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "stop",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "malscore",
  { data_type => "double precision", is_nullable => 0 },
  "subbed_from_ip",
  { data_type => "inet", is_nullable => 1 },
  "subbed_from_host",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pkg",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "md5",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "sha1",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "sha256",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "slug",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "url_hostname",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "proto",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "src_ip",
  { data_type => "inet", is_nullable => 1 },
  "src_port",
  { data_type => "integer", is_nullable => 1 },
  "dest_ip",
  { data_type => "inet", is_nullable => 1 },
  "dest_port",
  { data_type => "integer", is_nullable => 1 },
  "size",
  { data_type => "integer", is_nullable => 1 },
  "raw",
  { data_type => "jsonb", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2026-03-15 22:29:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zB5k7KPnxxSsMJZih+H8qw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
