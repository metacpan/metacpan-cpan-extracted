package Google::Cloud::Run::V2::ExecutionTemplate;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Run::V2::TaskTemplate };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvcnVuL3YyL2V4ZWN1dGlvbl90ZW1wbGF0ZS5wcm90bxITZ29vZ2xl
LmNsb3VkLnJ1bi52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxonZ29vZ2xl
L2Nsb3VkL3J1bi92Mi90YXNrX3RlbXBsYXRlLnByb3RvIs8EChFFeGVjdXRpb25UZW1wbGF0
ZRJKCgZsYWJlbHMYASADKAsyMi5nb29nbGUuY2xvdWQucnVuLnYyLkV4ZWN1dGlvblRlbXBs
YXRlLkxhYmVsc0VudHJ5UgZsYWJlbHMSWQoLYW5ub3RhdGlvbnMYAiADKAsyNy5nb29nbGUu
Y2xvdWQucnVuLnYyLkV4ZWN1dGlvblRlbXBsYXRlLkFubm90YXRpb25zRW50cnlSC2Fubm90
YXRpb25zEiUKC3BhcmFsbGVsaXNtGAMgASgFQgPgQQFSC3BhcmFsbGVsaXNtEh0KCnRhc2tf
Y291bnQYBCABKAVSCXRhc2tDb3VudBJCCgh0ZW1wbGF0ZRgFIAEoCzIhLmdvb2dsZS5jbG91
ZC5ydW4udjIuVGFza1RlbXBsYXRlQgPgQQJSCHRlbXBsYXRlEjEKD2RlbGF5X2V4ZWN1dGlv
bhgIIAEoCEID4EEBSABSDmRlbGF5RXhlY3V0aW9uiAEBEhsKBmNsaWVudBgJIAEoCUID4EEB
UgZjbGllbnQSKgoOY2xpZW50X3ZlcnNpb24YCiABKAlCA+BBAVINY2xpZW50VmVyc2lvbho5
CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6
AjgBGj4KEEFubm90YXRpb25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiAB
KAlSBXZhbHVlOgI4AUISChBfZGVsYXlfZXhlY3V0aW9uQl4KF2NvbS5nb29nbGUuY2xvdWQu
cnVuLnYyQhZFeGVjdXRpb25UZW1wbGF0ZVByb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28v
cnVuL2FwaXYyL3J1bnBiO3J1bnBiSokcCgYSBA4AUgEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoCAwASAxIAKQoJCgIDARIDEwAxCggKAQgSAxUA
QAoJCgIICxIDFQBACggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcANwoJCgIICBIDFwA3
CggKAQgSAxgAMAoJCgIIARIDGAAwCmoKAgQAEgQcAFIBGl4gRXhlY3V0aW9uVGVtcGxhdGUg
ZGVzY3JpYmVzIHRoZSBkYXRhIGFuIGV4ZWN1dGlvbiBzaG91bGQgaGF2ZSB3aGVuIGNyZWF0
ZWQKIGZyb20gYSB0ZW1wbGF0ZS4KCgoKAwQAARIDHAgZCrkFCgQEAAIAEgMpAiEaqwUgVW5z
dHJ1Y3R1cmVkIGtleSB2YWx1ZSBtYXAgdGhhdCBjYW4gYmUgdXNlZCB0byBvcmdhbml6ZSBh
bmQgY2F0ZWdvcml6ZQogb2JqZWN0cy4KIFVzZXItcHJvdmlkZWQgbGFiZWxzIGFyZSBzaGFy
ZWQgd2l0aCBHb29nbGUncyBiaWxsaW5nIHN5c3RlbSwgc28gdGhleSBjYW4KIGJlIHVzZWQg
dG8gZmlsdGVyLCBvciBicmVhayBkb3duIGJpbGxpbmcgY2hhcmdlcyBieSB0ZWFtLCBjb21w
b25lbnQsCiBlbnZpcm9ubWVudCwgc3RhdGUsIGV0Yy4gRm9yIG1vcmUgaW5mb3JtYXRpb24s
IHZpc2l0CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcmVzb3VyY2UtbWFuYWdlci9kb2Nz
L2NyZWF0aW5nLW1hbmFnaW5nLWxhYmVscyBvcgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29t
L3J1bi9kb2NzL2NvbmZpZ3VyaW5nL2xhYmVscy4KCiA8cD5DbG91ZCBSdW4gQVBJIHYyIGRv
ZXMgbm90IHN1cHBvcnQgbGFiZWxzIHdpdGggYHJ1bi5nb29nbGVhcGlzLmNvbWAsCiBgY2xv
dWQuZ29vZ2xlYXBpcy5jb21gLCBgc2VydmluZy5rbmF0aXZlLmRldmAsIG9yIGBhdXRvc2Nh
bGluZy5rbmF0aXZlLmRldmAKIG5hbWVzcGFjZXMsIGFuZCB0aGV5IHdpbGwgYmUgcmVqZWN0
ZWQuIEFsbCBzeXN0ZW0gbGFiZWxzIGluIHYxIG5vdyBoYXZlIGEKIGNvcnJlc3BvbmRpbmcg
ZmllbGQgaW4gdjIgRXhlY3V0aW9uVGVtcGxhdGUuCgoMCgUEAAIABhIDKQIVCgwKBQQAAgAB
EgMpFhwKDAoFBAACAAMSAykfIAqgBAoEBAACARIDNgImGpIEIFVuc3RydWN0dXJlZCBrZXkg
dmFsdWUgbWFwIHRoYXQgbWF5IGJlIHNldCBieSBleHRlcm5hbCB0b29scyB0byBzdG9yZSBh
bmQKIGFyYml0cmFyeSBtZXRhZGF0YS4gVGhleSBhcmUgbm90IHF1ZXJ5YWJsZSBhbmQgc2hv
dWxkIGJlIHByZXNlcnZlZAogd2hlbiBtb2RpZnlpbmcgb2JqZWN0cy4KCiA8cD5DbG91ZCBS
dW4gQVBJIHYyIGRvZXMgbm90IHN1cHBvcnQgYW5ub3RhdGlvbnMgd2l0aCBgcnVuLmdvb2ds
ZWFwaXMuY29tYCwKIGBjbG91ZC5nb29nbGVhcGlzLmNvbWAsIGBzZXJ2aW5nLmtuYXRpdmUu
ZGV2YCwgb3IgYGF1dG9zY2FsaW5nLmtuYXRpdmUuZGV2YAogbmFtZXNwYWNlcywgYW5kIHRo
ZXkgd2lsbCBiZSByZWplY3RlZC4gQWxsIHN5c3RlbSBhbm5vdGF0aW9ucyBpbiB2MSBub3cK
IGhhdmUgYSBjb3JyZXNwb25kaW5nIGZpZWxkIGluIHYyIEV4ZWN1dGlvblRlbXBsYXRlLgoK
IDxwPlRoaXMgZmllbGQgZm9sbG93cyBLdWJlcm5ldGVzIGFubm90YXRpb25zJyBuYW1lc3Bh
Y2luZywgbGltaXRzLCBhbmQKIHJ1bGVzLgoKDAoFBAACAQYSAzYCFQoMCgUEAAIBARIDNhYh
CgwKBQQAAgEDEgM2JCUKrQMKBAQAAgISAz4CQRqfAyBPcHRpb25hbC4gU3BlY2lmaWVzIHRo
ZSBtYXhpbXVtIGRlc2lyZWQgbnVtYmVyIG9mIHRhc2tzIHRoZSBleGVjdXRpb24KIHNob3Vs
ZCBydW4gYXQgZ2l2ZW4gdGltZS4gV2hlbiB0aGUgam9iIGlzIHJ1biwgaWYgdGhpcyBmaWVs
ZCBpcyAwIG9yIHVuc2V0LAogdGhlIG1heGltdW0gcG9zc2libGUgdmFsdWUgd2lsbCBiZSB1
c2VkIGZvciB0aGF0IGV4ZWN1dGlvbi4gVGhlIGFjdHVhbAogbnVtYmVyIG9mIHRhc2tzIHJ1
bm5pbmcgaW4gc3RlYWR5IHN0YXRlIHdpbGwgYmUgbGVzcyB0aGFuIHRoaXMgbnVtYmVyIHdo
ZW4KIHRoZXJlIGFyZSBmZXdlciB0YXNrcyB3YWl0aW5nIHRvIGJlIGNvbXBsZXRlZCByZW1h
aW5pbmcsIGkuZS4gd2hlbiB0aGUgd29yawogbGVmdCB0byBkbyBpcyBsZXNzIHRoYW4gbWF4
IHBhcmFsbGVsaXNtLgoKDAoFBAACAgUSAz4CBwoMCgUEAAICARIDPggTCgwKBQQAAgIDEgM+
FhcKDAoFBAACAggSAz4YQAoPCggEAAICCJwIABIDPhk/CtcBCgQEAAIDEgNDAhcayQEgU3Bl
Y2lmaWVzIHRoZSBkZXNpcmVkIG51bWJlciBvZiB0YXNrcyB0aGUgZXhlY3V0aW9uIHNob3Vs
ZCBydW4uCiBTZXR0aW5nIHRvIDEgbWVhbnMgdGhhdCBwYXJhbGxlbGlzbSBpcyBsaW1pdGVk
IHRvIDEgYW5kIHRoZSBzdWNjZXNzIG9mCiB0aGF0IHRhc2sgc2lnbmFscyB0aGUgc3VjY2Vz
cyBvZiB0aGUgZXhlY3V0aW9uLiBEZWZhdWx0cyB0byAxLgoKDAoFBAACAwUSA0MCBwoMCgUE
AAIDARIDQwgSCgwKBQQAAgMDEgNDFRYKYQoEBAACBBIDRwJFGlQgUmVxdWlyZWQuIERlc2Ny
aWJlcyB0aGUgdGFzayhzKSB0aGF0IHdpbGwgYmUgY3JlYXRlZCB3aGVuIGV4ZWN1dGluZyBh
bgogZXhlY3V0aW9uLgoKDAoFBAACBAYSA0cCDgoMCgUEAAIEARIDRw8XCgwKBQQAAgQDEgNH
GhsKDAoFBAACBAgSA0ccRAoPCggEAAIECJwIABIDRx1DCoABCgQEAAIFEgNLAk0acyBPcHRp
b25hbC4gSWYgdHJ1ZSwgdGhlIHN5c3RlbSB3aWxsIHN0YXJ0IHRoZSBleGVjdXRpb24gd2l0
aGluIHRoZSBuZXh0IDEyCiBob3VycyBkZXBlbmRpbmcgb24gYXZhaWxhYmxlIGNhcGFjaXR5
LgoKDAoFBAACBQQSA0sCCgoMCgUEAAIFBRIDSwsPCgwKBQQAAgUBEgNLEB8KDAoFBAACBQMS
A0siIwoMCgUEAAIFCBIDSyRMCg8KCAQAAgUInAgAEgNLJUsKQQoEBAACBhIDTgI9GjQgT3B0
aW9uYWwuIEFyYml0cmFyeSBpZGVudGlmaWVyIGZvciB0aGUgQVBJIGNsaWVudC4KCgwKBQQA
AgYFEgNOAggKDAoFBAACBgESA04JDwoMCgUEAAIGAxIDThITCgwKBQQAAgYIEgNOFDwKDwoI
BAACBgicCAASA04VOwpJCgQEAAIHEgNRAkYaPCBPcHRpb25hbC4gQXJiaXRyYXJ5IHZlcnNp
b24gaWRlbnRpZmllciBmb3IgdGhlIEFQSSBjbGllbnQuCgoMCgUEAAIHBRIDUQIICgwKBQQA
AgcBEgNRCRcKDAoFBAACBwMSA1EaHAoMCgUEAAIHCBIDUR1FCg8KCAQAAgcInAgAEgNRHkRi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Run::V2::ExecutionTemplate::ExecutionTemplate ===
    # Fields for ExecutionTemplate
    # Field: labels Type: 11 (.google.cloud.run.v2.ExecutionTemplate.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.run.v2.ExecutionTemplate.AnnotationsEntry)
    # Field: parallelism Type: 5 ()
    # Field: task_count Type: 5 ()
    # Field: template Type: 11 (.google.cloud.run.v2.TaskTemplate)
    # Field: delay_execution Type: 8 ()
    # Field: client Type: 9 ()
    # Field: client_version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Run::V2::ExecutionTemplate - Compiled Protocol Buffers messages for google/cloud/run/v2/execution_template.proto

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::ExecutionTemplate;

    my $msg = Google::Cloud::Run::V2::ExecutionTemplate::ExecutionTemplate->new({
        labels => $labels,
        annotations => $annotations,
        parallelism => $parallelism,
        task_count => $task_count,
    });

    # Read or update a field
    my $val = $msg->labels();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Run::V2::ExecutionTemplate::ExecutionTemplate->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/run/v2/execution_template.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Run::V2::ExecutionTemplate::ExecutionTemplate

