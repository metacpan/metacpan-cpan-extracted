package Google::Cloud::Securitycenter::V2::Database;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvZGF0YWJhc2UucHJvdG8SHmdvb2ds
ZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MiKqAQoIRGF0YWJhc2USEgoEbmFtZRgBIAEoCVIE
bmFtZRIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rpc3BsYXlOYW1lEhsKCXVzZXJfbmFtZRgD
IAEoCVIIdXNlck5hbWUSFAoFcXVlcnkYBCABKAlSBXF1ZXJ5EhoKCGdyYW50ZWVzGAUgAygJ
UghncmFudGVlcxIYCgd2ZXJzaW9uGAYgASgJUgd2ZXJzaW9uQucBCiJjb20uZ29vZ2xlLmNs
b3VkLnNlY3VyaXR5Y2VudGVyLnYyQg1EYXRhYmFzZVByb3RvUAFaSmNsb3VkLmdvb2dsZS5j
b20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjIvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNl
bnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYyygIeR29vZ2xlXENsb3Vk
XFNlY3VyaXR5Q2VudGVyXFYy6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYy
Sp4UCgYSBA4APgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ACcKCAoBCBIDEgA7CgkKAgglEgMSADsKCAoBCBIDEwBhCgkKAggLEgMTAGEKCAoBCBIDFAAi
CgkKAggKEgMUACIKCAoBCBIDFQAuCgkKAggIEgMVAC4KCAoBCBIDFgA7CgkKAggBEgMWADsK
CAoBCBIDFwA7CgkKAggpEgMXADsKCAoBCBIDGAA6CgkKAggtEgMYADoK+QMKAgQAEgQhAD4B
GuwDIFJlcHJlc2VudHMgZGF0YWJhc2UgYWNjZXNzIGluZm9ybWF0aW9uLCBzdWNoIGFzIHF1
ZXJpZXMuIEEgZGF0YWJhc2UgbWF5IGJlIGEKIHN1Yi1yZXNvdXJjZSBvZiBhbiBpbnN0YW5j
ZSAoYXMgaW4gdGhlIGNhc2Ugb2YgQ2xvdWQgU1FMIGluc3RhbmNlcyBvciBDbG91ZAogU3Bh
bm5lciBpbnN0YW5jZXMpLCBvciB0aGUgZGF0YWJhc2UgaW5zdGFuY2UgaXRzZWxmLiBTb21l
IGRhdGFiYXNlIHJlc291cmNlcwogbWlnaHQgbm90IGhhdmUgdGhlIFtmdWxsIHJlc291cmNl
CiBuYW1lXShodHRwczovL2dvb2dsZS5haXAuZGV2LzEyMiNmdWxsLXJlc291cmNlLW5hbWVz
KSBwb3B1bGF0ZWQgYmVjYXVzZSB0aGVzZQogcmVzb3VyY2UgdHlwZXMsIHN1Y2ggYXMgQ2xv
dWQgU1FMIGRhdGFiYXNlcywgYXJlIG5vdCB5ZXQgc3VwcG9ydGVkIGJ5IENsb3VkCiBBc3Nl
dCBJbnZlbnRvcnkuIEluIHRoZXNlIGNhc2VzIG9ubHkgdGhlIGRpc3BsYXkgbmFtZSBpcyBw
cm92aWRlZC4KCgoKAwQAARIDIQgQCs8DCgQEAAIAEgMqAhIawQMgU29tZSBkYXRhYmFzZSBy
ZXNvdXJjZXMgbWF5IG5vdCBoYXZlIHRoZSBbZnVsbCByZXNvdXJjZQogbmFtZV0oaHR0cHM6
Ly9nb29nbGUuYWlwLmRldi8xMjIjZnVsbC1yZXNvdXJjZS1uYW1lcykgcG9wdWxhdGVkIGJl
Y2F1c2UKIHRoZXNlIHJlc291cmNlIHR5cGVzIGFyZSBub3QgeWV0IHN1cHBvcnRlZCBieSBD
bG91ZCBBc3NldCBJbnZlbnRvcnkgKGUuZy4KIENsb3VkIFNRTCBkYXRhYmFzZXMpLiBJbiB0
aGVzZSBjYXNlcyBvbmx5IHRoZSBkaXNwbGF5IG5hbWUgd2lsbCBiZQogcHJvdmlkZWQuCiBU
aGUgW2Z1bGwgcmVzb3VyY2UgbmFtZV0oaHR0cHM6Ly9nb29nbGUuYWlwLmRldi8xMjIjZnVs
bC1yZXNvdXJjZS1uYW1lcykgb2YKIHRoZSBkYXRhYmFzZSB0aGF0IHRoZSB1c2VyIGNvbm5l
Y3RlZCB0bywgaWYgaXQgaXMgc3VwcG9ydGVkIGJ5IENsb3VkIEFzc2V0CiBJbnZlbnRvcnku
CgoMCgUEAAIABRIDKgIICgwKBQQAAgABEgMqCQ0KDAoFBAACAAMSAyoQEQpSCgQEAAIBEgMt
AhoaRSBUaGUgaHVtYW4tcmVhZGFibGUgbmFtZSBvZiB0aGUgZGF0YWJhc2UgdGhhdCB0aGUg
dXNlciBjb25uZWN0ZWQgdG8uCgoMCgUEAAIBBRIDLQIICgwKBQQAAgEBEgMtCRUKDAoFBAAC
AQMSAy0YGQqIAQoEBAACAhIDMQIXGnsgVGhlIHVzZXJuYW1lIHVzZWQgdG8gY29ubmVjdCB0
byB0aGUgZGF0YWJhc2UuIFRoZSB1c2VybmFtZSBtaWdodCBub3QgYmUgYW4KIElBTSBwcmlu
Y2lwYWwgYW5kIGRvZXMgbm90IGhhdmUgYSBzZXQgZm9ybWF0LgoKDAoFBAACAgUSAzECCAoM
CgUEAAICARIDMQkSCgwKBQQAAgIDEgMxFRYKTQoEBAACAxIDNAITGkAgVGhlIFNRTCBzdGF0
ZW1lbnQgdGhhdCBpcyBhc3NvY2lhdGVkIHdpdGggdGhlIGRhdGFiYXNlIGFjY2Vzcy4KCgwK
BQQAAgMFEgM0AggKDAoFBAACAwESAzQJDgoMCgUEAAIDAxIDNBESCnQKBAQAAgQSAzgCHxpn
IFRoZSB0YXJnZXQgdXNlcm5hbWVzLCByb2xlcywgb3IgZ3JvdXBzIG9mIGFuIFNRTCBwcml2
aWxlZ2UgZ3JhbnQsIHdoaWNoIGlzCiBub3QgYW4gSUFNIHBvbGljeSBjaGFuZ2UuCgoMCgUE
AAIEBBIDOAIKCgwKBQQAAgQFEgM4CxEKDAoFBAACBAESAzgSGgoMCgUEAAIEAxIDOB0eCq8B
CgQEAAIFEgM9AhUaoQEgVGhlIHZlcnNpb24gb2YgdGhlIGRhdGFiYXNlLCBmb3IgZXhhbXBs
ZSwgUE9TVEdSRVNfMTQuCiBTZWUgW3RoZSBjb21wbGV0ZQogbGlzdF0oaHR0cHM6Ly9jbG91
ZC5nb29nbGUuY29tL3NxbC9kb2NzL215c3FsL2FkbWluLWFwaS9yZXN0L3YxL1NxbERhdGFi
YXNlVmVyc2lvbikuCgoMCgUEAAIFBRIDPQIICgwKBQQAAgUBEgM9CRAKDAoFBAACBQMSAz0T
FGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::Database::Database ===
    # Fields for Database
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: user_name Type: 9 ()
    # Field: query Type: 9 ()
    # Field: grantees Type: 9 ()
    # Field: version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::Database - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/database.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::Database;

    my $msg = Google::Cloud::Securitycenter::V2::Database::Database->new({
        name => $name,
        display_name => $display_name,
        user_name => $user_name,
        query => $query,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::Database::Database->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/database.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::Database::Database

Represents database access information, such as queries. A database may be a
sub-resource of an instance (as in the case of Cloud SQL instances or Cloud
Spanner instances), or the database instance itself. Some database resources
might not have the [full resource
name](https://google.aip.dev/122#full-resource-names) populated because these
resource types, such as Cloud SQL databases, are not yet supported by Cloud
Asset Inventory. In these cases only the display name is provided.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Some database resources may not have the [full resource
name](https://google.aip.dev/122#full-resource-names) populated because
these resource types are not yet supported by Cloud Asset Inventory (e.g.
Cloud SQL databases). In these cases only the display name will be
provided.
The [full resource name](https://google.aip.dev/122#full-resource-names) of
the database that the user connected to, if it is supported by Cloud Asset
Inventory.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The human-readable name of the database that the user connected to.

=item * C<< $msg->user_name() >> / C<< $msg->user_name($value) >>

Type: C<String>

The username used to connect to the database. The username might not be an
IAM principal and does not have a set format.

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

The SQL statement that is associated with the database access.

=item * C<< $msg->grantees() >> / C<< $msg->grantees($value) >>

Type: C<String>

The target usernames, roles, or groups of an SQL privilege grant, which is
not an IAM policy change.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

The version of the database, for example, POSTGRES_14.
See [the complete
list](https://cloud.google.com/sql/docs/mysql/admin-api/rest/v1/SqlDatabaseVersion).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::Database::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
