package Google::Cloud::Agentregistry::V1::Binding;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvYWdlbnRyZWdpc3RyeS92MS9iaW5kaW5nLnByb3RvEh1nb29nbGUu
Y2xvdWQuYWdlbnRyZWdpc3RyeS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFt
cC5wcm90byKEBwoHQmluZGluZxJwChVhdXRoX3Byb3ZpZGVyX2JpbmRpbmcYBiABKAsyOi5n
b29nbGUuY2xvdWQuYWdlbnRyZWdpc3RyeS52MS5CaW5kaW5nLkF1dGhQcm92aWRlckJpbmRp
bmdIAFITYXV0aFByb3ZpZGVyQmluZGluZxIaCgRuYW1lGAEgASgJQgbgQQjgQQJSBG5hbWUS
JgoMZGlzcGxheV9uYW1lGAIgASgJQgPgQQFSC2Rpc3BsYXlOYW1lEiUKC2Rlc2NyaXB0aW9u
GAMgASgJQgPgQQFSC2Rlc2NyaXB0aW9uEkoKBnNvdXJjZRgEIAEoCzItLmdvb2dsZS5jbG91
ZC5hZ2VudHJlZ2lzdHJ5LnYxLkJpbmRpbmcuU291cmNlQgPgQQFSBnNvdXJjZRJKCgZ0YXJn
ZXQYBSABKAsyLS5nb29nbGUuY2xvdWQuYWdlbnRyZWdpc3RyeS52MS5CaW5kaW5nLlRhcmdl
dEID4EECUgZ0YXJnZXQSQAoLY3JlYXRlX3RpbWUYByABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYCCABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUaOQoGU291cmNlEiAKCmlk
ZW50aWZpZXIYASABKAlIAFIKaWRlbnRpZmllckINCgtzb3VyY2VfdHlwZRo5CgZUYXJnZXQS
IAoKaWRlbnRpZmllchgBIAEoCUgAUgppZGVudGlmaWVyQg0KC3RhcmdldF90eXBlGoQBChNB
dXRoUHJvdmlkZXJCaW5kaW5nEigKDWF1dGhfcHJvdmlkZXIYASABKAlCA+BBAlIMYXV0aFBy
b3ZpZGVyEhsKBnNjb3BlcxgCIAMoCUID4EEBUgZzY29wZXMSJgoMY29udGludWVfdXJpGAMg
ASgJQgPgQQFSC2NvbnRpbnVlVXJpOnjqQXUKJGFnZW50cmVnaXN0cnkuZ29vZ2xlYXBpcy5j
b20vQmluZGluZxI6cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Jp
bmRpbmdzL3tiaW5kaW5nfSoIYmluZGluZ3MyB2JpbmRpbmdCCQoHYmluZGluZ0LfAQohY29t
Lmdvb2dsZS5jbG91ZC5hZ2VudHJlZ2lzdHJ5LnYxQgxCaW5kaW5nUHJvdG9QAVpHY2xvdWQu
Z29vZ2xlLmNvbS9nby9hZ2VudHJlZ2lzdHJ5L2FwaXYxL2FnZW50cmVnaXN0cnlwYjthZ2Vu
dHJlZ2lzdHJ5cGKqAh1Hb29nbGUuQ2xvdWQuQWdlbnRSZWdpc3RyeS5WMcoCHUdvb2dsZVxD
bG91ZFxBZ2VudFJlZ2lzdHJ5XFYx6gIgR29vZ2xlOjpDbG91ZDo6QWdlbnRSZWdpc3RyeTo6
VjFKtR0KBhIEDgB3AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAAJgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWADoKCQoCCCUS
AxYAOgoICgEIEgMXAF4KCQoCCAsSAxcAXgoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZ
AC0KCQoCCAgSAxkALQoICgEIEgMaADoKCQoCCAESAxoAOgoICgEIEgMbADoKCQoCCCkSAxsA
OgoICgEIEgMcADkKCQoCCC0SAxwAOQowCgIEABIEHwB3ARokIFJlcHJlc2VudHMgYSB1c2Vy
LWRlZmluZWQgQmluZGluZy4KCgoKAwQAARIDHwgPCgsKAwQABxIEIAIlBAoNCgUEAAedCBIE
IAIlBAoqCgQEAAMAEgQoAjIDGhwgVGhlIHNvdXJjZSBvZiB0aGUgQmluZGluZy4KCgwKBQQA
AwABEgMoChAKdgoGBAADAAgAEgQrBDEFGmYgVGhlIHR5cGUgb2YgdGhlIHNvdXJjZSwgY3Vy
cmVudGx5IG9ubHkgc3VwcG9ydHMgQWdlbnRzLgogUG90ZW50aWFsIGZ1dHVyZSBmaWVsZHMg
aW5jbHVkZSAndGFnJywgZXRjLgoKDgoHBAADAAgAARIDKwoVCmwKBgQAAwACABIDMAYcGl0g
VGhlIGlkZW50aWZpZXIgb2YgdGhlIHNvdXJjZSBBZ2VudC4KIEZvcm1hdDoKCiAqIGB1cm46
YWdlbnQ6e3B1Ymxpc2hlcn06e25hbWVzcGFjZX06e25hbWV9YAoKDgoHBAADAAIABRIDMAYM
Cg4KBwQAAwACAAESAzANFwoOCgcEAAMAAgADEgMwGhsKKgoEBAADARIENQJCAxocIFRoZSB0
YXJnZXQgb2YgdGhlIEJpbmRpbmcuCgoMCgUEAAMBARIDNQoQCooBCgYEAAMBCAASBDkEQQUa
eiBUaGUgdHlwZSBvZiB0aGUgdGFyZ2V0LCBjdXJyZW50bHkgb25seSBzdXBwb3J0cyBhbiBB
Z2VudFJlZ2lzdHJ5CiBSZXNvdXJjZS4KIFBvdGVudGlhbCBmdXR1cmUgZmllbGRzIGluY2x1
ZGUgJ3RhZycsIGV0Yy4KCg4KBwQAAwEIAAESAzkKFQrjAQoGBAADAQIAEgNABhwa0wEgVGhl
IGlkZW50aWZpZXIgb2YgdGhlIHRhcmdldCBBZ2VudCwgTUNQIFNlcnZlciwgb3IgRW5kcG9p
bnQuCiBGb3JtYXQ6CgogKiBgdXJuOmFnZW50OntwdWJsaXNoZXJ9OntuYW1lc3BhY2V9Ontu
YW1lfWAKICogYHVybjptY3A6e3B1Ymxpc2hlcn06e25hbWVzcGFjZX06e25hbWV9YAogKiBg
dXJuOmVuZHBvaW50OntwdWJsaXNoZXJ9OntuYW1lc3BhY2V9OntuYW1lfWAKCg4KBwQAAwEC
AAUSA0AGDAoOCgcEAAMBAgABEgNADRcKDgoHBAADAQIAAxIDQBobCjAKBAQAAwISBEUCUwMa
IiBUaGUgQXV0aFByb3ZpZGVyIG9mIHRoZSBCaW5kaW5nLgoKDAoFBAADAgESA0UKHQqeAQoG
BAADAgIAEgNKBEYajgEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSB0YXJn
ZXQgQXV0aFByb3ZpZGVyLgogRm9ybWF0OgoKICogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9hdXRoUHJvdmlkZXJzL3thdXRoX3Byb3ZpZGVyfWAKCg4KBwQA
AwICAAUSA0oECgoOCgcEAAMCAgABEgNKCxgKDgoHBAADAgIAAxIDShscCg4KBwQAAwICAAgS
A0odRQoRCgoEAAMCAgAInAgAEgNKHkQKSQoGBAADAgIBEgNNBEgaOiBPcHRpb25hbC4gVGhl
IGxpc3Qgb2YgT0F1dGgyIHNjb3BlcyBvZiB0aGUgQXV0aFByb3ZpZGVyLgoKDgoHBAADAgIB
BBIDTQQMCg4KBwQAAwICAQUSA00NEwoOCgcEAAMCAgEBEgNNFBoKDgoHBAADAgIBAxIDTR0e
Cg4KBwQAAwICAQgSA00fRwoRCgoEAAMCAgEInAgAEgNNIEYKkwEKBgQAAwICAhIDUgRFGoMB
IE9wdGlvbmFsLiBUaGUgY29udGludWUgVVJJIG9mIHRoZSBBdXRoUHJvdmlkZXIuCiBUaGUg
VVJJIGlzIHVzZWQgdG8gcmVhdXRoZW50aWNhdGUgdGhlIHVzZXIgYW5kIGZpbmFsaXplIHRo
ZSBtYW5hZ2VkIE9BdXRoCiBmbG93LgoKDgoHBAADAgICBRIDUgQKCg4KBwQAAwICAgESA1IL
FwoOCgcEAAMCAgIDEgNSGhsKDgoHBAADAgICCBIDUhxEChEKCgQAAwICAgicCAASA1IdQwoy
CgQEAAgAEgRWAlkDGiQgVGhlIGNvbmZpZ3VyYXRpb24gZm9yIHRoZSBCaW5kaW5nLgoKDAoF
BAAIAAESA1YIDwosCgQEAAIAEgNYBDIaHyBUaGUgYmluZGluZyBmb3IgQXV0aFByb3ZpZGVy
LgoKDAoFBAACAAYSA1gEFwoMCgUEAAIAARIDWBgtCgwKBQQAAgADEgNYMDEKjwEKBAQAAgES
BF0CYAQagAEgUmVxdWlyZWQuIElkZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRo
ZSBCaW5kaW5nLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2JpbmRpbmdzL3tiaW5kaW5nfWAuCgoMCgUEAAIBBRIDXQIICgwKBQQAAgEBEgNd
CQ0KDAoFBAACAQMSA10QEQoNCgUEAAIBCBIEXRJgAwoPCggEAAIBCJwIABIDXgQsCg8KCAQA
AgEInAgBEgNfBCoKcgoEBAACAhIDZAJDGmUgT3B0aW9uYWwuIFVzZXItZGVmaW5lZCBkaXNw
bGF5IG5hbWUgZm9yIHRoZSBCaW5kaW5nLgogQ2FuIGhhdmUgYSBtYXhpbXVtIGxlbmd0aCBv
ZiBgNjNgIGNoYXJhY3RlcnMuCgoMCgUEAAICBRIDZAIICgwKBQQAAgIBEgNkCRUKDAoFBAAC
AgMSA2QYGQoMCgUEAAICCBIDZBpCCg8KCAQAAgIInAgAEgNkG0EKcAoEBAACAxIDaAJCGmMg
T3B0aW9uYWwuIFVzZXItZGVmaW5lZCBkZXNjcmlwdGlvbiBvZiBhIEJpbmRpbmcuCiBDYW4g
aGF2ZSBhIG1heGltdW0gbGVuZ3RoIG9mIGAyMDQ4YCBjaGFyYWN0ZXJzLgoKDAoFBAACAwUS
A2gCCAoMCgUEAAIDARIDaAkUCgwKBQQAAgMDEgNoFxgKDAoFBAACAwgSA2gZQQoPCggEAAID
CJwIABIDaBpACjkKBAQAAgQSA2sCPRosIE9wdGlvbmFsLiBUaGUgc291cmNlIEFnZW50IG9m
IHRoZSBCaW5kaW5nLgoKDAoFBAACBAYSA2sCCAoMCgUEAAIEARIDawkPCgwKBQQAAgQDEgNr
EhMKDAoFBAACBAgSA2sUPAoPCggEAAIECJwIABIDaxU7CksKBAQAAgUSA24CPRo+IFJlcXVp
cmVkLiBUaGUgdGFyZ2V0IEFnZW50IFJlZ2lzdHJ5IFJlc291cmNlIG9mIHRoZSBCaW5kaW5n
LgoKDAoFBAACBQYSA24CCAoMCgUEAAIFARIDbgkPCgwKBQQAAgUDEgNuEhMKDAoFBAACBQgS
A24UPAoPCggEAAIFCJwIABIDbhU7CkUKBAQAAgYSBHECcjIaNyBPdXRwdXQgb25seS4gVGlt
ZXN0YW1wIHdoZW4gdGhpcyBiaW5kaW5nIHdhcyBjcmVhdGVkLgoKDAoFBAACBgYSA3ECGwoM
CgUEAAIGARIDcRwnCgwKBQQAAgYDEgNxKisKDAoFBAACBggSA3IGMQoPCggEAAIGCJwIABID
cgcwCkoKBAQAAgcSBHUCdjIaPCBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhpcyBi
aW5kaW5nIHdhcyBsYXN0IHVwZGF0ZWQuCgoMCgUEAAIHBhIDdQIbCgwKBQQAAgcBEgN1HCcK
DAoFBAACBwMSA3UqKwoMCgUEAAIHCBIDdgYxCg8KCAQAAgcInAgAEgN2BzBiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Agentregistry::V1::Binding::Binding ===
    # Fields for Binding
    # Field: auth_provider_binding Type: 11 (.google.cloud.agentregistry.v1.Binding.AuthProviderBinding)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: source Type: 11 (.google.cloud.agentregistry.v1.Binding.Source)
    # Field: target Type: 11 (.google.cloud.agentregistry.v1.Binding.Target)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Agentregistry::V1::Binding - Compiled Protocol Buffers messages for google/cloud/agentregistry/v1/binding.proto

=head1 SYNOPSIS

    use Google::Cloud::Agentregistry::V1::Binding;

    my $msg = Google::Cloud::Agentregistry::V1::Binding::Binding->new({
        auth_provider_binding => $auth_provider_binding,
        name => $name,
        display_name => $display_name,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->auth_provider_binding();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Agentregistry::V1::Binding::Binding->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/agentregistry/v1/binding.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Agentregistry::V1::Binding::Binding

Represents a user-defined Binding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->auth_provider_binding() >> / C<< $msg->auth_provider_binding($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Binding::Binding::AuthProviderBinding>)

The binding for AuthProvider.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Identifier. The resource name of the Binding.
Format: `projects/{project}/locations/{location}/bindings/{binding}`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. User-defined display name for the Binding.
Can have a maximum length of `63` characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User-defined description of a Binding.
Can have a maximum length of `2048` characters.

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Binding::Binding::Source>)

Optional. The source Agent of the Binding.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Binding::Binding::Target>)

Required. The target Agent Registry Resource of the Binding.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when this binding was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when this binding was last updated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Agentregistry::V1::Binding::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
