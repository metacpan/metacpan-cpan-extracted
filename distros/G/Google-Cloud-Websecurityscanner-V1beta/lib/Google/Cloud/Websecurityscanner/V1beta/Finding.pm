package Google::Cloud::Websecurityscanner::V1beta::Finding;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Websecurityscanner::V1beta::FindingAddon };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYmV0YS9maW5kaW5nLnByb3Rv
EiZnb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YRoZZ29vZ2xlL2FwaS9y
ZXNvdXJjZS5wcm90bxo6Z29vZ2xlL2Nsb3VkL3dlYnNlY3VyaXR5c2Nhbm5lci92MWJldGEv
ZmluZGluZ19hZGRvbi5wcm90byLvBwoHRmluZGluZxISCgRuYW1lGAEgASgJUgRuYW1lEiEK
DGZpbmRpbmdfdHlwZRgCIAEoCVILZmluZGluZ1R5cGUSHwoLaHR0cF9tZXRob2QYAyABKAlS
Cmh0dHBNZXRob2QSHQoKZnV6emVkX3VybBgEIAEoCVIJZnV6emVkVXJsEhIKBGJvZHkYBSAB
KAlSBGJvZHkSIAoLZGVzY3JpcHRpb24YBiABKAlSC2Rlc2NyaXB0aW9uEikKEHJlcHJvZHVj
dGlvbl91cmwYByABKAlSD3JlcHJvZHVjdGlvblVybBIbCglmcmFtZV91cmwYCCABKAlSCGZy
YW1lVXJsEhsKCWZpbmFsX3VybBgJIAEoCVIIZmluYWxVcmwSHwoLdHJhY2tpbmdfaWQYCiAB
KAlSCnRyYWNraW5nSWQSQAoEZm9ybRgQIAEoCzIsLmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0
eXNjYW5uZXIudjFiZXRhLkZvcm1SBGZvcm0SYgoQb3V0ZGF0ZWRfbGlicmFyeRgLIAEoCzI3
Lmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFiZXRhLk91dGRhdGVkTGlicmFy
eVIPb3V0ZGF0ZWRMaWJyYXJ5EmgKEnZpb2xhdGluZ19yZXNvdXJjZRgMIAEoCzI5Lmdvb2ds
ZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFiZXRhLlZpb2xhdGluZ1Jlc291cmNlUhF2
aW9sYXRpbmdSZXNvdXJjZRJoChJ2dWxuZXJhYmxlX2hlYWRlcnMYDyABKAsyOS5nb29nbGUu
Y2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YS5WdWxuZXJhYmxlSGVhZGVyc1IRdnVs
bmVyYWJsZUhlYWRlcnMScQoVdnVsbmVyYWJsZV9wYXJhbWV0ZXJzGA0gASgLMjwuZ29vZ2xl
LmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEuVnVsbmVyYWJsZVBhcmFtZXRlcnNS
FHZ1bG5lcmFibGVQYXJhbWV0ZXJzEj0KA3hzcxgOIAEoCzIrLmdvb2dsZS5jbG91ZC53ZWJz
ZWN1cml0eXNjYW5uZXIudjFiZXRhLlhzc1IDeHNzOoQB6kGAAQopd2Vic2VjdXJpdHlzY2Fu
bmVyLmdvb2dsZWFwaXMuY29tL0ZpbmRpbmcSU3Byb2plY3RzL3twcm9qZWN0fS9zY2FuQ29u
Zmlncy97c2Nhbl9jb25maWd9L3NjYW5SdW5zL3tzY2FuX3J1bn0vZmluZGluZ3Mve2ZpbmRp
bmd9QpYCCipjb20uZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGFCDEZp
bmRpbmdQcm90b1ABWlpjbG91ZC5nb29nbGUuY29tL2dvL3dlYnNlY3VyaXR5c2Nhbm5lci9h
cGl2MWJldGEvd2Vic2VjdXJpdHlzY2FubmVycGI7d2Vic2VjdXJpdHlzY2FubmVycGKqAiZH
b29nbGUuQ2xvdWQuV2ViU2VjdXJpdHlTY2FubmVyLlYxQmV0YcoCJkdvb2dsZVxDbG91ZFxX
ZWJTZWN1cml0eVNjYW5uZXJcVjFiZXRh6gIpR29vZ2xlOjpDbG91ZDo6V2ViU2VjdXJpdHlT
Y2FubmVyOjpWMWJldGFKmBoKBhIEDwBhAQq9BAoBDBIDDwASMrIEIENvcHlyaWdodCAyMDI1
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCgoICgECEgMRAC8KCQoCAwASAxMAIwoJCgIDARIDFABECggKAQgSAxYAQwoJCgII
JRIDFgBDCggKAQgSAxcAcQoJCgIICxIDFwBxCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgS
AxkALQoJCgIICBIDGQAtCggKAQgSAxoAQwoJCgIIARIDGgBDCggKAQgSAxsAQwoJCgIIKRID
GwBDCggKAQgSAxwAQgoJCgIILRIDHABCCmIKAgQAEgQgAGEBGlYgQSBGaW5kaW5nIHJlc291
cmNlIHJlcHJlc2VudHMgYSB2dWxuZXJhYmlsaXR5IGluc3RhbmNlIGlkZW50aWZpZWQgZHVy
aW5nIGEKIFNjYW5SdW4uCgoKCgMEAAESAyAIDwoLCgMEAAcSBCECJAQKDQoFBAAHnQgSBCEC
JAQK3AEKBAQAAgASAykCEhrOASBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgRmluZGluZy4g
VGhlIG5hbWUgZm9sbG93cyB0aGUgZm9ybWF0IG9mCiAncHJvamVjdHMve3Byb2plY3RJZH0v
c2NhbkNvbmZpZ3Mve3NjYW5Db25maWdJZH0vc2NhbnJ1bnMve3NjYW5SdW5JZH0vZmluZGlu
Z3Mve2ZpbmRpbmdJZH0nLgogVGhlIGZpbmRpbmcgSURzIGFyZSBnZW5lcmF0ZWQgYnkgdGhl
IHN5c3RlbS4KCgwKBQQAAgAFEgMpAggKDAoFBAACAAESAykJDQoMCgUEAAIAAxIDKRARCrAB
CgQEAAIBEgMuAhoaogEgVGhlIHR5cGUgb2YgdGhlIEZpbmRpbmcuCiBEZXRhaWxlZCBhbmQg
dXAtdG8tZGF0ZSBpbmZvcm1hdGlvbiBvbiBmaW5kaW5ncyBjYW4gYmUgZm91bmQgaGVyZToK
IGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9zZWN1cml0eS1zY2FubmVyL2RvY3Mvc2Nhbi1y
ZXN1bHQtZGV0YWlscwoKDAoFBAACAQUSAy4CCAoMCgUEAAIBARIDLgkVCgwKBQQAAgEDEgMu
GBkKXgoEBAACAhIDMgIZGlEgVGhlIGh0dHAgbWV0aG9kIG9mIHRoZSByZXF1ZXN0IHRoYXQg
dHJpZ2dlcmVkIHRoZSB2dWxuZXJhYmlsaXR5LCBpbgogdXBwZXJjYXNlLgoKDAoFBAACAgUS
AzICCAoMCgUEAAICARIDMgkUCgwKBQQAAgIDEgMyFxgKdAoEBAACAxIDNgIYGmcgVGhlIFVS
TCBwcm9kdWNlZCBieSB0aGUgc2VydmVyLXNpZGUgZnV6emVyIGFuZCB1c2VkIGluIHRoZSBy
ZXF1ZXN0IHRoYXQKIHRyaWdnZXJlZCB0aGUgdnVsbmVyYWJpbGl0eS4KCgwKBQQAAgMFEgM2
AggKDAoFBAACAwESAzYJEwoMCgUEAAIDAxIDNhYXCkgKBAQAAgQSAzkCEho7IFRoZSBib2R5
IG9mIHRoZSByZXF1ZXN0IHRoYXQgdHJpZ2dlcmVkIHRoZSB2dWxuZXJhYmlsaXR5LgoKDAoF
BAACBAUSAzkCCAoMCgUEAAIEARIDOQkNCgwKBQQAAgQDEgM5EBEKNAoEBAACBRIDPAIZGicg
VGhlIGRlc2NyaXB0aW9uIG9mIHRoZSB2dWxuZXJhYmlsaXR5LgoKDAoFBAACBQUSAzwCCAoM
CgUEAAIFARIDPAkUCgwKBQQAAgUDEgM8FxgKcAoEBAACBhIDQAIeGmMgVGhlIFVSTCBjb250
YWluaW5nIGh1bWFuLXJlYWRhYmxlIHBheWxvYWQgdGhhdCB1c2VyIGNhbiBsZXZlcmFnZSB0
bwogcmVwcm9kdWNlIHRoZSB2dWxuZXJhYmlsaXR5LgoKDAoFBAACBgUSA0ACCAoMCgUEAAIG
ARIDQAkZCgwKBQQAAgYDEgNAHB0KcAoEBAACBxIDRAIXGmMgSWYgdGhlIHZ1bG5lcmFiaWxp
dHkgd2FzIG9yaWdpbmF0ZWQgZnJvbSBuZXN0ZWQgSUZyYW1lLCB0aGUgaW1tZWRpYXRlCiBw
YXJlbnQgSUZyYW1lIGlzIHJlcG9ydGVkLgoKDAoFBAACBwUSA0QCCAoMCgUEAAIHARIDRAkS
CgwKBQQAAgcDEgNEFRYKUgoEBAACCBIDRwIXGkUgVGhlIFVSTCB3aGVyZSB0aGUgYnJvd3Nl
ciBsYW5kcyB3aGVuIHRoZSB2dWxuZXJhYmlsaXR5IGlzIGRldGVjdGVkLgoKDAoFBAACCAUS
A0cCCAoMCgUEAAIIARIDRwkSCgwKBQQAAggDEgNHFRYKZgoEBAACCRIDSwIaGlkgVGhlIHRy
YWNraW5nIElEIHVuaXF1ZWx5IGlkZW50aWZpZXMgYSB2dWxuZXJhYmlsaXR5IGluc3RhbmNl
IGFjcm9zcwogbXVsdGlwbGUgU2NhblJ1bnMuCgoMCgUEAAIJBRIDSwIICgwKBQQAAgkBEgNL
CRQKDAoFBAACCQMSA0sXGQpnCgQEAAIKEgNPAhEaWiBBbiBhZGRvbiBjb250YWluaW5nIGlu
Zm9ybWF0aW9uIHJlcG9ydGVkIGZvciBhIHZ1bG5lcmFiaWxpdHkgd2l0aCBhbiBIVE1MCiBm
b3JtLCBpZiBhbnkuCgoMCgUEAAIKBhIDTwIGCgwKBQQAAgoBEgNPBwsKDAoFBAACCgMSA08O
EApICgQEAAILEgNSAigaOyBBbiBhZGRvbiBjb250YWluaW5nIGluZm9ybWF0aW9uIGFib3V0
IG91dGRhdGVkIGxpYnJhcmllcy4KCgwKBQQAAgsGEgNSAhEKDAoFBAACCwESA1ISIgoMCgUE
AAILAxIDUiUnCp8BCgQEAAIMEgNWAiwakQEgQW4gYWRkb24gY29udGFpbmluZyBkZXRhaWxl
ZCBpbmZvcm1hdGlvbiByZWdhcmRpbmcgYW55IHJlc291cmNlIGNhdXNpbmcgdGhlCiB2dWxu
ZXJhYmlsaXR5IHN1Y2ggYXMgSmF2YVNjcmlwdCBzb3VyY2VzLCBpbWFnZSwgYXVkaW8gZmls
ZXMsIGV0Yy4KCgwKBQQAAgwGEgNWAhMKDAoFBAACDAESA1YUJgoMCgUEAAIMAxIDVikrClgK
BAQAAg0SA1kCLBpLIEFuIGFkZG9uIGNvbnRhaW5pbmcgaW5mb3JtYXRpb24gYWJvdXQgdnVs
bmVyYWJsZSBvciBtaXNzaW5nIEhUVFAgaGVhZGVycy4KCgwKBQQAAg0GEgNZAhMKDAoFBAAC
DQESA1kUJgoMCgUEAAINAxIDWSkrCmsKBAQAAg4SA10CMhpeIEFuIGFkZG9uIGNvbnRhaW5p
bmcgaW5mb3JtYXRpb24gYWJvdXQgcmVxdWVzdCBwYXJhbWV0ZXJzIHdoaWNoIHdlcmUgZm91
bmQKIHRvIGJlIHZ1bG5lcmFibGUuCgoMCgUEAAIOBhIDXQIWCgwKBQQAAg4BEgNdFywKDAoF
BAACDgMSA10vMQpLCgQEAAIPEgNgAg8aPiBBbiBhZGRvbiBjb250YWluaW5nIGluZm9ybWF0
aW9uIHJlcG9ydGVkIGZvciBhbiBYU1MsIGlmIGFueS4KCgwKBQQAAg8GEgNgAgUKDAoFBAAC
DwESA2AGCQoMCgUEAAIPAxIDYAwOYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1beta::Finding::Finding ===
    # Fields for Finding
    # Field: name Type: 9 ()
    # Field: finding_type Type: 9 ()
    # Field: http_method Type: 9 ()
    # Field: fuzzed_url Type: 9 ()
    # Field: body Type: 9 ()
    # Field: description Type: 9 ()
    # Field: reproduction_url Type: 9 ()
    # Field: frame_url Type: 9 ()
    # Field: final_url Type: 9 ()
    # Field: tracking_id Type: 9 ()
    # Field: form Type: 11 (.google.cloud.websecurityscanner.v1beta.Form)
    # Field: outdated_library Type: 11 (.google.cloud.websecurityscanner.v1beta.OutdatedLibrary)
    # Field: violating_resource Type: 11 (.google.cloud.websecurityscanner.v1beta.ViolatingResource)
    # Field: vulnerable_headers Type: 11 (.google.cloud.websecurityscanner.v1beta.VulnerableHeaders)
    # Field: vulnerable_parameters Type: 11 (.google.cloud.websecurityscanner.v1beta.VulnerableParameters)
    # Field: xss Type: 11 (.google.cloud.websecurityscanner.v1beta.Xss)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1beta::Finding - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1beta/finding.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1beta::Finding;

    my $msg = Google::Cloud::Websecurityscanner::V1beta::Finding::Finding->new({
        name => $name,
        finding_type => $finding_type,
        http_method => $http_method,
        fuzzed_url => $fuzzed_url,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1beta::Finding::Finding->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1beta/finding.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1beta::Finding::Finding

A Finding resource represents a vulnerability instance identified during a
ScanRun.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the Finding. The name follows the format of
'projects/{projectId}/scanConfigs/{scanConfigId}/scanruns/{scanRunId}/findings/{findingId}'.
The finding IDs are generated by the system.

=item * C<< $msg->finding_type() >> / C<< $msg->finding_type($value) >>

Type: C<String>

The type of the Finding.
Detailed and up-to-date information on findings can be found here:
https://cloud.google.com/security-scanner/docs/scan-result-details

=item * C<< $msg->http_method() >> / C<< $msg->http_method($value) >>

Type: C<String>

The http method of the request that triggered the vulnerability, in
uppercase.

=item * C<< $msg->fuzzed_url() >> / C<< $msg->fuzzed_url($value) >>

Type: C<String>

The URL produced by the server-side fuzzer and used in the request that
triggered the vulnerability.

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<String>

The body of the request that triggered the vulnerability.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of the vulnerability.

=item * C<< $msg->reproduction_url() >> / C<< $msg->reproduction_url($value) >>

Type: C<String>

The URL containing human-readable payload that user can leverage to
reproduce the vulnerability.

=item * C<< $msg->frame_url() >> / C<< $msg->frame_url($value) >>

Type: C<String>

If the vulnerability was originated from nested IFrame, the immediate
parent IFrame is reported.

=item * C<< $msg->final_url() >> / C<< $msg->final_url($value) >>

Type: C<String>

The URL where the browser lands when the vulnerability is detected.

=item * C<< $msg->tracking_id() >> / C<< $msg->tracking_id($value) >>

Type: C<String>

The tracking ID uniquely identifies a vulnerability instance across
multiple ScanRuns.

=item * C<< $msg->form() >> / C<< $msg->form($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::FindingAddon::Form>)

An addon containing information reported for a vulnerability with an HTML
form, if any.

=item * C<< $msg->outdated_library() >> / C<< $msg->outdated_library($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::FindingAddon::OutdatedLibrary>)

An addon containing information about outdated libraries.

=item * C<< $msg->violating_resource() >> / C<< $msg->violating_resource($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::FindingAddon::ViolatingResource>)

An addon containing detailed information regarding any resource causing the
vulnerability such as JavaScript sources, image, audio files, etc.

=item * C<< $msg->vulnerable_headers() >> / C<< $msg->vulnerable_headers($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::FindingAddon::VulnerableHeaders>)

An addon containing information about vulnerable or missing HTTP headers.

=item * C<< $msg->vulnerable_parameters() >> / C<< $msg->vulnerable_parameters($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::FindingAddon::VulnerableParameters>)

An addon containing information about request parameters which were found
to be vulnerable.

=item * C<< $msg->xss() >> / C<< $msg->xss($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::FindingAddon::Xss>)

An addon containing information reported for an XSS, if any.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1beta::Finding::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
