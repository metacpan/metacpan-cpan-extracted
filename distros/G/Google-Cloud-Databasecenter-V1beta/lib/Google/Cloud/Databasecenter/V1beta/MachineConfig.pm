package Google::Cloud::Databasecenter::V1beta::MachineConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvZGF0YWJhc2VjZW50ZXIvdjFiZXRhL21hY2hpbmVfY29uZmlnLnBy
b3RvEiJnb29nbGUuY2xvdWQuZGF0YWJhc2VjZW50ZXIudjFiZXRhGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvIuYCCg1NYWNoaW5lQ29uZmlnEioKEW1lbW9yeV9zaXplX2J5
dGVzGAIgASgDUg9tZW1vcnlTaXplQnl0ZXMSKQoLc2hhcmRfY291bnQYAyABKAVCA+BBAUgA
UgpzaGFyZENvdW50iAEBEicKCnZjcHVfY291bnQYBCABKAFCA+BBAUgBUgl2Y3B1Q291bnSI
AQESOAoTYmFzZWxpbmVfc2xvdF9jb3VudBgFIAEoA0ID4EEBSAJSEWJhc2VsaW5lU2xvdENv
dW50iAEBEkUKGm1heF9yZXNlcnZhdGlvbl9zbG90X2NvdW50GAYgASgDQgPgQQFIA1IXbWF4
UmVzZXJ2YXRpb25TbG90Q291bnSIAQFCDgoMX3NoYXJkX2NvdW50Qg0KC192Y3B1X2NvdW50
QhYKFF9iYXNlbGluZV9zbG90X2NvdW50Qh0KG19tYXhfcmVzZXJ2YXRpb25fc2xvdF9jb3Vu
dEKAAgomY29tLmdvb2dsZS5jbG91ZC5kYXRhYmFzZWNlbnRlci52MWJldGFCEk1hY2hpbmVD
b25maWdQcm90b1ABWk5jbG91ZC5nb29nbGUuY29tL2dvL2RhdGFiYXNlY2VudGVyL2FwaXYx
YmV0YS9kYXRhYmFzZWNlbnRlcnBiO2RhdGFiYXNlY2VudGVycGKqAiJHb29nbGUuQ2xvdWQu
RGF0YWJhc2VDZW50ZXIuVjFCZXRhygIiR29vZ2xlXENsb3VkXERhdGFiYXNlQ2VudGVyXFYx
YmV0YeoCJUdvb2dsZTo6Q2xvdWQ6OkRhdGFiYXNlQ2VudGVyOjpWMWJldGFK4AwKBhIEDgAx
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
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKwoJCgIDABID
EgApCggKAQgSAxQAPwoJCgIIJRIDFAA/CggKAQgSAxUAZQoJCgIICxIDFQBlCggKAQgSAxYA
IgoJCgIIChIDFgAiCggKAQgSAxcAMwoJCgIICBIDFwAzCggKAQgSAxgAPwoJCgIIARIDGAA/
CggKAQgSAxkAPwoJCgIIKRIDGQA/CggKAQgSAxoAPgoJCgIILRIDGgA+CmYKAgQAEgQeADEB
GlogTWFjaGluZUNvbmZpZyBkZXNjcmliZXMgdGhlIGNvbmZpZ3VyYXRpb24gb2YgYSBtYWNo
aW5lIHNwZWNpZmljIHRvIGEgRGF0YWJhc2UKIFJlc291cmNlLgoKCgoDBAABEgMeCBUKJAoE
BAACABIDIAIeGhcgTWVtb3J5IHNpemUgaW4gYnl0ZXMuCgoMCgUEAAIABRIDIAIHCgwKBQQA
AgABEgMgCBkKDAoFBAACAAMSAyAcHQo+CgQEAAIBEgMjAkoaMSBPcHRpb25hbC4gVGhlIG51
bWJlciBvZiBTaGFyZHMgKGlmIGFwcGxpY2FibGUpLgoKDAoFBAACAQQSAyMCCgoMCgUEAAIB
BRIDIwsQCgwKBQQAAgEBEgMjERwKDAoFBAACAQMSAyMfIAoMCgUEAAIBCBIDIyFJCg8KCAQA
AgEInAgAEgMjIkgKPQoEBAACAhIDJgJKGjAgT3B0aW9uYWwuIFRoZSBudW1iZXIgb2YgdkNQ
VXMgKGlmIGFwcGxpY2FibGUpLgoKDAoFBAACAgQSAyYCCgoMCgUEAAICBRIDJgsRCgwKBQQA
AgIBEgMmEhwKDAoFBAACAgMSAyYfIAoMCgUEAAICCBIDJiFJCg8KCAQAAgIInAgAEgMmIkgK
bAoEBAACAxIEKgIrLxpeIE9wdGlvbmFsLiBCYXNlbGluZSBzbG90cyBmb3IgQmlnUXVlcnkg
UmVzZXJ2YXRpb25zLiBCYXNlbGluZSBzbG90cyBhcmUgaW4KIGluY3JlbWVudHMgb2YgNTAu
CgoMCgUEAAIDBBIDKgIKCgwKBQQAAgMFEgMqCxAKDAoFBAACAwESAyoRJAoMCgUEAAIDAxID
KicoCgwKBQQAAgMIEgMrBi4KDwoIBAACAwicCAASAysHLQpiCgQEAAIEEgQvAjAvGlQgT3B0
aW9uYWwuIE1heCBzbG90cyBmb3IgQmlnUXVlcnkgUmVzZXJ2YXRpb25zLiBNYXggc2xvdHMg
YXJlIGluIGluY3JlbWVudHMKIG9mIDUwLgoKDAoFBAACBAQSAy8CCgoMCgUEAAIEBRIDLwsQ
CgwKBQQAAgQBEgMvESsKDAoFBAACBAMSAy8uLwoMCgUEAAIECBIDMAYuCg8KCAQAAgQInAgA
EgMwBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Databasecenter::V1beta::MachineConfig::MachineConfig ===
    # Fields for MachineConfig
    # Field: memory_size_bytes Type: 3 ()
    # Field: shard_count Type: 5 ()
    # Field: vcpu_count Type: 1 ()
    # Field: baseline_slot_count Type: 3 ()
    # Field: max_reservation_slot_count Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Databasecenter::V1beta::MachineConfig - Compiled Protocol Buffers messages for google/cloud/databasecenter/v1beta/machine_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Databasecenter::V1beta::MachineConfig;

    my $msg = Google::Cloud::Databasecenter::V1beta::MachineConfig::MachineConfig->new({
        memory_size_bytes => $memory_size_bytes,
        shard_count => $shard_count,
        vcpu_count => $vcpu_count,
        baseline_slot_count => $baseline_slot_count,
    });

    # Read or update a field
    my $val = $msg->memory_size_bytes();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Databasecenter::V1beta::MachineConfig::MachineConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/databasecenter/v1beta/machine_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Databasecenter::V1beta::MachineConfig::MachineConfig

MachineConfig describes the configuration of a machine specific to a Database
Resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->memory_size_bytes() >> / C<< $msg->memory_size_bytes($value) >>

Type: C<Int64>

Memory size in bytes.

=item * C<< $msg->shard_count() >> / C<< $msg->shard_count($value) >>

Type: C<Int32>

Optional. The number of Shards (if applicable).

=item * C<< $msg->vcpu_count() >> / C<< $msg->vcpu_count($value) >>

Type: C<Double>

Optional. The number of vCPUs (if applicable).

=item * C<< $msg->baseline_slot_count() >> / C<< $msg->baseline_slot_count($value) >>

Type: C<Int64>

Optional. Baseline slots for BigQuery Reservations. Baseline slots are in
increments of 50.

=item * C<< $msg->max_reservation_slot_count() >> / C<< $msg->max_reservation_slot_count($value) >>

Type: C<Int64>

Optional. Max slots for BigQuery Reservations. Max slots are in increments
of 50.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Databasecenter::V1beta::MachineConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
