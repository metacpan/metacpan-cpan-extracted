package Google::Cloud::Gkebackup::Logging::V1::LoggedRestore;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvZ2tlYmFja3VwL2xvZ2dpbmcvdjEvbG9nZ2VkX3Jlc3RvcmUucHJv
dG8SIWdvb2dsZS5jbG91ZC5na2ViYWNrdXAubG9nZ2luZy52MSLDAwoNTG9nZ2VkUmVzdG9y
ZRIWCgZiYWNrdXAYASABKAlSBmJhY2t1cBJUCgZsYWJlbHMYAiADKAsyPC5nb29nbGUuY2xv
dWQuZ2tlYmFja3VwLmxvZ2dpbmcudjEuTG9nZ2VkUmVzdG9yZS5MYWJlbHNFbnRyeVIGbGFi
ZWxzEiAKC2Rlc2NyaXB0aW9uGAMgASgJUgtkZXNjcmlwdGlvbhJMCgVzdGF0ZRgEIAEoDjI2
Lmdvb2dsZS5jbG91ZC5na2ViYWNrdXAubG9nZ2luZy52MS5Mb2dnZWRSZXN0b3JlLlN0YXRl
UgVzdGF0ZRIhCgxzdGF0ZV9yZWFzb24YBSABKAlSC3N0YXRlUmVhc29uGjkKC0xhYmVsc0Vu
dHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEidgoFU3Rh
dGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIMCghDUkVBVElORxABEg8KC0lOX1BST0dSRVNT
EAISDQoJU1VDQ0VFREVEEAMSCgoGRkFJTEVEEAQSDAoIREVMRVRJTkcQBRIOCgpWQUxJREFU
SU5HEAZC6gEKIWdvb2dsZS5jbG91ZC5na2ViYWNrdXAubG9nZ2luZy52MUISTG9nZ2VkUmVz
dG9yZVByb3RvUAFaP2Nsb3VkLmdvb2dsZS5jb20vZ28vZ2tlYmFja3VwL2xvZ2dpbmcvYXBp
djEvbG9nZ2luZ3BiO2xvZ2dpbmdwYqoCIUdvb2dsZS5DbG91ZC5Ha2VCYWNrdXAuTG9nZ2lu
Zy5WMcoCIUdvb2dsZVxDbG91ZFxHa2VCYWNrdXBcTG9nZ2luZ1xWMeoCJUdvb2dsZTo6Q2xv
dWQ6OkdrZUJhY2t1cDo6TG9nZ2luZzo6VjFKrhMKBhIEDgBJAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKgoICgEIEgMSAD4KCQoCCCUSAxIAPgoICgEI
EgMTAFYKCQoCCAsSAxMAVgoICgEIEgMUACIKCQoCCAoSAxQAIgoICgEIEgMVADMKCQoCCAgS
AxUAMwoICgEIEgMWADoKCQoCCAESAxYAOgoICgEIEgMXAD8KCQoCCCkSAxcAPwoICgEIEgMY
AD4KCQoCCC0SAxgAPgqyAQoCBAASBB0ASQEapQEgUmVzdG9yZSBhcyBzdG9yZWQgaW4gUGxh
dGZvcm0gbG9nLiBJdCdzIHVzZWQgdG8gbG9nIHRoZSB1cGRhdGUgZGV0YWlscyBvZiBhCiB1
cGRhdGVSZXN0b3JlIHJlcXVlc3QsIHNvIG9ubHkgbXV0YWJsZSBhbmQgbm9uLW91dHB1dF9v
bmx5IGZpZWxkcyBhcmUKIGluY2x1ZGVkIGhlcmUuLgoKCgoDBAABEgMdCBUKOQoEBAAEABIE
HwI4AxorIFBvc3NpYmxlIHZhbHVlcyBmb3Igc3RhdGUgb2YgdGhlIFJlc3RvcmUuCgoMCgUE
AAQAARIDHwcMCkkKBgQABAACABIDIQQaGjogVGhlIFJlc3RvcmUgcmVzb3VyY2UgaXMgaW4g
dGhlIHByb2Nlc3Mgb2YgYmVpbmcgY3JlYXRlZC4KCg4KBwQABAACAAESAyEEFQoOCgcEAAQA
AgACEgMhGBkKkQEKBgQABAACARIDJQQRGoEBIFRoZSBSZXN0b3JlIHJlc291cmNlIGhhcyBi
ZWVuIGNyZWF0ZWQgYW5kIHRoZSBhc3NvY2lhdGVkIFJlc3RvcmVKb2IKIEt1YmVybmV0ZXMg
cmVzb3VyY2UgaGFzIGJlZW4gaW5qZWN0ZWQgaW50byB0YXJnZXQgY2x1c3Rlci4KCg4KBwQA
BAACAQESAyUEDAoOCgcEAAQAAgECEgMlDxAKXwoGBAAEAAICEgMpBBQaUCBUaGUgZ2tlYmFj
a3VwIGFnZW50IGluIHRoZSBjbHVzdGVyIGhhcyBiZWd1biBleGVjdXRpbmcgdGhlIHJlc3Rv
cmUKIG9wZXJhdGlvbi4KCg4KBwQABAACAgESAykEDwoOCgcEAAQAAgICEgMpEhMKcgoGBAAE
AAIDEgMtBBIaYyBUaGUgcmVzdG9yZSBvcGVyYXRpb24gaGFzIGNvbXBsZXRlZCBzdWNjZXNz
ZnVsbHkuIFJlc3RvcmVkIHdvcmtsb2FkcyBtYXkKIG5vdCB5ZXQgYmUgb3BlcmF0aW9uYWwu
CgoOCgcEAAQAAgMBEgMtBA0KDgoHBAAEAAIDAhIDLRARCjIKBgQABAACBBIDMAQPGiMgVGhl
IHJlc3RvcmUgb3BlcmF0aW9uIGhhcyBmYWlsZWQuCgoOCgcEAAQAAgQBEgMwBAoKDgoHBAAE
AAIEAhIDMA0OCkoKBgQABAACBRIDMwQRGjsgVGhpcyBSZXN0b3JlIHJlc291cmNlIGlzIGlu
IHRoZSBwcm9jZXNzIG9mIGJlaW5nIGRlbGV0ZWQuCgoOCgcEAAQAAgUBEgMzBAwKDgoHBAAE
AAIFAhIDMw8QClcKBgQABAACBhIDNwQTGkggVGhlIEt1YmVybmV0ZXMgcmVzb3VyY2VzIGNy
ZWF0ZWQgYnkgdGhpcyBSZXN0b3JlIGFyZSBiZWluZwogdmFsaWRhdGVkLgoKDgoHBAAEAAIG
ARIDNwQOCg4KBwQABAACBgISAzcREgqVAQoEBAACABIDPAIUGocBIEZ1bGwgbmFtZSBvZiB0
aGUgQmFja3VwIHJlc291cmNlIHRoaXMgUmVzdG9yZSByZXNvdXJjZSB1c2VkIHRvIHJlc3Rv
cmUKIGZyb20uIEZvcm1hdDogcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9iYWNrdXBQbGFucy8q
L2JhY2t1cHMvKi4KCgwKBQQAAgAFEgM8AggKDAoFBAACAAESAzwJDwoMCgUEAAIAAxIDPBIT
ChoKBAQAAgESAz8CIRoNIEdDUCBMYWJlbHMuCgoMCgUEAAIBBhIDPwIVCgwKBQQAAgEBEgM/
FhwKDAoFBAACAQMSAz8fIApCCgQEAAICEgNCAhkaNSBVc2VyIHNwZWNpZmllZCBkZXNjcmlw
dGl2ZSBzdHJpbmcgZm9yIHRoaXMgUmVzdG9yZS4KCgwKBQQAAgIFEgNCAggKDAoFBAACAgES
A0IJFAoMCgUEAAICAxIDQhcYCjAKBAQAAgMSA0UCEhojIFRoZSBjdXJyZW50IHN0YXRlIG9m
IHRoZSBSZXN0b3JlLgoKDAoFBAACAwYSA0UCBwoMCgUEAAIDARIDRQgNCgwKBQQAAgMDEgNF
EBEKVQoEBAACBBIDSAIaGkggSHVtYW4tcmVhZGFibGUgZGVzY3JpcHRpb24gb2Ygd2h5IHRo
ZSBSZXN0b3JlIGlzIGluIGl0cyBjdXJyZW50IHN0YXRlLgoKDAoFBAACBAUSA0gCCAoMCgUE
AAIEARIDSAkVCgwKBQQAAgQDEgNIGBliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::LoggedRestore ===
    # Fields for LoggedRestore
    # Field: backup Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedRestore.LabelsEntry)
    # Field: description Type: 9 ()
    # Field: state Type: 14 (.google.cloud.gkebackup.logging.v1.LoggedRestore.State)
    # Field: state_reason Type: 9 ()

