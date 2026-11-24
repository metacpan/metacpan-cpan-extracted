package Google::Cloud::Netapp::V1::Ontap;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvY2xvdWQvbmV0YXBwL3YxL29udGFwLnByb3RvEhZnb29nbGUuY2xvdWQubmV0
YXBwLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhxnb29nbGUvcHJvdG9i
dWYvc3RydWN0LnByb3RvIm8KF0V4ZWN1dGVPbnRhcFBvc3RSZXF1ZXN0EjAKBGJvZHkYAiAB
KAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0QgPgQQJSBGJvZHkSIgoKb250YXBfcGF0aBgD
IAEoCUID4EECUglvbnRhcFBhdGgiRwoYRXhlY3V0ZU9udGFwUG9zdFJlc3BvbnNlEisKBGJv
ZHkYASABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0UgRib2R5IjwKFkV4ZWN1dGVPbnRh
cEdldFJlcXVlc3QSIgoKb250YXBfcGF0aBgBIAEoCUID4EECUglvbnRhcFBhdGgiRgoXRXhl
Y3V0ZU9udGFwR2V0UmVzcG9uc2USKwoEYm9keRgBIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5T
dHJ1Y3RSBGJvZHkiPwoZRXhlY3V0ZU9udGFwRGVsZXRlUmVxdWVzdBIiCgpvbnRhcF9wYXRo
GAIgASgJQgPgQQJSCW9udGFwUGF0aCJJChpFeGVjdXRlT250YXBEZWxldGVSZXNwb25zZRIr
CgRib2R5GAEgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIEYm9keSJwChhFeGVjdXRl
T250YXBQYXRjaFJlcXVlc3QSMAoEYm9keRgCIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1
Y3RCA+BBAlIEYm9keRIiCgpvbnRhcF9wYXRoGAMgASgJQgPgQQJSCW9udGFwUGF0aCJIChlF
eGVjdXRlT250YXBQYXRjaFJlc3BvbnNlEisKBGJvZHkYASABKAsyFy5nb29nbGUucHJvdG9i
dWYuU3RydWN0UgRib2R5QqwBChpjb20uZ29vZ2xlLmNsb3VkLm5ldGFwcC52MUIKT250YXBQ
cm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL25ldGFwcC9hcGl2MS9uZXRhcHBwYjtuZXRh
cHBwYqoCFkdvb2dsZS5DbG91ZC5OZXRBcHAuVjHKAhZHb29nbGVcQ2xvdWRcTmV0QXBwXFYx
6gIZR29vZ2xlOjpDbG91ZDo6TmV0QXBwOjpWMUrdHQoGEgQOAHUBCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMSACkKCQoCAwESAxMAJgoI
CgEIEgMVADMKCQoCCCUSAxUAMwoICgEIEgMWAEkKCQoCCAsSAxYASQoICgEIEgMXACIKCQoC
CAoSAxcAIgoICgEIEgMYACsKCQoCCAgSAxgAKwoICgEIEgMZADMKCQoCCAESAxkAMwoICgEI
EgMaADMKCQoCCCkSAxoAMwoICgEIEgMbADIKCQoCCC0SAxsAMgo5CgIEABIEHgAyARotIFJl
cXVlc3QgbWVzc2FnZSBmb3IgYEV4ZWN1dGVPbnRhcFBvc3RgIEFQSS4KCgoKAwQAARIDHggf
CtgBCgQEAAIAEgMqAksaygEgUmVxdWlyZWQuIFRoZSByYXcgYEpTT05gIGJvZHkgb2YgdGhl
IHJlcXVlc3QuCiBUaGUgYm9keSBzaG91bGQgYmUgaW4gdGhlIGZvcm1hdCBvZiB0aGUgT05U
QVAgcmVzb3VyY2UuCiBGb3IgZXhhbXBsZToKIGBgYAogewogICAiYm9keSI6IHsKICAgICAi
ZmllbGQxIjogInZhbHVlMSIsCiAgICAgImZpZWxkMiI6ICJ2YWx1ZTIiLAogICB9CiB9CiBg
YGAKCgwKBQQAAgAGEgMqAhgKDAoFBAACAAESAyoZHQoMCgUEAAIAAxIDKiAhCgwKBQQAAgAI
EgMqIkoKDwoIBAACAAicCAASAyojSQqlAgoEBAACARIDMQJBGpcCIFJlcXVpcmVkLiBUaGUg
cGF0aCBvZiB0aGUgT05UQVAgcmVzb3VyY2UuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2pl
Y3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9zdG9yYWdlUG9vbHMve3N0b3Jh
Z2VfcG9vbF9pZH0vb250YXAve29udGFwX3Jlc291cmNlX3BhdGh9YC4KIEZvciBleGFtcGxl
OgogYHByb2plY3RzLzEyMzQ1Njc4OS9sb2NhdGlvbnMvdXMtY2VudHJhbDEvc3RvcmFnZVBv
b2xzL215LXN0b3JhZ2UtcG9vbC9vbnRhcC9hcGkvc3RvcmFnZS92b2x1bWVzYC4KCgwKBQQA
AgEFEgMxAggKDAoFBAACAQESAzEJEwoMCgUEAAIBAxIDMRYXCgwKBQQAAgEIEgMxGEAKDwoI
BAACAQicCAASAzEZPwo6CgIEARIENQA4ARouIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIGBFeGVj
dXRlT250YXBQb3N0YCBBUEkuCgoKCgMEAQESAzUIIAozCgQEAQIAEgM3AiIaJiBUaGUgcmF3
IGBKU09OYCBib2R5IG9mIHRoZSByZXNwb25zZS4KCgwKBQQBAgAGEgM3AhgKDAoFBAECAAES
AzcZHQoMCgUEAQIAAxIDNyAhCjgKAgQCEgQ7AEIBGiwgUmVxdWVzdCBtZXNzYWdlIGZvciBg
RXhlY3V0ZU9udGFwR2V0YCBBUEkuCgoKCgMEAgESAzsIHgquAgoEBAICABIDQQJBGqACIFJl
cXVpcmVkLiBUaGUgcmVzb3VyY2UgcGF0aCBvZiB0aGUgT05UQVAgcmVzb3VyY2UuCiBGb3Jt
YXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lk
fS9zdG9yYWdlUG9vbHMve3N0b3JhZ2VfcG9vbF9pZH0vb250YXAve29udGFwX3Jlc291cmNl
X3BhdGh9YC4KIEZvciBleGFtcGxlOgogYHByb2plY3RzLzEyMzQ1Njc4OS9sb2NhdGlvbnMv
dXMtY2VudHJhbDEvc3RvcmFnZVBvb2xzL215LXN0b3JhZ2UtcG9vbC9vbnRhcC9hcGkvc3Rv
cmFnZS92b2x1bWVzYC4KCgwKBQQCAgAFEgNBAggKDAoFBAICAAESA0EJEwoMCgUEAgIAAxID
QRYXCgwKBQQCAgAIEgNBGEAKDwoIBAICAAicCAASA0EZPwo5CgIEAxIERQBIARotIFJlc3Bv
bnNlIG1lc3NhZ2UgZm9yIGBFeGVjdXRlT250YXBHZXRgIEFQSS4KCgoKAwQDARIDRQgfCjMK
BAQDAgASA0cCIhomIFRoZSByYXcgYEpTT05gIGJvZHkgb2YgdGhlIHJlc3BvbnNlLgoKDAoF
BAMCAAYSA0cCGAoMCgUEAwIAARIDRxkdCgwKBQQDAgADEgNHICEKOwoCBAQSBEsAUgEaLyBS
ZXF1ZXN0IG1lc3NhZ2UgZm9yIGBFeGVjdXRlT250YXBEZWxldGVgIEFQSS4KCgoKAwQEARID
SwghCq4CCgQEBAIAEgNRAkEaoAIgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBwYXRoIG9mIHRo
ZSBPTlRBUCByZXNvdXJjZS4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9
L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L3N0b3JhZ2VQb29scy97c3RvcmFnZV9wb29sX2lk
fS9vbnRhcC97b250YXBfcmVzb3VyY2VfcGF0aH1gLgogRm9yIGV4YW1wbGU6CiBgcHJvamVj
dHMvMTIzNDU2Nzg5L2xvY2F0aW9ucy91cy1jZW50cmFsMS9zdG9yYWdlUG9vbHMvbXktc3Rv
cmFnZS1wb29sL29udGFwL2FwaS9zdG9yYWdlL3ZvbHVtZXNgLgoKDAoFBAQCAAUSA1ECCAoM
CgUEBAIAARIDUQkTCgwKBQQEAgADEgNRFhcKDAoFBAQCAAgSA1EYQAoPCggEBAIACJwIABID
URk/CjwKAgQFEgRVAFgBGjAgUmVzcG9uc2UgbWVzc2FnZSBmb3IgYEV4ZWN1dGVPbnRhcERl
bGV0ZWAgQVBJLgoKCgoDBAUBEgNVCCIKMwoEBAUCABIDVwIiGiYgVGhlIHJhdyBgSlNPTmAg
Ym9keSBvZiB0aGUgcmVzcG9uc2UuCgoMCgUEBQIABhIDVwIYCgwKBQQFAgABEgNXGR0KDAoF
BAUCAAMSA1cgIQo6CgIEBhIEWwBvARouIFJlcXVlc3QgbWVzc2FnZSBmb3IgYEV4ZWN1dGVP
bnRhcFBhdGNoYCBBUEkuCgoKCgMEBgESA1sIIArYAQoEBAYCABIDZwJLGsoBIFJlcXVpcmVk
LiBUaGUgcmF3IGBKU09OYCBib2R5IG9mIHRoZSByZXF1ZXN0LgogVGhlIGJvZHkgc2hvdWxk
IGJlIGluIHRoZSBmb3JtYXQgb2YgdGhlIE9OVEFQIHJlc291cmNlLgogRm9yIGV4YW1wbGU6
CiBgYGAKIHsKICAgImJvZHkiOiB7CiAgICAgImZpZWxkMSI6ICJ2YWx1ZTEiLAogICAgICJm
aWVsZDIiOiAidmFsdWUyIiwKICAgfQogfQogYGBgCgoMCgUEBgIABhIDZwIYCgwKBQQGAgAB
EgNnGR0KDAoFBAYCAAMSA2cgIQoMCgUEBgIACBIDZyJKCg8KCAQGAgAInAgAEgNnI0kKrgIK
BAQGAgESA24CQRqgAiBSZXF1aXJlZC4gVGhlIHJlc291cmNlIHBhdGggb2YgdGhlIE9OVEFQ
IHJlc291cmNlLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRp
b25zL3tsb2NhdGlvbl9pZH0vc3RvcmFnZVBvb2xzL3tzdG9yYWdlX3Bvb2xfaWR9L29udGFw
L3tvbnRhcF9yZXNvdXJjZV9wYXRofWAuCiBGb3IgZXhhbXBsZToKIGBwcm9qZWN0cy8xMjM0
NTY3ODkvbG9jYXRpb25zL3VzLWNlbnRyYWwxL3N0b3JhZ2VQb29scy9teS1zdG9yYWdlLXBv
b2wvb250YXAvYXBpL3N0b3JhZ2Uvdm9sdW1lc2AuCgoMCgUEBgIBBRIDbgIICgwKBQQGAgEB
EgNuCRMKDAoFBAYCAQMSA24WFwoMCgUEBgIBCBIDbhhACg8KCAQGAgEInAgAEgNuGT8KOwoC
BAcSBHIAdQEaLyBSZXNwb25zZSBtZXNzYWdlIGZvciBgRXhlY3V0ZU9udGFwUGF0Y2hgIEFQ
SS4KCgoKAwQHARIDcgghCjMKBAQHAgASA3QCIhomIFRoZSByYXcgYEpTT05gIGJvZHkgb2Yg
dGhlIHJlc3BvbnNlLgoKDAoFBAcCAAYSA3QCGAoMCgUEBwIAARIDdBkdCgwKBQQHAgADEgN0
ICFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPostRequest ===
    # Fields for ExecuteOntapPostRequest
    # Field: body Type: 11 (.google.protobuf.Struct)
    # Field: ontap_path Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPostResponse ===
    # Fields for ExecuteOntapPostResponse
    # Field: body Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Netapp::V1::Ontap::ExecuteOntapGetRequest ===
    # Fields for ExecuteOntapGetRequest
    # Field: ontap_path Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Ontap::ExecuteOntapGetResponse ===
    # Fields for ExecuteOntapGetResponse
    # Field: body Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Netapp::V1::Ontap::ExecuteOntapDeleteRequest ===
    # Fields for ExecuteOntapDeleteRequest
    # Field: ontap_path Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Ontap::ExecuteOntapDeleteResponse ===
    # Fields for ExecuteOntapDeleteResponse
    # Field: body Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPatchRequest ===
    # Fields for ExecuteOntapPatchRequest
    # Field: body Type: 11 (.google.protobuf.Struct)
    # Field: ontap_path Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPatchResponse ===
    # Fields for ExecuteOntapPatchResponse
    # Field: body Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Netapp::V1::Ontap - Compiled Protocol Buffers messages for google/cloud/netapp/v1/ontap.proto

