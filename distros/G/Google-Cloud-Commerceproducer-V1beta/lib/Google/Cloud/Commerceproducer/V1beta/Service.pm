package Google::Cloud::Commerceproducer::V1beta::Service;

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
    eval { require Google::Cloud::Commerceproducer::V1beta::PrivateOffer };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvY29tbWVyY2Vwcm9kdWNlci92MWJldGEvc2VydmljZS5wcm90bxIk
Z29vZ2xlLmNsb3VkLmNvbW1lcmNlcHJvZHVjZXIudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjhnb29nbGUvY2xv
dWQvY29tbWVyY2Vwcm9kdWNlci92MWJldGEvcHJpdmF0ZV9vZmZlci5wcm90byLQCAoHU2Vy
dmljZRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSGQoFdGl0bGUYAiABKAlCA+BBA1IFdGl0
bGUSeQoUZG9jdW1lbnRfcmVxdWlyZW1lbnQYAyABKAsyQS5nb29nbGUuY2xvdWQuY29tbWVy
Y2Vwcm9kdWNlci52MWJldGEuU2VydmljZS5Eb2N1bWVudFJlcXVpcmVtZW50QgPgQQNSE2Rv
Y3VtZW50UmVxdWlyZW1lbnQSYQoMcHJvZHVjdF90eXBlGAQgASgOMjkuZ29vZ2xlLmNsb3Vk
LmNvbW1lcmNlcHJvZHVjZXIudjFiZXRhLlNlcnZpY2UuUHJvZHVjdFR5cGVCA+BBA1ILcHJv
ZHVjdFR5cGUatwQKE0RvY3VtZW50UmVxdWlyZW1lbnQSlwEKGmRvY3VtZW50X3R5cGVfcmVx
dWlyZW1lbnRzGAEgAygLMlkuZ29vZ2xlLmNsb3VkLmNvbW1lcmNlcHJvZHVjZXIudjFiZXRh
LlNlcnZpY2UuRG9jdW1lbnRSZXF1aXJlbWVudC5Eb2N1bWVudFR5cGVSZXF1aXJlbWVudFIY
ZG9jdW1lbnRUeXBlUmVxdWlyZW1lbnRzGoUDChdEb2N1bWVudFR5cGVSZXF1aXJlbWVudBJs
Cg1kb2N1bWVudF90eXBlGAEgASgOMkcuZ29vZ2xlLmNsb3VkLmNvbW1lcmNlcHJvZHVjZXIu
djFiZXRhLlByaXZhdGVPZmZlckRvY3VtZW50LkRvY3VtZW50VHlwZVIMZG9jdW1lbnRUeXBl
EpcBChFyZXF1aXJlbWVudF9sZXZlbBgCIAEoDjJqLmdvb2dsZS5jbG91ZC5jb21tZXJjZXBy
b2R1Y2VyLnYxYmV0YS5TZXJ2aWNlLkRvY3VtZW50UmVxdWlyZW1lbnQuRG9jdW1lbnRUeXBl
UmVxdWlyZW1lbnQuUmVxdWlyZW1lbnRMZXZlbFIQcmVxdWlyZW1lbnRMZXZlbCJiChBSZXF1
aXJlbWVudExldmVsEiEKHVJFUVVJUkVNRU5UX0xFVkVMX1VOU1BFQ0lGSUVEEAASDAoIUkVR
VUlSRUQQARIMCghPUFRJT05BTBACEg8KC05PVF9BTExPV0VEEAMifAoLUHJvZHVjdFR5cGUS
HAoYUFJPRFVDVF9UWVBFX1VOU1BFQ0lGSUVEEAASGQoVU09GVFdBUkVfQVNfQV9TRVJWSUNF
EAESGQoVQU5BTFlUSUNTX0hVQl9MSVNUSU5HEAISGQoVUFJPRkVTU0lPTkFMX1NFUlZJQ0VT
EAM6e+pBeAonY29tbWVyY2Vwcm9kdWNlci5nb29nbGVhcGlzLmNvbS9TZXJ2aWNlEjpwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc2VydmljZXMve3NlcnZpY2V9
KghzZXJ2aWNlczIHc2VydmljZUKIAgooY29tLmdvb2dsZS5jbG91ZC5jb21tZXJjZXByb2R1
Y2VyLnYxYmV0YUIMU2VydmljZVByb3RvUAFaVGNsb3VkLmdvb2dsZS5jb20vZ28vY29tbWVy
Y2Vwcm9kdWNlci9hcGl2MWJldGEvY29tbWVyY2Vwcm9kdWNlcnBiO2NvbW1lcmNlcHJvZHVj
ZXJwYqoCJEdvb2dsZS5DbG91ZC5Db21tZXJjZVByb2R1Y2VyLlYxQmV0YcoCJEdvb2dsZVxD
bG91ZFxDb21tZXJjZVByb2R1Y2VyXFYxYmV0YeoCJ0dvb2dsZTo6Q2xvdWQ6OkNvbW1lcmNl
UHJvZHVjZXI6OlYxYmV0YUqiIgoGEgQOAHwBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFABCCggK
AQgSAxYAQQoJCgIIJRIDFgBBCggKAQgSAxcAawoJCgIICxIDFwBrCggKAQgSAxgAIgoJCgII
ChIDGAAiCggKAQgSAxkALQoJCgIICBIDGQAtCggKAQgSAxoAQQoJCgIIARIDGgBBCggKAQgS
AxsAQQoJCgIIKRIDGwBBCggKAQgSAxwAQAoJCgIILRIDHABACjIKAgQAEgQfAHwBGiYgTWVz
c2FnZSBkZXNjcmliaW5nIFNlcnZpY2UgcmVzb3VyY2UuCgoKCgMEAAESAx8IDwoLCgMEAAcS
BCACJQQKDQoFBAAHnQgSBCACJQQKVgoEBAADABIEKAJOAxpIIFJlcXVpcmVtZW50cyBhbmQg
Y29uc3RyYWludHMgZm9yIGRvY3VtZW50cyBhdHRhY2hlZCB0byBwcml2YXRlIG9mZmVycy4K
CgwKBQQAAwABEgMoCh0KSQoGBAADAAMAEgQqBEYFGjkgUmVxdWlyZW1lbnQgc3BlY2lmaWNh
dGlvbiBmb3IgYSBzcGVjaWZpYyBkb2N1bWVudCB0eXBlLgoKDgoHBAADAAMAARIDKgwjCjwK
CAQAAwADAAQAEgQsBj8HGiogUmVxdWlyZW1lbnQgbGV2ZWwgZm9yIHRoZSBkb2N1bWVudCB0
eXBlLgoKEAoJBAADAAMABAABEgMsCxsKPwoKBAADAAMABAACABIDLggqGiwgVW5zcGVjaWZp
ZWQgcmVxdWlyZW1lbnQgbGV2ZWwuIERvIG5vdCB1c2UuCgoSCgsEAAMAAwAEAAIAARIDLggl
ChIKCwQAAwADAAQAAgACEgMuKCkKjAEKCgQAAwADAAQAAgESAzIIFRp5IFRoZSBkb2N1bWVu
dCB0eXBlIGlzIG1hbmRhdG9yeSBmb3IgcHJpdmF0ZSBvZmZlcnMgb24gdGhpcyBzZXJ2aWNl
LgogRXhhY3RseSBvbmUgZG9jdW1lbnQgb2YgdGhpcyB0eXBlIG11c3QgYmUgYXR0YWNoZWQu
CgoSCgsEAAMAAwAEAAIBARIDMggQChIKCwQAAwADAAQAAgECEgMyExQKigEKCgQAAwADAAQA
AgISAzYIFRp3IFRoZSBkb2N1bWVudCB0eXBlIGlzIG9wdGlvbmFsIGZvciBwcml2YXRlIG9m
ZmVycyBvbiB0aGlzIHNlcnZpY2UuCiBBdCBtb3N0IG9uZSBkb2N1bWVudCBvZiB0aGlzIHR5
cGUgbWF5IGJlIGF0dGFjaGVkLgoKEgoLBAADAAMABAACAgESAzYIEAoSCgsEAAMAAwAEAAIC
AhIDNhMUCpQCCgoEAAMAAwAEAAIDEgM+CBgagAIgVGhlIGRvY3VtZW50IHR5cGUgaXMgbm90
IHBlcm1pdHRlZCBmb3IgcHJpdmF0ZSBvZmZlcnMgb24gdGhpcwogc2VydmljZS4gTm8gZG9j
dW1lbnQgb2YgdGhpcyB0eXBlIG1heSBiZSBhdHRhY2hlZC4KCiBBIGRvY3VtZW50IHR5cGUg
b21pdHRlZCBmcm9tIGBkb2N1bWVudF90eXBlX3JlcXVpcmVtZW50c2AgaXMgYWxzbwogbm90
IHBlcm1pdHRlZC4gVGhpcyB2YWx1ZSBpcyB1c2VkIHRvIHN0YXRlIHRoZSByZXN0cmljdGlv
bgogZXhwbGljaXRseS4KChIKCwQAAwADAAQAAgMBEgM+CBMKEgoLBAADAAMABAACAwISAz4W
FwolCggEAAMAAwACABIDQgY6GhQgVGhlIGRvY3VtZW50IHR5cGUuCgoQCgkEAAMAAwACAAYS
A0IGJwoQCgkEAAMAAwACAAESA0IoNQoQCgkEAAMAAwACAAMSA0I4OQpACggEAAMAAwACARID
RQYtGi8gVGhlIHJlcXVpcmVtZW50IGxldmVsIGZvciB0aGlzIGRvY3VtZW50IHR5cGUuCgoQ
CgkEAAMAAwACAQYSA0UGFgoQCgkEAAMAAwACAQESA0UXKAoQCgkEAAMAAwACAQMSA0UrLAqH
AgoGBAADAAIAEgNNBEQa9wEgRG9jdW1lbnQgcmVxdWlyZW1lbnRzIGZvciBwcml2YXRlIG9m
ZmVycyBvbiB0aGlzIHNlcnZpY2UuCgogRWFjaCBkb2N1bWVudCB0eXBlIGFwcGVhcnMgYXQg
bW9zdCBvbmNlLiBUaGUgb3JkZXIgb2YgZW50cmllcyBpcyBub3QKIHNpZ25pZmljYW50LiBB
IGRvY3VtZW50IHR5cGUgdGhhdCBpcyBub3QgcHJlc2VudCBpbiB0aGlzIGxpc3QgaXMgbm90
CiBwZXJtaXR0ZWQgZm9yIHByaXZhdGUgb2ZmZXJzIG9uIHRoaXMgc2VydmljZS4KCg4KBwQA
AwACAAQSA00EDAoOCgcEAAMAAgAGEgNNDSQKDgoHBAADAAIAARIDTSU/Cg4KBwQAAwACAAMS
A01CQwrBAwoEBAAEABIEWQJoAxqyAyBUaGUgdHlwZSBvZiB0aGUgcHJvZHVjdCB0aGlzIHNl
cnZpY2UgY29tbWVyY2lhbGl6ZXMuCgogRXZlcnkgc2VydmljZSBoYXMgYSB0eXBlLCBidXQg
b25seSB0aGUgdHlwZXMgbGlzdGVkIGJlbG93IGFyZSBleHBvc2VkLiBBCiBzZXJ2aWNlIHdo
b3NlIHR5cGUgaXMgbm90IG9uZSBvZiB0aGUgbGlzdGVkIHZhbHVlcyByZXBvcnRzCiBgUFJP
RFVDVF9UWVBFX1VOU1BFQ0lGSUVEYC4KCiBWYWx1ZXMgbWF5IGJlIGFkZGVkIG92ZXIgdGlt
ZS4gQ2xpZW50cyBtdXN0IGhhbmRsZSB1bnJlY29nbml6ZWQgdmFsdWVzLgogV2hlbiBuZXcg
dmFsdWVzIGFyZSBhZGRlZCwgdGhlIFByb2R1Y3RUeXBlIGZvciBhbiBleGlzdGluZyBzZXJ2
aWNlIG1heQogY2hhbmdlLiBDbGllbnRzIG11c3QgYWxzbyBiZSBhYmxlIHRvIGhhbmRsZSBh
IGNoYW5nZSBpbiBQcm9kdWN0VHlwZS4KCgwKBQQABAABEgNZBxIKVgoGBAAEAAIAEgNbBCEa
RyBUaGUgc2VydmljZSBoYXMgYSB0eXBlLCBidXQgaXQgaXMgbm90IG9uZSBvZiB0aGUgdHlw
ZXMgZXhwb3NlZCBiZWxvdy4KCg4KBwQABAACAAESA1sEHAoOCgcEAAQAAgACEgNbHyAKiQEK
BgQABAACARIDXwQeGnogUmVwcmVzZW50cyBhIHNvZnR3YXJlLWFzLWEtc2VydmljZSBwcm9k
dWN0LiBTZWUKIGh0dHBzOi8vZG9jcy5jbG91ZC5nb29nbGUuY29tL21hcmtldHBsYWNlL2Rv
Y3MvcGFydG5lcnMvaW50ZWdyYXRlZC1zYWFzCgoOCgcEAAQAAgEBEgNfBBkKDgoHBAAEAAIB
AhIDXxwdCpsBCgYEAAQAAgISA2MEHhqLASBSZXByZXNlbnRzIGEgZGF0YSBwcm9kdWN0IG9u
IEJpZ1F1ZXJ5IHNoYXJpbmcgKGZvcm1lcmx5IEFuYWx5dGljcyBIdWIpLgogU2VlIGh0dHBz
Oi8vZG9jcy5jbG91ZC5nb29nbGUuY29tL21hcmtldHBsYWNlL2RvY3MvcGFydG5lcnMvZGF0
YQoKDgoHBAAEAAICARIDYwQZCg4KBwQABAACAgISA2McHQqQAQoGBAAEAAIDEgNnBB4agAEg
UmVwcmVzZW50cyBhIHByb2Zlc3Npb25hbCBzZXJ2aWNlcyBwcm9kdWN0LiBTZWUKIGh0dHBz
Oi8vZG9jcy5jbG91ZC5nb29nbGUuY29tL21hcmtldHBsYWNlL2RvY3MvcGFydG5lcnMvcHJv
ZmVzc2lvbmFsLXNlcnZpY2VzCgoOCgcEAAQAAgMBEgNnBBkKDgoHBAAEAAIDAhIDZxwdCiwK
BAQAAgASA2sCPRofIElkZW50aWZpZXIuIE5hbWUgb2YgcmVzb3VyY2UuCgoMCgUEAAIABRID
awIICgwKBQQAAgABEgNrCQ0KDAoFBAACAAMSA2sQEQoMCgUEAAIACBIDaxI8Cg8KCAQAAgAI
nAgAEgNrEzsKWgoEBAACARIDcAI/Gk0gT3V0cHV0IG9ubHkuIFRpdGxlIG9mIHRoZSBzZXJ2
aWNlLgoKIE5vdCBpbmNsdWRlZCBmb3IgYFNFUlZJQ0VfVklFV19CQVNJQ2AuCgoMCgUEAAIB
BRIDcAIICgwKBQQAAgEBEgNwCQ4KDAoFBAACAQMSA3AREgoMCgUEAAIBCBIDcBM+Cg8KCAQA
AgEInAgAEgNwFD0KlwIKBAQAAgISBHcCeDIaiAIgT3V0cHV0IG9ubHkuIERvY3VtZW50IHJl
cXVpcmVtZW50IGZvciBwcml2YXRlIG9mZmVycyBvbiB0aGlzIHNlcnZpY2UuCgogQ29uc3Ry
YWludHMgdGhhdCBhcHBseSB0byBldmVyeSBzZXJ2aWNlLCBzdWNoIGFzIHRoZSByZXN0cmlj
dGlvbiBhZ2FpbnN0CiBhdHRhY2hpbmcgYm90aCBhIHN0YW5kYXJkIGFuZCBhIGN1c3RvbSBF
VUxBLCBhcmUgZG9jdW1lbnRlZCBvbgogYFByaXZhdGVPZmZlckRvY3VtZW50YCBhbmQgYXJl
IG5vdCByZXByZXNlbnRlZCBoZXJlLgoKDAoFBAACAgYSA3cCFQoMCgUEAAICARIDdxYqCgwK
BQQAAgIDEgN3LS4KDAoFBAACAggSA3gGMQoPCggEAAICCJwIABIDeAcwCkwKBAQAAgMSA3sC
Sxo/IE91dHB1dCBvbmx5LiBUeXBlIG9mIHRoZSBwcm9kdWN0IHRoaXMgc2VydmljZSBjb21t
ZXJjaWFsaXplcy4KCgwKBQQAAgMGEgN7Ag0KDAoFBAACAwESA3sOGgoMCgUEAAIDAxIDex0e
CgwKBQQAAgMIEgN7H0oKDwoIBAACAwicCAASA3sgSWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Commerceproducer::V1beta::Service::Service ===
    # Fields for Service
    # Field: name Type: 9 ()
    # Field: title Type: 9 ()
    # Field: document_requirement Type: 11 (.google.cloud.commerceproducer.v1beta.Service.DocumentRequirement)
    # Field: product_type Type: 14 (.google.cloud.commerceproducer.v1beta.Service.ProductType)

