package Grafeas::V1::Compliance;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Grafeas::V1::Severity };
    my $descriptor_b64 = <<'EOF';
ChtncmFmZWFzL3YxL2NvbXBsaWFuY2UucHJvdG8SCmdyYWZlYXMudjEaGWdyYWZlYXMvdjEv
c2V2ZXJpdHkucHJvdG8i5gMKDkNvbXBsaWFuY2VOb3RlEhQKBXRpdGxlGAEgASgJUgV0aXRs
ZRIgCgtkZXNjcmlwdGlvbhgCIAEoCVILZGVzY3JpcHRpb24SNwoHdmVyc2lvbhgDIAMoCzId
LmdyYWZlYXMudjEuQ29tcGxpYW5jZVZlcnNpb25SB3ZlcnNpb24SHAoJcmF0aW9uYWxlGAQg
ASgJUglyYXRpb25hbGUSIAoLcmVtZWRpYXRpb24YBSABKAlSC3JlbWVkaWF0aW9uEk4KDWNp
c19iZW5jaG1hcmsYBiABKAsyJy5ncmFmZWFzLnYxLkNvbXBsaWFuY2VOb3RlLkNpc0JlbmNo
bWFya0gAUgxjaXNCZW5jaG1hcmsSKwoRc2Nhbl9pbnN0cnVjdGlvbnMYByABKAxSEHNjYW5J
bnN0cnVjdGlvbnMSGAoGaW1wYWN0GAggASgJSAFSBmltcGFjdBplCgxDaXNCZW5jaG1hcmsS
IwoNcHJvZmlsZV9sZXZlbBgBIAEoBVIMcHJvZmlsZUxldmVsEjAKCHNldmVyaXR5GAIgASgO
MhQuZ3JhZmVhcy52MS5TZXZlcml0eVIIc2V2ZXJpdHlCEQoPY29tcGxpYW5jZV90eXBlQhIK
EHBvdGVudGlhbF9pbXBhY3QidQoRQ29tcGxpYW5jZVZlcnNpb24SFwoHY3BlX3VyaRgBIAEo
CVIGY3BlVXJpEi0KEmJlbmNobWFya19kb2N1bWVudBgDIAEoCVIRYmVuY2htYXJrRG9jdW1l
bnQSGAoHdmVyc2lvbhgCIAEoCVIHdmVyc2lvbiLRAQoUQ29tcGxpYW5jZU9jY3VycmVuY2US
TAoTbm9uX2NvbXBsaWFudF9maWxlcxgCIAMoCzIcLmdyYWZlYXMudjEuTm9uQ29tcGxpYW50
RmlsZVIRbm9uQ29tcGxpYW50RmlsZXMSMgoVbm9uX2NvbXBsaWFuY2VfcmVhc29uGAMgASgJ
UhNub25Db21wbGlhbmNlUmVhc29uEjcKB3ZlcnNpb24YBCABKAsyHS5ncmFmZWFzLnYxLkNv
bXBsaWFuY2VWZXJzaW9uUgd2ZXJzaW9uImcKEE5vbkNvbXBsaWFudEZpbGUSEgoEcGF0aBgB
IAEoCVIEcGF0aBInCg9kaXNwbGF5X2NvbW1hbmQYAiABKAlSDmRpc3BsYXlDb21tYW5kEhYK
BnJlYXNvbhgDIAEoCVIGcmVhc29uQlEKDWlvLmdyYWZlYXMudjFQAVo4Z29vZ2xlLmdvbGFu
Zy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9ncmFmZWFzL3YxO2dyYWZlYXOiAgNHUkFK2xoK
BhIEDgBXAQraBAoBDBIDDgASMs8EIENvcHlyaWdodCAyMDIxIFRoZSBHcmFmZWFzIEF1dGhv
cnMuIEFsbCByaWdodHMgcmVzZXJ2ZWQuCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAEwoJCgIDABIDEgAjCggKAQgSAxQATwoJCgII
CxIDFABPCggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYAJgoJCgIIARIDFgAmCggKAQgS
AxcAIQoJCgIIJBIDFwAhCgoKAgQAEgQZADIBCgoKAwQAARIDGQgWCj8KBAQAAgASAxsCExoy
IFRoZSB0aXRsZSB0aGF0IGlkZW50aWZpZXMgdGhpcyBjb21wbGlhbmNlIGNoZWNrLgoKDAoF
BAACAAUSAxsCCAoMCgUEAAIAARIDGwkOCgwKBQQAAgADEgMbERIKOQoEBAACARIDHQIZGiwg
QSBkZXNjcmlwdGlvbiBhYm91dCB0aGlzIGNvbXBsaWFuY2UgY2hlY2suCgoMCgUEAAIBBRID
HQIICgwKBQQAAgEBEgMdCRQKDAoFBAACAQMSAx0XGApDCgQEAAICEgMfAjQaNiBUaGUgT1Mg
YW5kIGNvbmZpZyB2ZXJzaW9ucyB0aGUgYmVuY2htYXJrIGFwcGxpZXMgdG8uCgoMCgUEAAIC
BBIDHwIKCgwKBQQAAgIGEgMfCycKDAoFBAACAgESAx8oLwoMCgUEAAICAxIDHzIzCkYKBAQA
AgMSAyECFxo5IEEgcmF0aW9uYWxlIGZvciB0aGUgZXhpc3RlbmNlIG9mIHRoaXMgY29tcGxp
YW5jZSBjaGVjay4KCgwKBQQAAgMFEgMhAggKDAoFBAACAwESAyEJEgoMCgUEAAIDAxIDIRUW
ClAKBAQAAgQSAyMCGRpDIEEgZGVzY3JpcHRpb24gb2YgcmVtZWRpYXRpb24gc3RlcHMgaWYg
dGhlIGNvbXBsaWFuY2UgY2hlY2sgZmFpbHMuCgoMCgUEAAIEBRIDIwIICgwKBQQAAgQBEgMj
CRQKDAoFBAACBAMSAyMXGAo7CgQEAAMAEgQlAigDGi0gQSBjb21wbGlhbmNlIGNoZWNrIHRo
YXQgaXMgYSBDSVMgYmVuY2htYXJrLgoKDAoFBAADAAESAyUKFgoNCgYEAAMAAgASAyYEHAoO
CgcEAAMAAgAFEgMmBAkKDgoHBAADAAIAARIDJgoXCg4KBwQAAwACAAMSAyYaGwoNCgYEAAMA
AgESAycEJQoOCgcEAAMAAgEGEgMnBBcKDgoHBAADAAIBARIDJxggCg4KBwQAAwACAQMSAycj
JAoMCgQEAAgAEgQpAisDCgwKBQQACAABEgMpCBcKCwoEBAACBRIDKgQjCgwKBQQAAgUGEgMq
BBAKDAoFBAACBQESAyoRHgoMCgUEAAIFAxIDKiEiCkUKBAQAAgYSAy0CHho4IFNlcmlhbGl6
ZWQgc2NhbiBpbnN0cnVjdGlvbnMgd2l0aCBhIHByZWRlZmluZWQgZm9ybWF0LgoKDAoFBAAC
BgUSAy0CBwoMCgUEAAIGARIDLQgZCgwKBQQAAgYDEgMtHB0KPQoEBAAIARIELwIxAxovIFBv
dGVudGlhbCBpbXBhY3Qgb2YgdGhlIHN1Z2dlc3RlZCByZW1lZGlhdGlvbgoKDAoFBAAIAQES
Ay8IGAoLCgQEAAIHEgMwBBYKDAoFBAACBwUSAzAECgoMCgUEAAIHARIDMAsRCgwKBQQAAgcD
EgMwFBUKYwoCBAESBDYAQAEaVyBEZXNjcmliZXMgdGhlIENJUyBiZW5jaG1hcmsgdmVyc2lv
biB0aGF0IGlzIGFwcGxpY2FibGUgdG8gYSBnaXZlbiBPUyBhbmQKIG9zIHZlcnNpb24uCgoK
CgMEAQESAzYIGQpjCgQEAQIAEgM5AhUaViBUaGUgQ1BFIFVSSSAoaHR0cHM6Ly9jcGUubWl0
cmUub3JnL3NwZWNpZmljYXRpb24vKSB0aGlzIGJlbmNobWFyayBpcwogYXBwbGljYWJsZSB0
by4KCgwKBQQBAgAFEgM5AggKDAoFBAECAAESAzkJEAoMCgUEAQIAAxIDORMUCmgKBAQBAgES
AzwCIBpbIFRoZSBuYW1lIG9mIHRoZSBkb2N1bWVudCB0aGF0IGRlZmluZXMgdGhpcyBiZW5j
aG1hcmssIGUuZy4gIkNJUwogQ29udGFpbmVyLU9wdGltaXplZCBPUyIuCgoMCgUEAQIBBRID
PAIICgwKBQQBAgEBEgM8CRsKDAoFBAECAQMSAzweHwqFAQoEBAECAhIDPwIVGnggVGhlIHZl
cnNpb24gb2YgdGhlIGJlbmNobWFyay4gVGhpcyBpcyBzZXQgdG8gdGhlIHZlcnNpb24gb2Yg
dGhlIE9TLXNwZWNpZmljCiBDSVMgZG9jdW1lbnQgdGhlIGJlbmNobWFyayBpcyBkZWZpbmVk
IGluLgoKDAoFBAECAgUSAz8CCAoMCgUEAQICARIDPwkQCgwKBQQBAgIDEgM/ExQKnAEKAgQC
EgREAEkBGo8BIEFuIGluZGljYXRpb24gdGhhdCB0aGUgY29tcGxpYW5jZSBjaGVja3MgaW4g
dGhlIGFzc29jaWF0ZWQgQ29tcGxpYW5jZU5vdGUKIHdlcmUgbm90IHNhdGlzZmllZCBmb3Ig
cGFydGljdWxhciByZXNvdXJjZXMgb3IgYSBzcGVjaWZpZWQgcmVhc29uLgoKCgoDBAIBEgNE
CBwKCwoEBAICABIDRQI0CgwKBQQCAgAEEgNFAgoKDAoFBAICAAYSA0ULGwoMCgUEAgIAARID
RRwvCgwKBQQCAgADEgNFMjMKCwoEBAICARIDRgIjCgwKBQQCAgEFEgNGAggKDAoFBAICAQES
A0YJHgoMCgUEAgIBAxIDRiEiCkIKBAQCAgISA0gCKxo1IFRoZSBPUyBhbmQgY29uZmlnIHZl
cnNpb24gdGhlIGJlbmNobWFyayB3YXMgcnVuIG9uLgoKDAoFBAICAgYSA0gCHgoMCgUEAgIC
ARIDSB8mCgwKBQQCAgIDEgNIKSoKjAIKAgQDEgRMAFcBGj0gRGV0YWlscyBhYm91dCBmaWxl
cyB0aGF0IGNhdXNlZCBhIGNvbXBsaWFuY2UgY2hlY2sgdG8gZmFpbC4KIsABIGRpc3BsYXlf
Y29tbWFuZCBpcyBhIHNpbmdsZSBjb21tYW5kIHRoYXQgY2FuIGJlIHVzZWQgdG8gZGlzcGxh
eSBhIGxpc3Qgb2YKIG5vbiBjb21wbGlhbnQgZmlsZXMuIFdoZW4gdGhlcmUgaXMgbm8gc3Vj
aCBjb21tYW5kLCB3ZSBjYW4gYWxzbyBpdGVyYXRlIGEKIGxpc3Qgb2Ygbm9uIGNvbXBsaWFu
dCBmaWxlIHVzaW5nICdwYXRoJy4KCgoKAwQDARIDTAgYCjEKBAQDAgASA1ICEhokIEVtcHR5
IGlmIGBkaXNwbGF5X2NvbW1hbmRgIGlzIHNldC4KCgwKBQQDAgAFEgNSAggKDAoFBAMCAAES
A1IJDQoMCgUEAwIAAxIDUhARCjoKBAQDAgESA1QCHRotIENvbW1hbmQgdG8gZGlzcGxheSB0
aGUgbm9uLWNvbXBsaWFudCBmaWxlcy4KCgwKBQQDAgEFEgNUAggKDAoFBAMCAQESA1QJGAoM
CgUEAwIBAxIDVBscCkQKBAQDAgISA1YCFBo3IEV4cGxhaW5zIHdoeSBhIGZpbGUgaXMgbm9u
IGNvbXBsaWFudCBmb3IgYSBDSVMgY2hlY2suCgoMCgUEAwICBRIDVgIICgwKBQQDAgIBEgNW
CQ8KDAoFBAMCAgMSA1YSE2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::Compliance::ComplianceNote ===
    # Fields for ComplianceNote
    # Field: title Type: 9 ()
    # Field: description Type: 9 ()
    # Field: version Type: 11 (.grafeas.v1.ComplianceVersion)
    # Field: rationale Type: 9 ()
    # Field: remediation Type: 9 ()
    # Field: cis_benchmark Type: 11 (.grafeas.v1.ComplianceNote.CisBenchmark)
    # Field: scan_instructions Type: 12 ()
    # Field: impact Type: 9 ()