# Enum: LoggedRestore::State
our $LoggedRestore_STATE_UNSPECIFIED = 0;
our $LoggedRestore_CREATING = 1;
our $LoggedRestore_IN_PROGRESS = 2;
our $LoggedRestore_SUCCEEDED = 3;
our $LoggedRestore_FAILED = 4;
our $LoggedRestore_DELETING = 5;
our $LoggedRestore_VALIDATING = 6;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::LoggedRestore - Compiled Protocol Buffers messages for google/cloud/gkebackup/logging/v1/logged_restore.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::Logging::V1::LoggedRestore;

    my $msg = Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::LoggedRestore->new({
        backup => $backup,
        labels => $labels,
        description => $description,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->backup();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::LoggedRestore->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/logging/v1/logged_restore.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::LoggedRestore

Restore as stored in Platform log. It's used to log the update details of a
updateRestore request, so only mutable and non-output_only fields are
included here..

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup() >> / C<< $msg->backup($value) >>

Type: C<String>

Full name of the Backup resource this Restore resource used to restore
from. Format: projects/*/locations/*/backupPlans/*/backups/*.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::LoggedRestore::LabelsEntry>)

GCP Labels.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

User specified descriptive string for this Restore.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::State>)

The current state of the Restore.

=item * C<< $msg->state_reason() >> / C<< $msg->state_reason($value) >>

Type: C<String>

Human-readable description of why the Restore is in its current state.

=back

=head3 Enum: LoggedRestore::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<IN_PROGRESS> => C<2>

=item * C<SUCCEEDED> => C<3>

=item * C<FAILED> => C<4>

=item * C<DELETING> => C<5>

=item * C<VALIDATING> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
