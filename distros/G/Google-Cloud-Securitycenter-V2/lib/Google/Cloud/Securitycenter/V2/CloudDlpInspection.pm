package Google::Cloud::Securitycenter::V2::CloudDlpInspection;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvY2xvdWRfZGxwX2luc3BlY3Rpb24u
cHJvdG8SHmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MhoZZ29vZ2xlL2FwaS9yZXNv
dXJjZS5wcm90byK3AQoSQ2xvdWREbHBJbnNwZWN0aW9uEj8KC2luc3BlY3Rfam9iGAEgASgJ
Qh76QRsKGWRscC5nb29nbGVhcGlzLmNvbS9EbHBKb2JSCmluc3BlY3RKb2ISGwoJaW5mb190
eXBlGAIgASgJUghpbmZvVHlwZRImCg9pbmZvX3R5cGVfY291bnQYAyABKANSDWluZm9UeXBl
Q291bnQSGwoJZnVsbF9zY2FuGAQgASgIUghmdWxsU2NhbkLwAgoiY29tLmdvb2dsZS5jbG91
ZC5zZWN1cml0eWNlbnRlci52MkIXQ2xvdWREbHBJbnNwZWN0aW9uUHJvdG9QAVpKY2xvdWQu
Z29vZ2xlLmNvbS9nby9zZWN1cml0eWNlbnRlci9hcGl2Mi9zZWN1cml0eWNlbnRlcnBiO3Nl
Y3VyaXR5Y2VudGVycGKqAh5Hb29nbGUuQ2xvdWQuU2VjdXJpdHlDZW50ZXIuVjLKAh5Hb29n
bGVcQ2xvdWRcU2VjdXJpdHlDZW50ZXJcVjLqAiFHb29nbGU6OkNsb3VkOjpTZWN1cml0eUNl
bnRlcjo6VjLqQXwKGWRscC5nb29nbGVhcGlzLmNvbS9EbHBKb2ISJHByb2plY3RzL3twcm9q
ZWN0fS9kbHBKb2JzL3tkbHBfam9ifRI5cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L2RscEpvYnMve2RscF9qb2J9St0MCgYSBA4ANQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAIwoICgEIEgMUADsKCQoC
CCUSAxQAOwoICgEIEgMVAGEKCQoCCAsSAxUAYQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEI
EgMXADgKCQoCCAgSAxcAOAoICgEIEgMYADsKCQoCCAESAxgAOwoICgEIEgMZADsKCQoCCCkS
AxkAOwoICgEIEgMaADoKCQoCCC0SAxoAOgoJCgEIEgQbAB8CCgwKBAidCAASBBsAHwIKrgEK
AgQAEgQkADUBGqEBIERldGFpbHMgYWJvdXQgdGhlIENsb3VkIERhdGEgTG9zcyBQcmV2ZW50
aW9uIChDbG91ZCBETFApIFtpbnNwZWN0aW9uCiBqb2JdKGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9kbHAvZG9jcy9jb25jZXB0cy1qb2ItdHJpZ2dlcnMpIHRoYXQgcHJvZHVjZWQKIHRo
ZSBmaW5kaW5nLgoKCgoDBAABEgMkCBoKbAoEBAACABIEJwIoUBpeIE5hbWUgb2YgdGhlIGlu
c3BlY3Rpb24gam9iLCBmb3IgZXhhbXBsZSwKIGBwcm9qZWN0cy8xMjMvbG9jYXRpb25zL2V1
cm9wZS9kbHBKb2JzL2ktODM4MzkyOWAuCgoMCgUEAAIABRIDJwIICgwKBQQAAgABEgMnCRQK
DAoFBAACAAMSAycXGAoMCgUEAAIACBIDKAZPCg4KBwQAAgAInwgSAygHTgqrAQoEBAACARID
LQIXGp0BIFRoZSB0eXBlIG9mIGluZm9ybWF0aW9uIChvcgogKltpbmZvVHlwZV0oaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL2RscC9kb2NzL2luZm90eXBlcy1yZWZlcmVuY2UpKikgZm91
bmQsCiBmb3IgZXhhbXBsZSwgYEVNQUlMX0FERFJFU1NgIG9yIGBTVFJFRVRfQUREUkVTU2Au
CgoMCgUEAAIBBRIDLQIICgwKBQQAAgEBEgMtCRIKDAoFBAACAQMSAy0VFgpfCgQEAAICEgMx
AhwaUiBUaGUgbnVtYmVyIG9mIHRpbWVzIENsb3VkIERMUCBmb3VuZCB0aGlzIGluZm9UeXBl
IHdpdGhpbiB0aGlzIGpvYgogYW5kIHJlc291cmNlLgoKDAoFBAACAgUSAzECBwoMCgUEAAIC
ARIDMQgXCgwKBQQAAgIDEgMxGhsKUwoEBAACAxIDNAIVGkYgV2hldGhlciBDbG91ZCBETFAg
c2Nhbm5lZCB0aGUgY29tcGxldGUgcmVzb3VyY2Ugb3IgYSBzYW1wbGVkIHN1YnNldC4KCgwK
BQQAAgMFEgM0AgYKDAoFBAACAwESAzQHEAoMCgUEAAIDAxIDNBMUYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::CloudDlpInspection::CloudDlpInspection ===
    # Fields for CloudDlpInspection
    # Field: inspect_job Type: 9 ()
    # Field: info_type Type: 9 ()
    # Field: info_type_count Type: 3 ()
    # Field: full_scan Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::CloudDlpInspection - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/cloud_dlp_inspection.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::CloudDlpInspection;

    my $msg = Google::Cloud::Securitycenter::V2::CloudDlpInspection::CloudDlpInspection->new({
        inspect_job => $inspect_job,
        info_type => $info_type,
        info_type_count => $info_type_count,
        full_scan => $full_scan,
    });

    # Read or update a field
    my $val = $msg->inspect_job();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::CloudDlpInspection::CloudDlpInspection->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/cloud_dlp_inspection.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::CloudDlpInspection::CloudDlpInspection

Details about the Cloud Data Loss Prevention (Cloud DLP) [inspection
job](https://cloud.google.com/dlp/docs/concepts-job-triggers) that produced
the finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->inspect_job() >> / C<< $msg->inspect_job($value) >>

Type: C<String>

Name of the inspection job, for example,
`projects/123/locations/europe/dlpJobs/i-8383929`.

=item * C<< $msg->info_type() >> / C<< $msg->info_type($value) >>

Type: C<String>

The type of information (or
*[infoType](https://cloud.google.com/dlp/docs/infotypes-reference)*) found,
for example, `EMAIL_ADDRESS` or `STREET_ADDRESS`.

=item * C<< $msg->info_type_count() >> / C<< $msg->info_type_count($value) >>

Type: C<Int64>

The number of times Cloud DLP found this infoType within this job
and resource.

=item * C<< $msg->full_scan() >> / C<< $msg->full_scan($value) >>

Type: C<Bool>

Whether Cloud DLP scanned the complete resource or a sampled subset.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::CloudDlpInspection::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
