package Google::Devtools::Build::V1::BuildStatus;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Any };
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvZGV2dG9vbHMvYnVpbGQvdjEvYnVpbGRfc3RhdHVzLnByb3RvEhhnb29nbGUu
ZGV2dG9vbHMuYnVpbGQudjEaGWdvb2dsZS9wcm90b2J1Zi9hbnkucHJvdG8aHmdvb2dsZS9w
cm90b2J1Zi93cmFwcGVycy5wcm90byL6AwoLQnVpbGRTdGF0dXMSRAoGcmVzdWx0GAEgASgO
MiwuZ29vZ2xlLmRldnRvb2xzLmJ1aWxkLnYxLkJ1aWxkU3RhdHVzLlJlc3VsdFIGcmVzdWx0
Ei4KE2ZpbmFsX2ludm9jYXRpb25faWQYAyABKAlSEWZpbmFsSW52b2NhdGlvbklkEkwKFGJ1
aWxkX3Rvb2xfZXhpdF9jb2RlGAQgASgLMhsuZ29vZ2xlLnByb3RvYnVmLkludDMyVmFsdWVS
EWJ1aWxkVG9vbEV4aXRDb2RlEiMKDWVycm9yX21lc3NhZ2UYBSABKAlSDGVycm9yTWVzc2Fn
ZRIuCgdkZXRhaWxzGAIgASgLMhQuZ29vZ2xlLnByb3RvYnVmLkFueVIHZGV0YWlscyLRAQoG
UmVzdWx0EhIKDlVOS05PV05fU1RBVFVTEAASFQoRQ09NTUFORF9TVUNDRUVERUQQARISCg5D
T01NQU5EX0ZBSUxFRBACEg4KClVTRVJfRVJST1IQAxIQCgxTWVNURU1fRVJST1IQBBIWChJS
RVNPVVJDRV9FWEhBVVNURUQQBRIgChxJTlZPQ0FUSU9OX0RFQURMSU5FX0VYQ0VFREVEEAYS
HQoZUkVRVUVTVF9ERUFETElORV9FWENFRURFRBAIEg0KCUNBTkNFTExFRBAHQowBChxjb20u
Z29vZ2xlLmRldnRvb2xzLmJ1aWxkLnYxQhBCdWlsZFN0YXR1c1Byb3RvUAFaPWdvb2dsZS5n
b2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvZGV2dG9vbHMvYnVpbGQvdjE7YnVpbGT4
AQHKAhVHb29nbGVcQ2xvdWRcQnVpbGRcVjFKsxMKBhIEDgBMAQq8BAoBDBIDDgASMrEEIENv
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
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIQoJCgIDABIDEgAjCgkKAgMBEgMTACgKCAoB
CBIDFQAfCgkKAggfEgMVAB8KCAoBCBIDFgBUCgkKAggLEgMWAFQKCAoBCBIDFwAiCgkKAggK
EgMXACIKCAoBCBIDGAAxCgkKAggIEgMYADEKCAoBCBIDGQA1CgkKAggBEgMZADUKCAoBCBID
GgAyCgkKAggpEgMaADIKUwoCBAASBB0ATAEaRyBTdGF0dXMgdXNlZCBmb3IgYm90aCBpbnZv
Y2F0aW9uIGF0dGVtcHQgYW5kIG92ZXJhbGwgYnVpbGQgY29tcGxldGlvbi4KCgoKAwQAARID
HQgTCiwKBAQABAASBB8COgMaHiBUaGUgZW5kIHJlc3VsdCBvZiB0aGUgQnVpbGQuCgoMCgUE
AAQAARIDHwcNCigKBgQABAACABIDIQQXGhkgVW5zcGVjaWZpZWQgb3IgdW5rbm93bi4KCg4K
BwQABAACAAESAyEEEgoOCgcEAAQAAgACEgMhFRYKSAoGBAAEAAIBEgMkBBoaOSBCdWlsZCB3
YXMgc3VjY2Vzc2Z1bCBhbmQgdGVzdHMgKGlmIHJlcXVlc3RlZCkgYWxsIHBhc3MuCgoOCgcE
AAQAAgEBEgMkBBUKDgoHBAAEAAIBAhIDJBgZCjEKBgQABAACAhIDJwQXGiIgQnVpbGQgZXJy
b3IgYW5kL29yIHRlc3QgZmFpbHVyZS4KCg4KBwQABAACAgESAycEEgoOCgcEAAQAAgICEgMn
FRYKTQoGBAAEAAIDEgMqBBMaPiBVbmFibGUgdG8gb2J0YWluIGEgcmVzdWx0IGR1ZSB0byBp
bnB1dCBwcm92aWRlZCBieSB0aGUgdXNlci4KCg4KBwQABAACAwESAyoEDgoOCgcEAAQAAgMC
EgMqERIKVAoGBAAEAAIEEgMtBBUaRSBVbmFibGUgdG8gb2J0YWluIGEgcmVzdWx0IGR1ZSB0
byBhIGZhaWx1cmUgd2l0aGluIHRoZSBidWlsZCBzeXN0ZW0uCgoOCgcEAAQAAgQBEgMtBBAK
DgoHBAAEAAIEAhIDLRMUCksKBgQABAACBRIDMAQbGjwgQnVpbGQgcmVxdWlyZWQgdG9vIG1h
bnkgcmVzb3VyY2VzLCBzdWNoIGFzIGJ1aWxkIHRvb2wgUkFNLgoKDgoHBAAEAAIFARIDMAQW
Cg4KBwQABAACBQISAzAZGgpCCgYEAAQAAgYSAzMEJRozIEFuIGludm9jYXRpb24gYXR0ZW1w
dCB0aW1lIGV4Y2VlZGVkIGl0cyBkZWFkbGluZS4KCg4KBwQABAACBgESAzMEIAoOCgcEAAQA
AgYCEgMzIyQKQQoGBAAEAAIHEgM2BCIaMiBCdWlsZCByZXF1ZXN0IHRpbWUgZXhjZWVkZWQg
dGhlIHJlcXVlc3RfZGVhZGxpbmUKCg4KBwQABAACBwESAzYEHQoOCgcEAAQAAgcCEgM2ICEK
QgoGBAAEAAIIEgM5BBIaMyBUaGUgYnVpbGQgd2FzIGNhbmNlbGxlZCBieSBhIGNhbGwgdG8g
Q2FuY2VsQnVpbGQuCgoOCgcEAAQAAggBEgM5BA0KDgoHBAAEAAIIAhIDORARCh4KBAQAAgAS
Az0CFBoRIFRoZSBlbmQgcmVzdWx0LgoKDAoFBAACAAYSAz0CCAoMCgUEAAIAARIDPQkPCgwK
BQQAAgADEgM9EhMKfgoEBAACARIDQQIhGnEgRmluYWwgaW52b2NhdGlvbiBJRCBvZiB0aGUg
YnVpbGQsIGlmIHRoZXJlIHdhcyBvbmUuCiBUaGlzIGZpZWxkIGlzIG9ubHkgc2V0IG9uIGEg
c3RhdHVzIGluIEJ1aWxkRmluaXNoZWQgZXZlbnQuCgoMCgUEAAIBBRIDQQIICgwKBQQAAgEB
EgNBCRwKDAoFBAACAQMSA0EfIAqWAQoEBAACAhIDRQI2GogBIEJ1aWxkIHRvb2wgZXhpdCBj
b2RlLiBJbnRlZ2VyIHZhbHVlIHJldHVybmVkIGJ5IHRoZSBleGVjdXRlZCBidWlsZCB0b29s
LgogTWlnaHQgbm90IGJlIGF2YWlsYWJsZSBpbiBzb21lIGNhc2VzLCBlLmcuLCBhIGJ1aWxk
IHRpbWVvdXQuCgoMCgUEAAICBhIDRQIcCgwKBQQAAgIBEgNFHTEKDAoFBAACAgMSA0U0NQpS
CgQEAAIDEgNIAhsaRSBIdW1hbi1yZWFkYWJsZSBlcnJvciBtZXNzYWdlLiBEbyBub3QgdXNl
IGZvciBwcm9ncmFtbWF0aWMgcHVycG9zZXMuCgoMCgUEAAIDBRIDSAIICgwKBQQAAgMBEgNI
CRYKDAoFBAACAwMSA0gZGgpMCgQEAAIEEgNLAiIaPyBGaW5lLWdyYWluZWQgZGlhZ25vc3Rp
YyBpbmZvcm1hdGlvbiB0byBjb21wbGVtZW50IHRoZSBzdGF0dXMuCgoMCgUEAAIEBhIDSwIV
CgwKBQQAAgQBEgNLFh0KDAoFBAACBAMSA0sgIWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Build::V1::BuildStatus::BuildStatus ===
    # Fields for BuildStatus
    # Field: result Type: 14 (.google.devtools.build.v1.BuildStatus.Result)
    # Field: final_invocation_id Type: 9 ()
    # Field: build_tool_exit_code Type: 11 (.google.protobuf.Int32Value)
    # Field: error_message Type: 9 ()
    # Field: details Type: 11 (.google.protobuf.Any)