ExecutionTemplate describes the data an execution should have when created
from a template.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::ExecutionTemplate::ExecutionTemplate::LabelsEntry>)

Unstructured key value map that can be used to organize and categorize
objects.
User-provided labels are shared with Google's billing system, so they can
be used to filter, or break down billing charges by team, component,
environment, state, etc. For more information, visit
https://cloud.google.com/resource-manager/docs/creating-managing-labels or
https://cloud.google.com/run/docs/configuring/labels.

<p>Cloud Run API v2 does not support labels with `run.googleapis.com`,
`cloud.googleapis.com`, `serving.knative.dev`, or `autoscaling.knative.dev`
namespaces, and they will be rejected. All system labels in v1 now have a
corresponding field in v2 ExecutionTemplate.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::ExecutionTemplate::ExecutionTemplate::AnnotationsEntry>)

Unstructured key value map that may be set by external tools to store and
arbitrary metadata. They are not queryable and should be preserved
when modifying objects.

<p>Cloud Run API v2 does not support annotations with `run.googleapis.com`,
`cloud.googleapis.com`, `serving.knative.dev`, or `autoscaling.knative.dev`
namespaces, and they will be rejected. All system annotations in v1 now
have a corresponding field in v2 ExecutionTemplate.

<p>This field follows Kubernetes annotations' namespacing, limits, and
rules.

