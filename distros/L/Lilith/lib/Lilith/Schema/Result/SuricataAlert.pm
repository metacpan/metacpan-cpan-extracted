use utf8;
package Lilith::Schema::Result::SuricataAlert;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Lilith::Schema::Result::SuricataAlert

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<suricata_alerts>

=cut

__PACKAGE__->table("suricata_alerts");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'suricata_alerts_id_seq'

=head2 instance

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 host

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 timestamp

  data_type: 'timestamp with time zone'
  is_nullable: 0

=head2 event_id

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 flow_id

  data_type: 'bigint'
  is_nullable: 1

=head2 in_iface

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

=head2 proto

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 app_proto

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 flow_pkts_toserver

  data_type: 'integer'
  is_nullable: 1

=head2 flow_bytes_toserver

  data_type: 'integer'
  is_nullable: 1

=head2 flow_pkts_toclient

  data_type: 'integer'
  is_nullable: 1

=head2 flow_bytes_toclient

  data_type: 'integer'
  is_nullable: 1

=head2 flow_start

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 classification

  data_type: 'varchar'
  is_nullable: 1
  size: 1024

=head2 signature

  data_type: 'varchar'
  is_nullable: 1
  size: 2048

=head2 gid

  data_type: 'integer'
  is_nullable: 1

=head2 sid

  data_type: 'bigint'
  is_nullable: 1

=head2 rev

  data_type: 'bigint'
  is_nullable: 1

=head2 raw

  data_type: 'json'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "suricata_alerts_id_seq",
  },
  "instance",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "host",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "timestamp",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "event_id",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "flow_id",
  { data_type => "bigint", is_nullable => 1 },
  "in_iface",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "src_ip",
  { data_type => "inet", is_nullable => 1 },
  "src_port",
  { data_type => "integer", is_nullable => 1 },
  "dest_ip",
  { data_type => "inet", is_nullable => 1 },
  "dest_port",
  { data_type => "integer", is_nullable => 1 },
  "proto",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "app_proto",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "flow_pkts_toserver",
  { data_type => "integer", is_nullable => 1 },
  "flow_bytes_toserver",
  { data_type => "integer", is_nullable => 1 },
  "flow_pkts_toclient",
  { data_type => "integer", is_nullable => 1 },
  "flow_bytes_toclient",
  { data_type => "integer", is_nullable => 1 },
  "flow_start",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "classification",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
  "signature",
  { data_type => "varchar", is_nullable => 1, size => 2048 },
  "gid",
  { data_type => "integer", is_nullable => 1 },
  "sid",
  { data_type => "bigint", is_nullable => 1 },
  "rev",
  { data_type => "bigint", is_nullable => 1 },
  "raw",
  { data_type => "json", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2026-03-15 22:29:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cS8b29asQj6VYpHQxjjbwg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
