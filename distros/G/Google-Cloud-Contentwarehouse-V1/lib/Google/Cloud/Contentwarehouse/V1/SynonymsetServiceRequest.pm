package Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest;

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
    eval { require Google::Cloud::Contentwarehouse::V1::Synonymset };
    my $descriptor_b64 = <<'EOF';
CkFnb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9zeW5vbnltc2V0X3NlcnZpY2Vf
cmVxdWVzdC5wcm90bxIgZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEaH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8a
MWdvb2dsZS9jbG91ZC9jb250ZW50d2FyZWhvdXNlL3YxL3N5bm9ueW1zZXQucHJvdG8itwEK
F0NyZWF0ZVN5bm9ueW1TZXRSZXF1ZXN0EkgKBnBhcmVudBgBIAEoCUIw4EEC+kEqCihjb250
ZW50d2FyZWhvdXNlLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSUgoLc3lub255
bV9zZXQYAiABKAsyLC5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5TeW5vbnlt
U2V0QgPgQQJSCnN5bm9ueW1TZXQiXgoUR2V0U3lub255bVNldFJlcXVlc3QSRgoEbmFtZRgB
IAEoCUIy4EEC+kEsCipjb250ZW50d2FyZWhvdXNlLmdvb2dsZWFwaXMuY29tL1N5bm9ueW1T
ZXRSBG5hbWUingEKFkxpc3RTeW5vbnltU2V0c1JlcXVlc3QSSAoGcGFyZW50GAEgASgJQjDg
QQL6QSoKKGNvbnRlbnR3YXJlaG91c2UuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVu
dBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBh
Z2VUb2tlbiKSAQoXTGlzdFN5bm9ueW1TZXRzUmVzcG9uc2USTwoMc3lub255bV9zZXRzGAEg
AygLMiwuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuU3lub255bVNldFILc3lu
b255bVNldHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIrUBChdV
cGRhdGVTeW5vbnltU2V0UmVxdWVzdBJGCgRuYW1lGAEgASgJQjLgQQL6QSwKKmNvbnRlbnR3
YXJlaG91c2UuZ29vZ2xlYXBpcy5jb20vU3lub255bVNldFIEbmFtZRJSCgtzeW5vbnltX3Nl
dBgCIAEoCzIsLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlN5bm9ueW1TZXRC
A+BBAlIKc3lub255bVNldCJhChdEZWxldGVTeW5vbnltU2V0UmVxdWVzdBJGCgRuYW1lGAEg
ASgJQjLgQQL6QSwKKmNvbnRlbnR3YXJlaG91c2UuZ29vZ2xlYXBpcy5jb20vU3lub255bVNl
dFIEbmFtZUKFAgokY29tLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxQh1TeW5v
bnltU2V0U2VydmljZVJlcXVlc3RQcm90b1ABWlBjbG91ZC5nb29nbGUuY29tL2dvL2NvbnRl
bnR3YXJlaG91c2UvYXBpdjEvY29udGVudHdhcmVob3VzZXBiO2NvbnRlbnR3YXJlaG91c2Vw
YqoCIEdvb2dsZS5DbG91ZC5Db250ZW50V2FyZWhvdXNlLlYxygIgR29vZ2xlXENsb3VkXENv
bnRlbnRXYXJlaG91c2VcVjHqAiNHb29nbGU6OkNsb3VkOjpDb250ZW50V2FyZWhvdXNlOjpW
MUqKHQoGEgQOAHwBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAApCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA7CggKAQgSAxYAPQoJCgIIJRID
FgA9CggKAQgSAxcAZwoJCgIICxIDFwBnCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkA
PgoJCgIICBIDGQA+CggKAQgSAxoAPQoJCgIIARIDGgA9CggKAQgSAxsAPQoJCgIIKRIDGwA9
CggKAQgSAxwAPAoJCgIILRIDHAA8CkUKAgQAEgQfACsBGjkgUmVxdWVzdCBtZXNzYWdlIGZv
ciBTeW5vbnltU2V0U2VydmljZS5DcmVhdGVTeW5vbnltU2V0LgoKCgoDBAABEgMfCB8KYwoE
BAACABIEIgInBBpVIFJlcXVpcmVkLiBUaGUgcGFyZW50IG5hbWUuCiBGb3JtYXQ6IHByb2pl
Y3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0uCgoMCgUEAAIABRID
IgIICgwKBQQAAgABEgMiCQ8KDAoFBAACAAMSAyISEwoNCgUEAAIACBIEIhQnAwoPCggEAAIA
CJwIABIDIwQqCg8KBwQAAgAInwgSBCQEJgUKQwoEBAACARIDKgJGGjYgUmVxdWlyZWQuIFRo
ZSBzeW5vbnltU2V0IHRvIGJlIGNyZWF0ZWQgZm9yIGEgY29udGV4dAoKDAoFBAACAQYSAyoC
DAoMCgUEAAIBARIDKg0YCgwKBQQAAgEDEgMqGxwKDAoFBAACAQgSAyodRQoPCggEAAIBCJwI
ABIDKh5ECnEKAgQBEgQvADkBGmUgUmVxdWVzdCBtZXNzYWdlIGZvciBTeW5vbnltU2V0U2Vy
dmljZS5HZXRTeW5vbnltU2V0LgogV2lsbCByZXR1cm4gc3lub255bVNldCBmb3IgYSBjZXJ0
YWluIGNvbnRleHQuCgoKCgMEAQESAy8IHAqRAQoEBAECABIEMwI4BBqCASBSZXF1aXJlZC4g
VGhlIG5hbWUgb2YgdGhlIHN5bm9ueW1TZXQgdG8gcmV0cmlldmUKIEZvcm1hdDoKIHByb2pl
Y3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc3lub255bVNldHMv
e2NvbnRleHR9LgoKDAoFBAECAAUSAzMCCAoMCgUEAQIAARIDMwkNCgwKBQQBAgADEgMzEBEK
DQoFBAECAAgSBDMSOAMKDwoIBAECAAicCAASAzQEKgoPCgcEAQIACJ8IEgQ1BDcFCoQBCgIE
AhIEPQBTARp4IFJlcXVlc3QgbWVzc2FnZSBmb3IgU3lub255bVNldFNlcnZpY2UuTGlzdFN5
bm9ueW1TZXRzLgogV2lsbCByZXR1cm4gYWxsIHN5bm9ueW1TZXRzIGJlbG9uZ2luZyB0byB0
aGUgY3VzdG9tZXIgcHJvamVjdC4KCgoKAwQCARIDPQgeCmMKBAQCAgASBEACRQQaVSBSZXF1
aXJlZC4gVGhlIHBhcmVudCBuYW1lLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdF9udW1i
ZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259LgoKDAoFBAICAAUSA0ACCAoMCgUEAgIAARIDQAkP
CgwKBQQCAgADEgNAEhMKDQoFBAICAAgSBEAURQMKDwoIBAICAAicCAASA0EEKgoPCgcEAgIA
CJ8IEgRCBEQFCuoBCgQEAgIBEgNLAhYa3AEgVGhlIG1heGltdW0gbnVtYmVyIG9mIHN5bm9u
eW1TZXRzIHRvIHJldHVybi4gVGhlIHNlcnZpY2UgbWF5IHJldHVybgogZmV3ZXIgdGhhbiB0
aGlzIHZhbHVlLgogSWYgdW5zcGVjaWZpZWQsIGF0IG1vc3QgNTAgcnVsZSBzZXRzIHdpbGwg
YmUgcmV0dXJuZWQuCiBUaGUgbWF4aW11bSB2YWx1ZSBpcyAxMDAwOyB2YWx1ZXMgYWJvdmUg
MTAwMCB3aWxsIGJlIGNvZXJjZWQgdG8gMTAwMC4KCgwKBQQCAgEFEgNLAgcKDAoFBAICAQES
A0sIEQoMCgUEAgIBAxIDSxQVCvYBCgQEAgICEgNSAhga6AEgQSBwYWdlIHRva2VuLCByZWNl
aXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RTeW5vbnltU2V0c2AgY2FsbC4KIFByb3ZpZGUg
dGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKIFdoZW4gcGFnaW5hdGlu
ZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8gYExpc3RTeW5vbnltU2V0c2AK
IG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZSB0b2tlbi4KCgwK
BQQCAgIFEgNSAggKDAoFBAICAgESA1IJEwoMCgUEAgICAxIDUhYXCkUKAgQDEgRWAF0BGjkg
UmVzcG9uc2UgbWVzc2FnZSBmb3IgU3lub255bVNldFNlcnZpY2UuTGlzdFN5bm9ueW1TZXRz
LgoKCgoDBAMBEgNWCB8KOQoEBAMCABIDWAInGiwgVGhlIHN5bm9ueW1TZXRzIGZyb20gdGhl
IHNwZWNpZmllZCBwYXJlbnQuCgoMCgUEAwIABBIDWAIKCgwKBQQDAgAGEgNYCxUKDAoFBAMC
AAESA1gWIgoMCgUEAwIAAxIDWCUmCnwKBAQDAgESA1wCHRpvIEEgcGFnZSB0b2tlbiwgcmVj
ZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0U3lub255bVNldHNgIGNhbGwuCiBQcm92aWRl
IHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCgwKBQQDAgEFEgNcAggK
DAoFBAMCAQESA1wJGAoMCgUEAwIBAxIDXBscCq4BCgIEBBIEYgBvARqhASBSZXF1ZXN0IG1l
c3NhZ2UgZm9yIFN5bm9ueW1TZXRTZXJ2aWNlLlVwZGF0ZVN5bm9ueW1TZXQuCiBSZW1vdmVz
IHRoZSBTeW5vbnltU2V0IGZvciB0aGUgc3BlY2lmaWVkIGNvbnRleHQgYW5kIHJlcGxhY2Vz
CiBpdCB3aXRoIHRoZSBTeW5vbnltU2V0IGluIHRoaXMgcmVxdWVzdC4KCgoKAwQEARIDYggf
Co8BCgQEBAIAEgRmAmsEGoABIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgc3lub255bVNl
dCB0byB1cGRhdGUKIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vc3lub255bVNldHMve2NvbnRleHR9LgoKDAoFBAQCAAUSA2YCCAoM
CgUEBAIAARIDZgkNCgwKBQQEAgADEgNmEBEKDQoFBAQCAAgSBGYSawMKDwoIBAQCAAicCAAS
A2cEKgoPCgcEBAIACJ8IEgRoBGoFCkYKBAQEAgESA24CRho5IFJlcXVpcmVkLiBUaGUgc3lu
b255bVNldCB0byBiZSB1cGRhdGVkIGZvciB0aGUgY3VzdG9tZXIKCgwKBQQEAgEGEgNuAgwK
DAoFBAQCAQESA24NGAoMCgUEBAIBAxIDbhscCgwKBQQEAgEIEgNuHUUKDwoIBAQCAQicCAAS
A24eRApFCgIEBRIEcgB8ARo5IFJlcXVlc3QgbWVzc2FnZSBmb3IgU3lub255bVNldFNlcnZp
Y2UuRGVsZXRlU3lub255bVNldC4KCgoKAwQFARIDcggfCo8BCgQEBQIAEgR2AnsEGoABIFJl
cXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgc3lub255bVNldCB0byBkZWxldGUKIEZvcm1hdDoK
IHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc3lub255
bVNldHMve2NvbnRleHR9LgoKDAoFBAUCAAUSA3YCCAoMCgUEBQIAARIDdgkNCgwKBQQFAgAD
EgN2EBEKDQoFBAUCAAgSBHYSewMKDwoIBAUCAAicCAASA3cEKgoPCgcEBQIACJ8IEgR4BHoF
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::CreateSynonymSetRequest ===
    # Fields for CreateSynonymSetRequest
    # Field: parent Type: 9 ()
    # Field: synonym_set Type: 11 (.google.cloud.contentwarehouse.v1.SynonymSet)

