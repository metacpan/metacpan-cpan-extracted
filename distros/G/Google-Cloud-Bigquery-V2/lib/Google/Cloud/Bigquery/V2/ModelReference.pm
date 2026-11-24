package Google::Cloud::Bigquery::V2::ModelReference;

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
Ci5nb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvbW9kZWxfcmVmZXJlbmNlLnByb3RvEhhnb29n
bGUuY2xvdWQuYmlncXVlcnkudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8i
eAoOTW9kZWxSZWZlcmVuY2USIgoKcHJvamVjdF9pZBgBIAEoCUID4EECUglwcm9qZWN0SWQS
IgoKZGF0YXNldF9pZBgCIAEoCUID4EECUglkYXRhc2V0SWQSHgoIbW9kZWxfaWQYAyABKAlC
A+BBAlIHbW9kZWxJZEJwChxjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyQhNNb2RlbFJl
ZmVyZW5jZVByb3RvWjtjbG91ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L3YyL2FwaXYyL2Jp
Z3F1ZXJ5cGI7YmlncXVlcnlwYkreCQoGEgQOACQBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMSACkKCAoBCBIDFABSCgkKAggLEgMUAFIK
CAoBCBIDFQA0CgkKAggIEgMVADQKCAoBCBIDFgA1CgkKAggBEgMWADUKIQoCBAASBBkAJAEa
FSBJZCBwYXRoIG9mIGEgbW9kZWwuCgoKCgMEAAESAxkIFgpFCgQEAAIAEgMbAkEaOCBSZXF1
aXJlZC4gVGhlIElEIG9mIHRoZSBwcm9qZWN0IGNvbnRhaW5pbmcgdGhpcyBtb2RlbC4KCgwK
BQQAAgAFEgMbAggKDAoFBAACAAESAxsJEwoMCgUEAAIAAxIDGxYXCgwKBQQAAgAIEgMbGEAK
DwoIBAACAAicCAASAxsZPwpFCgQEAAIBEgMeAkEaOCBSZXF1aXJlZC4gVGhlIElEIG9mIHRo
ZSBkYXRhc2V0IGNvbnRhaW5pbmcgdGhpcyBtb2RlbC4KCgwKBQQAAgEFEgMeAggKDAoFBAAC
AQESAx4JEwoMCgUEAAIBAxIDHhYXCgwKBQQAAgEIEgMeGEAKDwoIBAACAQicCAASAx4ZPwqo
AQoEBAACAhIDIwI/GpoBIFJlcXVpcmVkLiBUaGUgSUQgb2YgdGhlIG1vZGVsLiBUaGUgSUQg
bXVzdCBjb250YWluIG9ubHkKIGxldHRlcnMgKGEteiwgQS1aKSwgbnVtYmVycyAoMC05KSwg
b3IgdW5kZXJzY29yZXMgKF8pLiBUaGUgbWF4aW11bQogbGVuZ3RoIGlzIDEsMDI0IGNoYXJh
Y3RlcnMuCgoMCgUEAAICBRIDIwIICgwKBQQAAgIBEgMjCREKDAoFBAACAgMSAyMUFQoMCgUE
AAICCBIDIxY+Cg8KCAQAAgIInAgAEgMjFz1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::ModelReference::ModelReference ===
    # Fields for ModelReference
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: model_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::ModelReference - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/model_reference.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::ModelReference;

    my $msg = Google::Cloud::Bigquery::V2::ModelReference::ModelReference->new({
        project_id => $project_id,
        dataset_id => $dataset_id,
        model_id => $model_id,
    });

    # Read or update a field
    my $val = $msg->project_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::ModelReference::ModelReference->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/model_reference.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::ModelReference::ModelReference

Id path of a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The ID of the project containing this model.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. The ID of the dataset containing this model.

=item * C<< $msg->model_id() >> / C<< $msg->model_id($value) >>

Type: C<String>

Required. The ID of the model. The ID must contain only
letters (a-z, A-Z), numbers (0-9), or underscores (_). The maximum
length is 1,024 characters.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::ModelReference::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