=head1 SYNOPSIS

    use Google::Cloud::Netapp::V1::Ontap;

    my $msg = Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPostRequest->new({
        body => $body,
        ontap_path => $ontap_path,
    });

    # Read or update a field
    my $val = $msg->body();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPostRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/netapp/v1/ontap.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPostRequest

Request message for `ExecuteOntapPost` API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Required. The raw `JSON` body of the request.
The body should be in the format of the ONTAP resource.
For example:
```
{
  "body": {
    "field1": "value1",
    "field2": "value2",
  }
}
```

=item * C<< $msg->ontap_path() >> / C<< $msg->ontap_path($value) >>

Type: C<String>

Required. The path of the ONTAP resource.
Format:
`projects/{project_number}/locations/{location_id}/storagePools/{storage_pool_id}/ontap/{ontap_resource_path}`.
For example:
`projects/123456789/locations/us-central1/storagePools/my-storage-pool/ontap/api/storage/volumes`.

=back

=head2 Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPostResponse

Response message for `ExecuteOntapPost` API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The raw `JSON` body of the response.

=back

=head2 Google::Cloud::Netapp::V1::Ontap::ExecuteOntapGetRequest

Request message for `ExecuteOntapGet` API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ontap_path() >> / C<< $msg->ontap_path($value) >>

