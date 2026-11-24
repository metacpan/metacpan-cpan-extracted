package Google::Cloud::Notebooks::V2::DiagnosticConfig;

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
CjFnb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YyL2RpYWdub3N0aWNfY29uZmlnLnByb3RvEhln
b29nbGUuY2xvdWQubm90ZWJvb2tzLnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvIpgCChBEaWFnbm9zdGljQ29uZmlnEiIKCmdjc19idWNrZXQYASABKAlCA+BBAlIJZ2Nz
QnVja2V0EigKDXJlbGF0aXZlX3BhdGgYAiABKAlCA+BBAVIMcmVsYXRpdmVQYXRoEjEKEmVu
YWJsZV9yZXBhaXJfZmxhZxgDIAEoCEID4EEBUhBlbmFibGVSZXBhaXJGbGFnEkAKGmVuYWJs
ZV9wYWNrZXRfY2FwdHVyZV9mbGFnGAQgASgIQgPgQQFSF2VuYWJsZVBhY2tldENhcHR1cmVG
bGFnEkEKG2VuYWJsZV9jb3B5X2hvbWVfZmlsZXNfZmxhZxgFIAEoCEID4EEBUhdlbmFibGVD
b3B5SG9tZUZpbGVzRmxhZ0LMAQodY29tLmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjJCFURp
YWdub3N0aWNDb25maWdQcm90b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL25vdGVib29rcy9h
cGl2Mi9ub3RlYm9va3NwYjtub3RlYm9va3NwYqoCGUdvb2dsZS5DbG91ZC5Ob3RlYm9va3Mu
VjLKAhlHb29nbGVcQ2xvdWRcTm90ZWJvb2tzXFYy6gIcR29vZ2xlOjpDbG91ZDo6Tm90ZWJv
b2tzOjpWMkqSEgoGEgQOADwBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAiCgkKAgMAEgMSACkKCAoBCBIDFAA2CgkKAgglEgMUADYKCAoBCBIDFQBSCgkK
AggLEgMVAFIKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA2CgkKAggIEgMXADYKCAoB
CBIDGAA2CgkKAggBEgMYADYKCAoBCBIDGQA2CgkKAggpEgMZADYKCAoBCBIDGgA1CgkKAggt
EgMaADUKRAoCBAASBB0APAEaOCBEZWZpbmVzIGZsYWdzIHRoYXQgYXJlIHVzZWQgdG8gcnVu
IHRoZSBkaWFnbm9zdGljIHRvb2wKCgoKAwQAARIDHQgYCqAECgQEAAIAEgMrAkEakgQgUmVx
dWlyZWQuIFVzZXIgQ2xvdWQgU3RvcmFnZSBidWNrZXQgbG9jYXRpb24gKFJFUVVJUkVEKS4K
IE11c3QgYmUgZm9ybWF0dGVkIHdpdGggcGF0aCBwcmVmaXggKGBnczovLyRHQ1NfQlVDS0VU
YCkuCgogUGVybWlzc2lvbnM6CiBVc2VyIE1hbmFnZWQgTm90ZWJvb2tzOgogLSBzdG9yYWdl
LmJ1Y2tldHMud3JpdGVyOiBNdXN0IGJlIGdpdmVuIHRvIHRoZSBwcm9qZWN0J3Mgc2Vydmlj
ZSBhY2NvdW50CiAgIGF0dGFjaGVkIHRvIFZNLgogR29vZ2xlIE1hbmFnZWQgTm90ZWJvb2tz
OgogLSBzdG9yYWdlLmJ1Y2tldHMud3JpdGVyOiBNdXN0IGJlIGdpdmVuIHRvIHRoZSBwcm9q
ZWN0J3Mgc2VydmljZSBhY2NvdW50IG9yCiAgIHVzZXIgY3JlZGVudGlhbHMgYXR0YWNoZWQg
dG8gVk0gZGVwZW5kaW5nIG9uIGF1dGhlbnRpY2F0aW9uIG1vZGUuCgogQ2xvdWQgU3RvcmFn
ZSBidWNrZXQgTG9nIGZpbGUgd2lsbCBiZSB3cml0dGVuIHRvCiBgZ3M6Ly8kR0NTX0JVQ0tF
VC8kUkVMQVRJVkVfUEFUSC8kVk1fREFURV8kVElNRS50YXIuZ3pgCgoMCgUEAAIABRIDKwII
CgwKBQQAAgABEgMrCRMKDAoFBAACAAMSAysWFwoMCgUEAAIACBIDKxhACg8KCAQAAgAInAgA
EgMrGT8KygIKBAQAAgESAzICRBq8AiBPcHRpb25hbC4gRGVmaW5lcyB0aGUgcmVsYXRpdmUg
c3RvcmFnZSBwYXRoIGluIHRoZSBDbG91ZCBTdG9yYWdlIGJ1Y2tldAogd2hlcmUgdGhlIGRp
YWdub3N0aWMgbG9ncyB3aWxsIGJlIHdyaXR0ZW46IERlZmF1bHQgcGF0aCB3aWxsIGJlIHRo
ZSByb290CiBkaXJlY3Rvcnkgb2YgdGhlIENsb3VkIFN0b3JhZ2UgYnVja2V0CiAoYGdzOi8v
JEdDU19CVUNLRVQvJERBVEVfJFRJTUUudGFyLmd6YCkgRXhhbXBsZSBvZiBmdWxsIHBhdGgg
d2hlcmUgTG9nIGZpbGUKIHdpbGwgYmUgd3JpdHRlbjogYGdzOi8vJEdDU19CVUNLRVQvJFJF
TEFUSVZFX1BBVEgvYAoKDAoFBAACAQUSAzICCAoMCgUEAAIBARIDMgkWCgwKBQQAAgEDEgMy
GRoKDAoFBAACAQgSAzIbQwoPCggEAAIBCJwIABIDMhxCCkQKBAQAAgISAzUCRxo3IE9wdGlv
bmFsLiBFbmFibGVzIGZsYWcgdG8gcmVwYWlyIHNlcnZpY2UgZm9yIGluc3RhbmNlCgoMCgUE
AAICBRIDNQIGCgwKBQQAAgIBEgM1BxkKDAoFBAACAgMSAzUcHQoMCgUEAAICCBIDNR5GCg8K
CAQAAgIInAgAEgM1H0UKWQoEBAACAxIDOAJPGkwgT3B0aW9uYWwuIEVuYWJsZXMgZmxhZyB0
byBjYXB0dXJlIHBhY2tldHMgZnJvbSB0aGUgaW5zdGFuY2UgZm9yIDMwIHNlY29uZHMKCgwK
BQQAAgMFEgM4AgYKDAoFBAACAwESAzgHIQoMCgUEAAIDAxIDOCQlCgwKBQQAAgMIEgM4Jk4K
DwoIBAACAwicCAASAzgnTQpRCgQEAAIEEgM7AlAaRCBPcHRpb25hbC4gRW5hYmxlcyBmbGFn
IHRvIGNvcHkgYWxsIGAvaG9tZS9qdXB5dGVyYCBmb2xkZXIgY29udGVudHMKCgwKBQQAAgQF
EgM7AgYKDAoFBAACBAESAzsHIgoMCgUEAAIEAxIDOyUmCgwKBQQAAgQIEgM7J08KDwoIBAAC
BAicCAASAzsoTmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Notebooks::V2::DiagnosticConfig::DiagnosticConfig ===
    # Fields for DiagnosticConfig
    # Field: gcs_bucket Type: 9 ()
    # Field: relative_path Type: 9 ()
    # Field: enable_repair_flag Type: 8 ()
    # Field: enable_packet_capture_flag Type: 8 ()
    # Field: enable_copy_home_files_flag Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Notebooks::V2::DiagnosticConfig - Compiled Protocol Buffers messages for google/cloud/notebooks/v2/diagnostic_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Notebooks::V2::DiagnosticConfig;

    my $msg = Google::Cloud::Notebooks::V2::DiagnosticConfig::DiagnosticConfig->new({
        gcs_bucket => $gcs_bucket,
        relative_path => $relative_path,
        enable_repair_flag => $enable_repair_flag,
        enable_packet_capture_flag => $enable_packet_capture_flag,
    });

    # Read or update a field
    my $val = $msg->gcs_bucket();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Notebooks::V2::DiagnosticConfig::DiagnosticConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/notebooks/v2/diagnostic_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Notebooks::V2::DiagnosticConfig::DiagnosticConfig

