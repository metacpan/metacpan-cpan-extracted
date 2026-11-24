package Google::Cloud::Apphub::V1::Boundary;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvYXBwaHViL3YxL2JvdW5kYXJ5LnByb3RvEhZnb29nbGUuY2xvdWQu
YXBwaHViLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBp
L3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIs8DCghC
b3VuZGFyeRIgCghjcm1fbm9kZRgEIAEoCUID4EEBSABSB2NybU5vZGUSFwoEbmFtZRgBIAEo
CUID4EEIUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAMgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEj4KBHR5cGUYBSABKA4yJS5n
b29nbGUuY2xvdWQuYXBwaHViLnYxLkJvdW5kYXJ5LlR5cGVCA+BBA1IEdHlwZSJOCgRUeXBl
EhQKEFRZUEVfVU5TUEVDSUZJRUQQABINCglBVVRPTUFUSUMQARIKCgZNQU5VQUwQAhIVChFN
QU5BR0VEX0FVVE9NQVRJQxADOmvqQWgKHmFwcGh1Yi5nb29nbGVhcGlzLmNvbS9Cb3VuZGFy
eRIwcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2JvdW5kYXJ5Kgpi
b3VuZGFyaWVzMghib3VuZGFyeUIHCgVzY29wZUKvAQoaY29tLmdvb2dsZS5jbG91ZC5hcHBo
dWIudjFCDUJvdW5kYXJ5UHJvdG9QAVoyY2xvdWQuZ29vZ2xlLmNvbS9nby9hcHBodWIvYXBp
djEvYXBwaHVicGI7YXBwaHVicGKqAhZHb29nbGUuQ2xvdWQuQXBwSHViLlYxygIWR29vZ2xl
XENsb3VkXEFwcEh1YlxWMeoCGUdvb2dsZTo6Q2xvdWQ6OkFwcEh1Yjo6VjFKuREKBhIEDgBN
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABID
EgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWADMKCQoCCCUSAxYAMwoICgEIEgMX
AEkKCQoCCAsSAxcASQoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZAC4KCQoCCAgSAxkA
LgoICgEIEgMaADMKCQoCCAESAxoAMwoICgEIEgMbADMKCQoCCCkSAxsAMwoICgEIEgMcADIK
CQoCCC0SAxwAMgouCgIEABIEHwBNARoiIEFwcGxpY2F0aW9uIG1hbmFnZW1lbnQgYm91bmRh
cnkuCgoKCgMEAAESAx8IEAoLCgMEAAcSBCACJQQKDQoFBAAHnQgSBCACJQQKKQoEBAAEABIE
KAI1AxobIEJvdW5kYXJ5IG1hbmFnZW1lbnQgdHlwZS4KCgwKBQQABAABEgMoBwsKIgoGBAAE
AAIAEgMqBBkaEyBVbnNwZWNpZmllZCB0eXBlLgoKDgoHBAAEAAIAARIDKgQUCg4KBwQABAAC
AAISAyoXGApVCgYEAAQAAgESAy0EEhpGIFRoZSBCb3VuZGFyeSBhdXRvbWF0aWNhbGx5IGlu
Y2x1ZGVzIGFsbCBkZXNjZW5kYW50cyBvZiB0aGUgQ1JNIG5vZGUuCgoOCgcEAAQAAgEBEgMt
BA0KDgoHBAAEAAIBAhIDLRARClEKBgQABAACAhIDMAQPGkIgVGhlIGxpc3Qgb2YgcHJvamVj
dHMgd2l0aGluIHRoZSBCb3VuZGFyeSBpcyBtYW5hZ2VkIGJ5IHRoZSB1c2VyLgoKDgoHBAAE
AAICARIDMAQKCg4KBwQABAACAgISAzANDgqJAQoGBAAEAAIDEgM0BBoaeiBUaGUgQm91bmRh
cnkgYXV0b21hdGljYWxseSBpbmNsdWRlcyBhbGwgZGVzY2VuZGFudHMgb2YgdGhlIENSTSBu
b2RlLAogd2hpY2ggaXMgc2V0IHZpYSBBcHAgTWFuYWdlbWVudCBmb2xkZXIgY2FwYWJpbGl0
eS4KCg4KBwQABAACAwESAzQEFQoOCgcEAAQAAgMCEgM0GBkKMAoEBAAIABIEOAI9AxoiIFRo
ZSBzY29wZSBkZWZpbmluZyB0aGUgYm91bmRhcnkuCgoMCgUEAAgAARIDOAgNCpwBCgQEAAIA
EgM8BEEajgEgT3B0aW9uYWwuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBDUk0gbm9kZSBi
ZWluZyBhdHRhY2hlZCB0byB0aGUKIGJvdW5kYXJ5LgogRm9ybWF0OiBgcHJvamVjdHMve3By
b2plY3QtbnVtYmVyfWAgb3IgYHByb2plY3RzL3twcm9qZWN0LWlkfWAKCgwKBQQAAgAFEgM8
BAoKDAoFBAACAAESAzwLEwoMCgUEAAIAAxIDPBYXCgwKBQQAAgAIEgM8GEAKDwoIBAACAAic
CAASAzwZPwp5CgQEAAIBEgNBAj0abCBJZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgYm91bmRhcnkuCiBGb3JtYXQ6ICJwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vYm91bmRhcnkiCgoMCgUEAAIBBRIDQQIICgwKBQQAAgEBEgNBCQ0KDAoF
BAACAQMSA0EQEQoMCgUEAAIBCBIDQRI8Cg8KCAQAAgEInAgAEgNBEzsKKQoEBAACAhIERAJF
MhobIE91dHB1dCBvbmx5LiBDcmVhdGUgdGltZS4KCgwKBQQAAgIGEgNEAhsKDAoFBAACAgES
A0QcJwoMCgUEAAICAxIDRCorCgwKBQQAAgIIEgNFBjEKDwoIBAACAgicCAASA0UHMAopCgQE
AAIDEgRIAkkyGhsgT3V0cHV0IG9ubHkuIFVwZGF0ZSB0aW1lLgoKDAoFBAACAwYSA0gCGwoM
CgUEAAIDARIDSBwnCgwKBQQAAgMDEgNIKisKDAoFBAACAwgSA0kGMQoPCggEAAIDCJwIABID
SQcwCioKBAQAAgQSA0wCPBodIE91dHB1dCBvbmx5LiBCb3VuZGFyeSB0eXBlLgoKDAoFBAAC
BAYSA0wCBgoMCgUEAAIEARIDTAcLCgwKBQQAAgQDEgNMDg8KDAoFBAACBAgSA0wQOwoPCggE
AAIECJwIABIDTBE6YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apphub::V1::Boundary::Boundary ===
    # Fields for Boundary
    # Field: crm_node Type: 9 ()
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: type Type: 14 (.google.cloud.apphub.v1.Boundary.Type)