# Enum: BuildStatus::Result
our $BuildStatus_UNKNOWN_STATUS = 0;
our $BuildStatus_COMMAND_SUCCEEDED = 1;
our $BuildStatus_COMMAND_FAILED = 2;
our $BuildStatus_USER_ERROR = 3;
our $BuildStatus_SYSTEM_ERROR = 4;
our $BuildStatus_RESOURCE_EXHAUSTED = 5;
our $BuildStatus_INVOCATION_DEADLINE_EXCEEDED = 6;
our $BuildStatus_REQUEST_DEADLINE_EXCEEDED = 8;
our $BuildStatus_CANCELLED = 7;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Build::V1::BuildStatus - Compiled Protocol Buffers messages for google/devtools/build/v1/build_status.proto

=head1 SYNOPSIS

    use Google::Devtools::Build::V1::BuildStatus;

    my $msg = Google::Devtools::Build::V1::BuildStatus::BuildStatus->new({
        result => $result,
        final_invocation_id => $final_invocation_id,
        build_tool_exit_code => $build_tool_exit_code,
        error_message => $error_message,
    });

    # Read or update a field
    my $val = $msg->result();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Build::V1::BuildStatus::BuildStatus->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/build/v1/build_status.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Build::V1::BuildStatus::BuildStatus