# Enum: Service::ProductType
our $Service_PRODUCT_TYPE_UNSPECIFIED = 0;
our $Service_SOFTWARE_AS_A_SERVICE = 1;
our $Service_ANALYTICS_HUB_LISTING = 2;
our $Service_PROFESSIONAL_SERVICES = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Commerceproducer::V1beta::Service - Compiled Protocol Buffers messages for google/cloud/commerceproducer/v1beta/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Commerceproducer::V1beta::Service;

    my $msg = Google::Cloud::Commerceproducer::V1beta::Service::Service->new({
        name => $name,
        title => $title,
        document_requirement => $document_requirement,
        product_type => $product_type,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Commerceproducer::V1beta::Service::Service->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/commerceproducer/v1beta/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Commerceproducer::V1beta::Service::Service

Message describing Service resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Name of resource.

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Output only. Title of the service.

Not included for `SERVICE_VIEW_BASIC`.

=item * C<< $msg->document_requirement() >> / C<< $msg->document_requirement($value) >>

Type: C<Message> (L<Google::Cloud::Commerceproducer::V1beta::Service::Service::DocumentRequirement>)

Output only. Document requirement for private offers on this service.

Constraints that apply to every service, such as the restriction against
attaching both a standard and a custom EULA, are documented on
`PrivateOfferDocument` and are not represented here.

=item * C<< $msg->product_type() >> / C<< $msg->product_type($value) >>

Type: C<Enum> (L<Google::Cloud::Commerceproducer::V1beta::Service::ProductType>)

Output only. Type of the product this service commercializes.

=back

=head3 Enum: Service::ProductType

=over 4

=item * C<PRODUCT_TYPE_UNSPECIFIED> => C<0>

=item * C<SOFTWARE_AS_A_SERVICE> => C<1>

=item * C<ANALYTICS_HUB_LISTING> => C<2>

=item * C<PROFESSIONAL_SERVICES> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Commerceproducer::V1beta::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
