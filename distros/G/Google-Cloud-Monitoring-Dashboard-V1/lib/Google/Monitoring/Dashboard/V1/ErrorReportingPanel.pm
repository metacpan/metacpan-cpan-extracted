package Google::Monitoring::Dashboard::V1::ErrorReportingPanel;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvZXJyb3JfcmVwb3J0aW5nX3BhbmVs
LnByb3RvEh5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjEicgoTRXJyb3JSZXBvcnRp
bmdQYW5lbBIjCg1wcm9qZWN0X25hbWVzGAEgAygJUgxwcm9qZWN0TmFtZXMSGgoIc2Vydmlj
ZXMYAiADKAlSCHNlcnZpY2VzEhoKCHZlcnNpb25zGAMgAygJUgh2ZXJzaW9uc0LWAQoiY29t
Lmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MUIYRXJyb3JSZXBvcnRpbmdQYW5lbFBy
b3RvUAFaRmNsb3VkLmdvb2dsZS5jb20vZ28vbW9uaXRvcmluZy9kYXNoYm9hcmQvYXBpdjEv
ZGFzaGJvYXJkcGI7ZGFzaGJvYXJkcGKqAiRHb29nbGUuQ2xvdWQuTW9uaXRvcmluZy5EYXNo
Ym9hcmQuVjHKAiRHb29nbGVcQ2xvdWRcTW9uaXRvcmluZ1xEYXNoYm9hcmRcVjFKtg8KBhIE
DgAxAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoICgEI
EgMSAEEKCQoCCCUSAxIAQQoICgEIEgMTAF0KCQoCCAsSAxMAXQoICgEIEgMUACIKCQoCCAoS
AxQAIgoICgEIEgMVADkKCQoCCAgSAxUAOQoICgEIEgMWADsKCQoCCAESAxYAOwoICgEIEgMX
AEIKCQoCCCkSAxcAQgo8CgIEABIEGgAxARowIEEgd2lkZ2V0IHRoYXQgZGlzcGxheXMgYSBs
aXN0IG9mIGVycm9yIGdyb3Vwcy4KCgoKAwQAARIDGggbCs0CCgQEAAIAEgMhAiQavwIgVGhl
IHJlc291cmNlIG5hbWUgb2YgdGhlIEdvb2dsZSBDbG91ZCBQbGF0Zm9ybSBwcm9qZWN0LiBX
cml0dGVuCiBhcyBgcHJvamVjdHMve3Byb2plY3RJRH1gIG9yIGBwcm9qZWN0cy97cHJvamVj
dE51bWJlcn1gLCB3aGVyZQogYHtwcm9qZWN0SUR9YCBhbmQgYHtwcm9qZWN0TnVtYmVyfWAg
Y2FuIGJlIGZvdW5kIGluIHRoZQogW0dvb2dsZSBDbG91ZCBjb25zb2xlXShodHRwczovL3N1
cHBvcnQuZ29vZ2xlLmNvbS9jbG91ZC9hbnN3ZXIvNjE1ODg0MCkuCgogRXhhbXBsZXM6IGBw
cm9qZWN0cy9teS1wcm9qZWN0LTEyM2AsIGBwcm9qZWN0cy81NTUxMjM0YC4KCgwKBQQAAgAE
EgMhAgoKDAoFBAACAAUSAyELEQoMCgUEAAIAARIDIRIfCgwKBQQAAgADEgMhIiMKsgMKBAQA
AgESAyoCHxqkAyBBbiBpZGVudGlmaWVyIG9mIHRoZSBzZXJ2aWNlLCBzdWNoIGFzIHRoZSBu
YW1lIG9mIHRoZQogZXhlY3V0YWJsZSwgam9iLCBvciBHb29nbGUgQXBwIEVuZ2luZSBzZXJ2
aWNlIG5hbWUuIFRoaXMgZmllbGQgaXMgZXhwZWN0ZWQKIHRvIGhhdmUgYSBsb3cgbnVtYmVy
IG9mIHZhbHVlcyB0aGF0IGFyZSByZWxhdGl2ZWx5IHN0YWJsZSBvdmVyIHRpbWUsIGFzCiBv
cHBvc2VkIHRvIGB2ZXJzaW9uYCwgd2hpY2ggY2FuIGJlIGNoYW5nZWQgd2hlbmV2ZXIgbmV3
IGNvZGUgaXMgZGVwbG95ZWQuCgogQ29udGFpbnMgdGhlIHNlcnZpY2UgbmFtZSBmb3IgZXJy
b3IgcmVwb3J0cyBleHRyYWN0ZWQgZnJvbSBHb29nbGUKIEFwcCBFbmdpbmUgbG9ncyBvciBg
ZGVmYXVsdGAgaWYgdGhlIEFwcCBFbmdpbmUgZGVmYXVsdCBzZXJ2aWNlIGlzIHVzZWQuCgoM
CgUEAAIBBBIDKgIKCgwKBQQAAgEFEgMqCxEKDAoFBAACAQESAyoSGgoMCgUEAAIBAxIDKh0e
Cu0BCgQEAAICEgMwAh8a3wEgUmVwcmVzZW50cyB0aGUgc291cmNlIGNvZGUgdmVyc2lvbiB0
aGF0IHRoZSBkZXZlbG9wZXIgcHJvdmlkZWQsCiB3aGljaCBjb3VsZCByZXByZXNlbnQgYSB2
ZXJzaW9uIGxhYmVsIG9yIGEgR2l0IFNIQS0xIGhhc2gsIGZvciBleGFtcGxlLgogRm9yIEFw
cCBFbmdpbmUgc3RhbmRhcmQgZW52aXJvbm1lbnQsIHRoZSB2ZXJzaW9uIGlzIHNldCB0byB0
aGUgdmVyc2lvbiBvZgogdGhlIGFwcC4KCgwKBQQAAgIEEgMwAgoKDAoFBAACAgUSAzALEQoM
CgUEAAICARIDMBIaCgwKBQQAAgIDEgMwHR5iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::ErrorReportingPanel::ErrorReportingPanel ===
    # Fields for ErrorReportingPanel
    # Field: project_names Type: 9 ()
    # Field: services Type: 9 ()
    # Field: versions Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::ErrorReportingPanel - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/error_reporting_panel.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::ErrorReportingPanel;

    my $msg = Google::Monitoring::Dashboard::V1::ErrorReportingPanel::ErrorReportingPanel->new({
        project_names => $project_names,
        services => $services,
        versions => $versions,
    });

    # Read or update a field
    my $val = $msg->project_names();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::ErrorReportingPanel::ErrorReportingPanel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/error_reporting_panel.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::ErrorReportingPanel::ErrorReportingPanel

A widget that displays a list of error groups.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_names() >> / C<< $msg->project_names($value) >>

Type: C<String>

The resource name of the Google Cloud Platform project. Written
as `projects/{projectID}` or `projects/{projectNumber}`, where
`{projectID}` and `{projectNumber}` can be found in the
[Google Cloud console](https://support.google.com/cloud/answer/6158840).

Examples: `projects/my-project-123`, `projects/5551234`.

=item * C<< $msg->services() >> / C<< $msg->services($value) >>

Type: C<String>

An identifier of the service, such as the name of the
executable, job, or Google App Engine service name. This field is expected
to have a low number of values that are relatively stable over time, as
opposed to `version`, which can be changed whenever new code is deployed.

Contains the service name for error reports extracted from Google
App Engine logs or `default` if the App Engine default service is used.

=item * C<< $msg->versions() >> / C<< $msg->versions($value) >>

Type: C<String>

Represents the source code version that the developer provided,
which could represent a version label or a Git SHA-1 hash, for example.
For App Engine standard environment, the version is set to the version of
the app.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::ErrorReportingPanel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