# === Message: Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::GetSynonymSetRequest ===
    # Fields for GetSynonymSetRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::ListSynonymSetsRequest ===
    # Fields for ListSynonymSetsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::ListSynonymSetsResponse ===
    # Fields for ListSynonymSetsResponse
    # Field: synonym_sets Type: 11 (.google.cloud.contentwarehouse.v1.SynonymSet)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::UpdateSynonymSetRequest ===
    # Fields for UpdateSynonymSetRequest
    # Field: name Type: 9 ()
    # Field: synonym_set Type: 11 (.google.cloud.contentwarehouse.v1.SynonymSet)

# === Message: Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::DeleteSynonymSetRequest ===
    # Fields for DeleteSynonymSetRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/synonymset_service_request.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest;

    my $msg = Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::CreateSynonymSetRequest->new({
        parent => $parent,
        synonym_set => $synonym_set,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::CreateSynonymSetRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/synonymset_service_request.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::CreateSynonymSetRequest

Request message for SynonymSetService.CreateSynonymSet.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent name.
Format: projects/{project_number}/locations/{location}.

=item * C<< $msg->synonym_set() >> / C<< $msg->synonym_set($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet>)

Required. The synonymSet to be created for a context

=back

=head2 Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::GetSynonymSetRequest

Request message for SynonymSetService.GetSynonymSet.
Will return synonymSet for a certain context.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the synonymSet to retrieve
Format:
projects/{project_number}/locations/{location}/synonymSets/{context}.

=back

=head2 Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::ListSynonymSetsRequest

Request message for SynonymSetService.ListSynonymSets.
Will return all synonymSets belonging to the customer project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent name.
Format: projects/{project_number}/locations/{location}.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of synonymSets to return. The service may return
fewer than this value.
If unspecified, at most 50 rule sets will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListSynonymSets` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListSynonymSets`
must match the call that provided the page token.

=back

=head2 Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::ListSynonymSetsResponse

Response message for SynonymSetService.ListSynonymSets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->synonym_sets() >> / C<< $msg->synonym_sets($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet>)

The synonymSets from the specified parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A page token, received from a previous `ListSynonymSets` call.
Provide this to retrieve the subsequent page.

=back

=head2 Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::UpdateSynonymSetRequest

Request message for SynonymSetService.UpdateSynonymSet.
Removes the SynonymSet for the specified context and replaces
it with the SynonymSet in this request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the synonymSet to update
Format:
projects/{project_number}/locations/{location}/synonymSets/{context}.

=item * C<< $msg->synonym_set() >> / C<< $msg->synonym_set($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet>)

Required. The synonymSet to be updated for the customer

=back

=head2 Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::DeleteSynonymSetRequest

Request message for SynonymSetService.DeleteSynonymSet.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the synonymSet to delete
Format:
projects/{project_number}/locations/{location}/synonymSets/{context}.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