=item * C<< $msg->parallelism() >> / C<< $msg->parallelism($value) >>

Type: C<Int32>

Optional. Specifies the maximum desired number of tasks the execution
should run at given time. When the job is run, if this field is 0 or unset,
the maximum possible value will be used for that execution. The actual
number of tasks running in steady state will be less than this number when
there are fewer tasks waiting to be completed remaining, i.e. when the work
left to do is less than max parallelism.

=item * C<< $msg->task_count() >> / C<< $msg->task_count($value) >>

Type: C<Int32>

Specifies the desired number of tasks the execution should run.
Setting to 1 means that parallelism is limited to 1 and the success of
that task signals the success of the execution. Defaults to 1.

=item * C<< $msg->template() >> / C<< $msg->template($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::TaskTemplate::TaskTemplate>)

Required. Describes the task(s) that will be created when executing an
execution.

=item * C<< $msg->delay_execution() >> / C<< $msg->delay_execution($value) >>

Type: C<Bool>

Optional. If true, the system will start the execution within the next 12
hours depending on available capacity.

=item * C<< $msg->client() >> / C<< $msg->client($value) >>

Type: C<String>

Optional. Arbitrary identifier for the API client.

=item * C<< $msg->client_version() >> / C<< $msg->client_version($value) >>

Type: C<String>

Optional. Arbitrary version identifier for the API client.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Run::V2::ExecutionTemplate::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
