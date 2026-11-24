package Google::Cloud::Securitycenter::V2::Job;

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
Cihnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvam9iLnByb3RvEh5nb29nbGUuY2xv
dWQuc2VjdXJpdHljZW50ZXIudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8i
mQEKA0pvYhISCgRuYW1lGAEgASgJUgRuYW1lEkMKBXN0YXRlGAIgASgOMiguZ29vZ2xlLmNs
b3VkLnNlY3VyaXR5Y2VudGVyLnYyLkpvYlN0YXRlQgPgQQNSBXN0YXRlEh0KCmVycm9yX2Nv
ZGUYAyABKAVSCWVycm9yQ29kZRIaCghsb2NhdGlvbhgEIAEoCVIIbG9jYXRpb24qWgoISm9i
U3RhdGUSGQoVSk9CX1NUQVRFX1VOU1BFQ0lGSUVEEAASCwoHUEVORElORxABEgsKB1JVTk5J
TkcQAhINCglTVUNDRUVERUQQAxIKCgZGQUlMRUQQBELiAQoiY29tLmdvb2dsZS5jbG91ZC5z
ZWN1cml0eWNlbnRlci52MkIISm9iUHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9zZWN1
cml0eWNlbnRlci9hcGl2Mi9zZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2VudGVycGKqAh5H
b29nbGUuQ2xvdWQuU2VjdXJpdHlDZW50ZXIuVjLKAh5Hb29nbGVcQ2xvdWRcU2VjdXJpdHlD
ZW50ZXJcVjLqAiFHb29nbGU6OkNsb3VkOjpTZWN1cml0eUNlbnRlcjo6VjJKpw4KBhIEDgA+
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABID
EgApCggKAQgSAxQAOwoJCgIIJRIDFAA7CggKAQgSAxUAYQoJCgIICxIDFQBhCggKAQgSAxYA
IgoJCgIIChIDFgAiCggKAQgSAxcAKQoJCgIICBIDFwApCggKAQgSAxgAOwoJCgIIARIDGAA7
CggKAQgSAxkAOwoJCgIIKRIDGQA7CggKAQgSAxoAOgoJCgIILRIDGgA6Ch0KAgQAEgQdACwB
GhEgRGVzY3JpYmVzIGEgam9iCgoKCgMEAAESAx0ICwpeCgQEAAIAEgMgAhIaUSBUaGUgZnVs
bHktcXVhbGlmaWVkIG5hbWUgZm9yIGEgam9iLgogZS5nLiBgcHJvamVjdHMvPHByb2plY3Rf
aWQ+L2pvYnMvPGpvYl9pZD5gCgoMCgUEAAIABRIDIAIICgwKBQQAAgABEgMgCQ0KDAoFBAAC
AAMSAyAQEQpNCgQEAAIBEgMjAkEaQCBPdXRwdXQgb25seS4gU3RhdGUgb2YgdGhlIGpvYiwg
c3VjaCBhcyBgUlVOTklOR2Agb3IgYFBFTkRJTkdgLgoKDAoFBAACAQYSAyMCCgoMCgUEAAIB
ARIDIwsQCgwKBQQAAgEDEgMjExQKDAoFBAACAQgSAyMVQAoPCggEAAIBCJwIABIDIxY/Cl0K
BAQAAgISAycCFxpQIE9wdGlvbmFsLiBJZiB0aGUgam9iIGRpZCBub3QgY29tcGxldGUgc3Vj
Y2Vzc2Z1bGx5LCB0aGlzIGZpZWxkIGRlc2NyaWJlcwogd2h5LgoKDAoFBAACAgUSAycCBwoM
CgUEAAICARIDJwgSCgwKBQQAAgIDEgMnFRYKXgoEBAACAxIDKwIWGlEgT3B0aW9uYWwuIEdp
dmVzIHRoZSBsb2NhdGlvbiB3aGVyZSB0aGUgam9iIHJhbiwgc3VjaCBhcyBgVVNgIG9yCiBg
ZXVyb3BlLXdlc3QxYAoKDAoFBAACAwUSAysCCAoMCgUEAAIDARIDKwkRCgwKBQQAAgMDEgMr
FBUKNwoCBQASBC8APgEaKyBKb2JTdGF0ZSByZXByZXNlbnRzIHRoZSBzdGF0ZSBvZiB0aGUg
am9iLgoKCgoDBQABEgMvBQ0KTgoEBQACABIDMQIcGkEgVW5zcGVjaWZpZWQgcmVwcmVzZW50
cyBhbiB1bmtub3duIHN0YXRlIGFuZCBzaG91bGQgbm90IGJlIHVzZWQuCgoMCgUFAAIAARID
MQIXCgwKBQUAAgACEgMxGhsKMwoEBQACARIDNAIOGiYgSm9iIGlzIHNjaGVkdWxlZCBhbmQg
cGVuZGluZyBmb3IgcnVuCgoMCgUFAAIBARIDNAIJCgwKBQUAAgECEgM0DA0KHgoEBQACAhID
NwIOGhEgSm9iIGluIHByb2dyZXNzCgoMCgUFAAICARIDNwIJCgwKBQUAAgICEgM3DA0KLQoE
BQACAxIDOgIQGiAgSm9iIGhhcyBjb21wbGV0ZWQgd2l0aCBzdWNjZXNzCgoMCgUFAAIDARID
OgILCgwKBQUAAgMCEgM6Dg8KMQoEBQACBBIDPQINGiQgSm9iIGhhcyBjb21wbGV0ZWQgYnV0
IHdpdGggZmFpbHVyZQoKDAoFBQACBAESAz0CCAoMCgUFAAIEAhIDPQsMYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::Job::Job ===
    # Fields for Job
    # Field: name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.securitycenter.v2.JobState)
    # Field: error_code Type: 5 ()
    # Field: location Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::Job - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/job.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::Job;

    my $msg = Google::Cloud::Securitycenter::V2::Job::Job->new({
        name => $name,
        state => $state,
        error_code => $error_code,
        location => $location,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::Job::Job->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/job.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::Job::Job

Describes a job

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The fully-qualified name for a job.
e.g. `projects/<project_id>/jobs/<job_id>`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V2::JobState>)

Output only. State of the job, such as `RUNNING` or `PENDING`.

=item * C<< $msg->error_code() >> / C<< $msg->error_code($value) >>

Type: C<Int32>

Optional. If the job did not complete successfully, this field describes
why.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Optional. Gives the location where the job ran, such as `US` or
`europe-west1`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::Job::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