Defines flags that are used to run the diagnostic tool

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_bucket() >> / C<< $msg->gcs_bucket($value) >>

Type: C<String>

Required. User Cloud Storage bucket location (REQUIRED).
Must be formatted with path prefix (`gs://$GCS_BUCKET`).

Permissions:
User Managed Notebooks:
- storage.buckets.writer: Must be given to the project's service account
  attached to VM.
Google Managed Notebooks:
- storage.buckets.writer: Must be given to the project's service account or
  user credentials attached to VM depending on authentication mode.

Cloud Storage bucket Log file will be written to
`gs://$GCS_BUCKET/$RELATIVE_PATH/$VM_DATE_$TIME.tar.gz`

=item * C<< $msg->relative_path() >> / C<< $msg->relative_path($value) >>

Type: C<String>

Optional. Defines the relative storage path in the Cloud Storage bucket
where the diagnostic logs will be written: Default path will be the root
directory of the Cloud Storage bucket
(`gs://$GCS_BUCKET/$DATE_$TIME.tar.gz`) Example of full path where Log file
will be written: `gs://$GCS_BUCKET/$RELATIVE_PATH/`

=item * C<< $msg->enable_repair_flag() >> / C<< $msg->enable_repair_flag($value) >>

Type: C<Bool>

Optional. Enables flag to repair service for instance

=item * C<< $msg->enable_packet_capture_flag() >> / C<< $msg->enable_packet_capture_flag($value) >>

Type: C<Bool>

Optional. Enables flag to capture packets from the instance for 30 seconds

=item * C<< $msg->enable_copy_home_files_flag() >> / C<< $msg->enable_copy_home_files_flag($value) >>

Type: C<Bool>

Optional. Enables flag to copy all `/home/jupyter` folder contents

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Notebooks::V2::DiagnosticConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