# Enum: Boundary::Type
our $Boundary_TYPE_UNSPECIFIED = 0;
our $Boundary_AUTOMATIC = 1;
our $Boundary_MANUAL = 2;
our $Boundary_MANAGED_AUTOMATIC = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apphub::V1::Boundary - Compiled Protocol Buffers messages for google/cloud/apphub/v1/boundary.proto

=head1 SYNOPSIS

    use Google::Cloud::Apphub::V1::Boundary;

    my $msg = Google::Cloud::Apphub::V1::Boundary::Boundary->new({
        crm_node => $crm_node,
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->crm_node();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apphub::V1::Boundary::Boundary->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apphub/v1/boundary.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apphub::V1::Boundary::Boundary

Application management boundary.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->crm_node() >> / C<< $msg->crm_node($value) >>

Type: C<String>

Optional. The resource name of the CRM node being attached to the
boundary.
Format: `projects/{project-number}` or `projects/{project-id}`

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the boundary.
Format: "projects/{project}/locations/{location}/boundary"

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Apphub::V1::Boundary::Type>)

Output only. Boundary type.

=back

=head3 Enum: Boundary::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<AUTOMATIC> => C<1>

=item * C<MANUAL> => C<2>

=item * C<MANAGED_AUTOMATIC> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apphub::V1::Boundary::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