# === Message: Grafeas::V1::Compliance::ComplianceVersion ===
    # Fields for ComplianceVersion
    # Field: cpe_uri Type: 9 ()
    # Field: benchmark_document Type: 9 ()
    # Field: version Type: 9 ()

# === Message: Grafeas::V1::Compliance::ComplianceOccurrence ===
    # Fields for ComplianceOccurrence
    # Field: non_compliant_files Type: 11 (.grafeas.v1.NonCompliantFile)
    # Field: non_compliance_reason Type: 9 ()
    # Field: version Type: 11 (.grafeas.v1.ComplianceVersion)

# === Message: Grafeas::V1::Compliance::NonCompliantFile ===
    # Fields for NonCompliantFile
    # Field: path Type: 9 ()
    # Field: display_command Type: 9 ()
    # Field: reason Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::Compliance - Compiled Protocol Buffers messages for grafeas/v1/compliance.proto

=head1 SYNOPSIS

    use Grafeas::V1::Compliance;

    my $msg = Grafeas::V1::Compliance::ComplianceNote->new({
        title => $title,
        description => $description,
        version => $version,
        rationale => $rationale,
    });

    # Read or update a field
    my $val = $msg->title();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::Compliance::ComplianceNote->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/compliance.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::Compliance::ComplianceNote

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

