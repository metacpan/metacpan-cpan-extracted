package Google::Cloud::Gkebackup::V1::RestorePlanBinding;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvZ2tlYmFja3VwL3YxL3Jlc3RvcmVfcGxhbl9iaW5kaW5nLnByb3Rv
Ehlnb29nbGUuY2xvdWQuZ2tlYmFja3VwLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3Vy
Y2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i2wQKElJlc3RvcmVQ
bGFuQmluZGluZxIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSHQoDdWlkGAIgASgJQgvijM/X
CAIIAeBBA1IDdWlkEkAKC2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAQgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEk8KDHJlc3RvcmVfcGxhbhgF
IAEoCUIs4EED+kEmCiRna2ViYWNrdXAuZ29vZ2xlYXBpcy5jb20vUmVzdG9yZVBsYW5SC3Jl
c3RvcmVQbGFuEhcKBGV0YWcYBiABKAlCA+BBA1IEZXRhZxJMCgtiYWNrdXBfcGxhbhgHIAEo
CUIr4EED+kElCiNna2ViYWNrdXAuZ29vZ2xlYXBpcy5jb20vQmFja3VwUGxhblIKYmFja3Vw
UGxhbjrQAepBzAEKK2drZWJhY2t1cC5nb29nbGVhcGlzLmNvbS9SZXN0b3JlUGxhbkJpbmRp
bmcSdHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXN0b3JlQ2hh
bm5lbHMve3Jlc3RvcmVfY2hhbm5lbH0vcmVzdG9yZVBsYW5CaW5kaW5ncy97cmVzdG9yZV9w
bGFuX2JpbmRpbmd9KhNyZXN0b3JlUGxhbkJpbmRpbmdzMhJyZXN0b3JlUGxhbkJpbmRpbmdC
zgEKHWNvbS5nb29nbGUuY2xvdWQuZ2tlYmFja3VwLnYxQhdSZXN0b3JlUGxhbkJpbmRpbmdQ
cm90b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL2drZWJhY2t1cC9hcGl2MS9na2ViYWNrdXBw
Yjtna2ViYWNrdXBwYqoCGUdvb2dsZS5DbG91ZC5Ha2VCYWNrdXAuVjHKAhlHb29nbGVcQ2xv
dWRcR2tlQmFja3VwXFYx6gIcR29vZ2xlOjpDbG91ZDo6R2tlQmFja3VwOjpWMUrzFwoGEgQO
AFoBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAiCgkKAgMA
EgMSACkKCQoCAwESAxMAJQoJCgIDAhIDFAAjCgkKAgMDEgMVACkKCAoBCBIDFwA2CgkKAggl
EgMXADYKCAoBCBIDGABSCgkKAggLEgMYAFIKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBID
GgA4CgkKAggIEgMaADgKCAoBCBIDGwA2CgkKAggBEgMbADYKCAoBCBIDHAA2CgkKAggpEgMc
ADYKCAoBCBIDHQA1CgkKAggtEgMdADUKlgIKAgQAEgQjAFoBGokCIEEgUmVzdG9yZVBsYW5C
aW5kaW5nIGJpbmRzIGEgUmVzdG9yZVBsYW4gd2l0aCBhIFJlc3RvcmVDaGFubmVsLgogVGhp
cyByZXNvdXJjZSBpcyBjcmVhdGVkIGF1dG9tYXRpY2FsbHkgd2hlbiBhIFJlc3RvcmVQbGFu
IGlzIGNyZWF0ZWQgdXNpbmcgYQogUmVzdG9yZUNoYW5uZWwuIFRoaXMgYWxzbyBzZXJ2ZXMg
YXMgYSBob2xkZXIgZm9yIGNyb3NzLXByb2plY3QgZmllbGRzCiB0aGF0IG5lZWQgdG8gYmUg
ZGlzcGxheWVkIGluIHRoZSBjdXJyZW50IHByb2plY3QuCgoKCgMEAAESAyMIGgoLCgMEAAcS
BCQCKQQKDQoFBAAHnQgSBCQCKQQKkQEKBAQAAgASAy0CPRqDASBJZGVudGlmaWVyLiBUaGUg
ZnVsbHkgcXVhbGlmaWVkIG5hbWUgb2YgdGhlIFJlc3RvcmVQbGFuQmluZGluZy4KIGBwcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL3Jlc3RvcmVDaGFubmVscy8qL3Jlc3RvcmVQbGFuQmluZGlu
Z3MvKmAKCgwKBQQAAgAFEgMtAggKDAoFBAACAAESAy0JDQoMCgUEAAIAAxIDLRARCgwKBQQA
AgAIEgMtEjwKDwoIBAACAAicCAASAy0TOwqQAQoEBAACARIEMQI0BBqBASBPdXRwdXQgb25s
eS4gU2VydmVyIGdlbmVyYXRlZCBnbG9iYWwgdW5pcXVlIGlkZW50aWZpZXIgb2YKIFtVVUlE
NF0oaHR0cHM6Ly9lbi53aWtpcGVkaWEub3JnL3dpa2kvVW5pdmVyc2FsbHlfdW5pcXVlX2lk
ZW50aWZpZXIpCgoMCgUEAAIBBRIDMQIICgwKBQQAAgEBEgMxCQwKDAoFBAACAQMSAzEPEAoN
CgUEAAIBCBIEMRE0AwoSCgsEAAIBCMzx+YoBARIDMgQqCg8KCAQAAgEInAgAEgMzBC0KSQoE
BAACAhIENwI4Mho7IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhpcyBiaW5k
aW5nIHdhcyBjcmVhdGVkLgoKDAoFBAACAgYSAzcCGwoMCgUEAAICARIDNxwnCgwKBQQAAgID
EgM3KisKDAoFBAACAggSAzgGMQoPCggEAAICCJwIABIDOAcwCkkKBAQAAgMSBDsCPDIaOyBP
dXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB3aGVuIHRoaXMgYmluZGluZyB3YXMgY3JlYXRl
ZC4KCgwKBQQAAgMGEgM7AhsKDAoFBAACAwESAzscJwoMCgUEAAIDAxIDOyorCgwKBQQAAgMI
EgM8BjEKDwoIBAACAwicCAASAzwHMAqdAQoEBAACBBIEQAJFBBqOASBPdXRwdXQgb25seS4g
VGhlIGZ1bGx5IHF1YWxpZmllZCBuYW1lIG9mIHRoZSBSZXN0b3JlUGxhbiBib3VuZCB0byB0
aGlzCiBSZXN0b3JlQ2hhbm5lbC4gYHByb2plY3RzLyovbG9jYXRpb25zLyovcmVzdG9yZVBs
YW5zL3tyZXN0b3JlX3BsYW59YAoKDAoFBAACBAUSA0ACCAoMCgUEAAIEARIDQAkVCgwKBQQA
AgQDEgNAGBkKDQoFBAACBAgSBEAaRQMKDwoIBAACBAicCAASA0EELQoPCgcEAAIECJ8IEgRC
BEQFCuYECgQEAAIFEgNQAj4a2AQgT3V0cHV0IG9ubHkuIGBldGFnYCBpcyB1c2VkIGZvciBv
cHRpbWlzdGljIGNvbmN1cnJlbmN5IGNvbnRyb2wgYXMgYSB3YXkgdG8KIGhlbHAgcHJldmVu
dCBzaW11bHRhbmVvdXMgdXBkYXRlcyBvZiBhIFJlc3RvcmVQbGFuQmluZGluZyBmcm9tIG92
ZXJ3cml0aW5nCiBlYWNoIG90aGVyLiBJdCBpcyBzdHJvbmdseSBzdWdnZXN0ZWQgdGhhdCBz
eXN0ZW1zIG1ha2UgdXNlIG9mIHRoZSAnZXRhZycgaW4KIHRoZSByZWFkLW1vZGlmeS13cml0
ZSBjeWNsZSB0byBwZXJmb3JtIFJlc3RvcmVQbGFuQmluZGluZyB1cGRhdGVzIGluCiBvcmRl
ciB0byBhdm9pZCByYWNlIGNvbmRpdGlvbnM6IEFuIGBldGFnYCBpcyByZXR1cm5lZCBpbiB0
aGUgcmVzcG9uc2UgdG8KIGBHZXRSZXN0b3JlUGxhbkJpbmRpbmdgLCBhbmQgc3lzdGVtcyBh
cmUgZXhwZWN0ZWQgdG8gcHV0IHRoYXQgZXRhZyBpbgogdGhlIHJlcXVlc3QgdG8gYFVwZGF0
ZVJlc3RvcmVQbGFuQmluZGluZ2Agb3IKIGBEZWxldGVSZXN0b3JlUGxhbkJpbmRpbmdgIHRv
IGVuc3VyZSB0aGF0IHRoZWlyIGNoYW5nZSB3aWxsIGJlIGFwcGxpZWQKIHRvIHRoZSBzYW1l
IHZlcnNpb24gb2YgdGhlIHJlc291cmNlLgoKDAoFBAACBQUSA1ACCAoMCgUEAAIFARIDUAkN
CgwKBQQAAgUDEgNQEBEKDAoFBAACBQgSA1ASPQoPCggEAAIFCJwIABIDUBM8CqEBCgQEAAIG
EgRUAlkEGpIBIE91dHB1dCBvbmx5LiBUaGUgZnVsbHkgcXVhbGlmaWVkIG5hbWUgb2YgdGhl
IEJhY2t1cFBsYW4gYm91bmQgdG8gdGhlCiBzcGVjaWZpZWQgUmVzdG9yZVBsYW4uIGBwcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2JhY2t1a3BQbGFucy97YmFja3VwX3BsYW59YAoKDAoFBAAC
BgUSA1QCCAoMCgUEAAIGARIDVAkUCgwKBQQAAgYDEgNUFxgKDQoFBAACBggSBFQZWQMKDwoI
BAACBgicCAASA1UELQoPCgcEAAIGCJ8IEgRWBFgFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::V1::RestorePlanBinding::RestorePlanBinding ===
    # Fields for RestorePlanBinding
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: restore_plan Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: backup_plan Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::V1::RestorePlanBinding - Compiled Protocol Buffers messages for google/cloud/gkebackup/v1/restore_plan_binding.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::V1::RestorePlanBinding;

    my $msg = Google::Cloud::Gkebackup::V1::RestorePlanBinding::RestorePlanBinding->new({
        name => $name,
        uid => $uid,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::V1::RestorePlanBinding::RestorePlanBinding->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/v1/restore_plan_binding.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::V1::RestorePlanBinding::RestorePlanBinding

A RestorePlanBinding binds a RestorePlan with a RestoreChannel.
This resource is created automatically when a RestorePlan is created using a
RestoreChannel. This also serves as a holder for cross-project fields
that need to be displayed in the current project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The fully qualified name of the RestorePlanBinding.
`projects/*/locations/*/restoreChannels/*/restorePlanBindings/*`

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server generated global unique identifier of
[UUID4](https://en.wikipedia.org/wiki/Universally_unique_identifier)

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this binding was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this binding was created.

=item * C<< $msg->restore_plan() >> / C<< $msg->restore_plan($value) >>

Type: C<String>

Output only. The fully qualified name of the RestorePlan bound to this
RestoreChannel. `projects/*/locations/*/restorePlans/{restore_plan}`

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. `etag` is used for optimistic concurrency control as a way to
help prevent simultaneous updates of a RestorePlanBinding from overwriting
each other. It is strongly suggested that systems make use of the 'etag' in
the read-modify-write cycle to perform RestorePlanBinding updates in
order to avoid race conditions: An `etag` is returned in the response to
`GetRestorePlanBinding`, and systems are expected to put that etag in
the request to `UpdateRestorePlanBinding` or
`DeleteRestorePlanBinding` to ensure that their change will be applied
to the same version of the resource.

=item * C<< $msg->backup_plan() >> / C<< $msg->backup_plan($value) >>

Type: C<String>

Output only. The fully qualified name of the BackupPlan bound to the
specified RestorePlan. `projects/*/locations/*/backukpPlans/{backup_plan}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::V1::RestorePlanBinding::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