Status used for both invocation attempt and overall build completion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->result() >> / C<< $msg->result($value) >>

Type: C<Enum> (L<Google::Devtools::Build::V1::BuildStatus::Result>)

The end result.

=item * C<< $msg->final_invocation_id() >> / C<< $msg->final_invocation_id($value) >>

Type: C<String>

Final invocation ID of the build, if there was one.
This field is only set on a status in BuildFinished event.

=item * C<< $msg->build_tool_exit_code() >> / C<< $msg->build_tool_exit_code($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::Int32Value>)

Build tool exit code. Integer value returned by the executed build tool.
Might not be available in some cases, e.g., a build timeout.

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

Human-readable error message. Do not use for programmatic purposes.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

Fine-grained diagnostic information to complement the status.

=back

=head3 Enum: BuildStatus::Result

=over 4

=item * C<UNKNOWN_STATUS> => C<0>

=item * C<COMMAND_SUCCEEDED> => C<1>

=item * C<COMMAND_FAILED> => C<2>

=item * C<USER_ERROR> => C<3>

=item * C<SYSTEM_ERROR> => C<4>

=item * C<RESOURCE_EXHAUSTED> => C<5>

=item * C<INVOCATION_DEADLINE_EXCEEDED> => C<6>

=item * C<REQUEST_DEADLINE_EXCEEDED> => C<8>

=item * C<CANCELLED> => C<7>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Build::V1::BuildStatus::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