The title that identifies this compliance check.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A description about this compliance check.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Grafeas::V1::Compliance::ComplianceVersion>)

The OS and config versions the benchmark applies to.

=item * C<< $msg->rationale() >> / C<< $msg->rationale($value) >>

Type: C<String>

A rationale for the existence of this compliance check.

=item * C<< $msg->remediation() >> / C<< $msg->remediation($value) >>

Type: C<String>

A description of remediation steps if the compliance check fails.

=item * C<< $msg->cis_benchmark() >> / C<< $msg->cis_benchmark($value) >>

Type: C<Message> (L<Grafeas::V1::Compliance::ComplianceNote::CisBenchmark>)

=item * C<< $msg->scan_instructions() >> / C<< $msg->scan_instructions($value) >>

Type: C<Bytes>

Serialized scan instructions with a predefined format.

=item * C<< $msg->impact() >> / C<< $msg->impact($value) >>

Type: C<String>

=back

=head2 Grafeas::V1::Compliance::ComplianceVersion

Describes the CIS benchmark version that is applicable to a given OS and
os version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cpe_uri() >> / C<< $msg->cpe_uri($value) >>

Type: C<String>

The CPE URI (https://cpe.mitre.org/specification/) this benchmark is
applicable to.

=item * C<< $msg->benchmark_document() >> / C<< $msg->benchmark_document($value) >>

Type: C<String>

The name of the document that defines this benchmark, e.g. "CIS
Container-Optimized OS".

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

The version of the benchmark. This is set to the version of the OS-specific
CIS document the benchmark is defined in.

=back

=head2 Grafeas::V1::Compliance::ComplianceOccurrence

An indication that the compliance checks in the associated ComplianceNote
were not satisfied for particular resources or a specified reason.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->non_compliant_files() >> / C<< $msg->non_compliant_files($value) >>

Type: C<Message> (L<Grafeas::V1::Compliance::NonCompliantFile>)

=item * C<< $msg->non_compliance_reason() >> / C<< $msg->non_compliance_reason($value) >>

Type: C<String>

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Grafeas::V1::Compliance::ComplianceVersion>)

The OS and config version the benchmark was run on.

=back

=head2 Grafeas::V1::Compliance::NonCompliantFile

Details about files that caused a compliance check to fail.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

Empty if `display_command` is set.

=item * C<< $msg->display_command() >> / C<< $msg->display_command($value) >>

Type: C<String>

Command to display the non-compliant files.

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<String>

Explains why a file is non compliant for a CIS check.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::Compliance::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