Type: C<String>

Required. The resource path of the ONTAP resource.
Format:
`projects/{project_number}/locations/{location_id}/storagePools/{storage_pool_id}/ontap/{ontap_resource_path}`.
For example:
`projects/123456789/locations/us-central1/storagePools/my-storage-pool/ontap/api/storage/volumes`.

=back

=head2 Google::Cloud::Netapp::V1::Ontap::ExecuteOntapGetResponse

Response message for `ExecuteOntapGet` API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The raw `JSON` body of the response.

=back

=head2 Google::Cloud::Netapp::V1::Ontap::ExecuteOntapDeleteRequest

Request message for `ExecuteOntapDelete` API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ontap_path() >> / C<< $msg->ontap_path($value) >>

Type: C<String>

Required. The resource path of the ONTAP resource.
Format:
`projects/{project_number}/locations/{location_id}/storagePools/{storage_pool_id}/ontap/{ontap_resource_path}`.
For example:
`projects/123456789/locations/us-central1/storagePools/my-storage-pool/ontap/api/storage/volumes`.

=back

=head2 Google::Cloud::Netapp::V1::Ontap::ExecuteOntapDeleteResponse

Response message for `ExecuteOntapDelete` API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The raw `JSON` body of the response.

=back

=head2 Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPatchRequest

Request message for `ExecuteOntapPatch` API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Required. The raw `JSON` body of the request.
The body should be in the format of the ONTAP resource.
For example:
```
{
  "body": {
    "field1": "value1",
    "field2": "value2",
  }
}
```

=item * C<< $msg->ontap_path() >> / C<< $msg->ontap_path($value) >>

Type: C<String>

Required. The resource path of the ONTAP resource.
Format:
`projects/{project_number}/locations/{location_id}/storagePools/{storage_pool_id}/ontap/{ontap_resource_path}`.
For example:
`projects/123456789/locations/us-central1/storagePools/my-storage-pool/ontap/api/storage/volumes`.

=back

=head2 Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPatchResponse

Response message for `ExecuteOntapPatch` API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The raw `JSON` body of the response.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Netapp::V1::Ontap::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
