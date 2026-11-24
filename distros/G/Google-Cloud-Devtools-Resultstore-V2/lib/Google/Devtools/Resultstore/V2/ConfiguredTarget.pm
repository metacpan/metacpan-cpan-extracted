package Google::Devtools::Resultstore::V2::ConfiguredTarget;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Devtools::Resultstore::V2::Common };
    eval { require Google::Devtools::Resultstore::V2::File };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvY29uZmlndXJlZF90YXJnZXQucHJv
dG8SHmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52MhoZZ29vZ2xlL2FwaS9yZXNvdXJj
ZS5wcm90bxorZ29vZ2xlL2RldnRvb2xzL3Jlc3VsdHN0b3JlL3YyL2NvbW1vbi5wcm90bxop
Z29vZ2xlL2RldnRvb2xzL3Jlc3VsdHN0b3JlL3YyL2ZpbGUucHJvdG8aHmdvb2dsZS9wcm90
b2J1Zi9kdXJhdGlvbi5wcm90byLqBQoQQ29uZmlndXJlZFRhcmdldBISCgRuYW1lGAEgASgJ
UgRuYW1lEkMKAmlkGAIgASgLMjMuZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLkNv
bmZpZ3VyZWRUYXJnZXQuSWRSAmlkEl0KEXN0YXR1c19hdHRyaWJ1dGVzGAMgASgLMjAuZ29v
Z2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLlN0YXR1c0F0dHJpYnV0ZXNSEHN0YXR1c0F0
dHJpYnV0ZXMSPgoGdGltaW5nGAQgASgLMiYuZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3Jl
LnYyLlRpbWluZ1IGdGltaW5nEmEKD3Rlc3RfYXR0cmlidXRlcxgGIAEoCzI4Lmdvb2dsZS5k
ZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5Db25maWd1cmVkVGVzdEF0dHJpYnV0ZXNSDnRlc3RB
dHRyaWJ1dGVzEkgKCnByb3BlcnRpZXMYByADKAsyKC5nb29nbGUuZGV2dG9vbHMucmVzdWx0
c3RvcmUudjIuUHJvcGVydHlSCnByb3BlcnRpZXMSOgoFZmlsZXMYCCADKAsyJC5nb29nbGUu
ZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuRmlsZVIFZmlsZXMacQoCSWQSIwoNaW52b2NhdGlv
bl9pZBgBIAEoCVIMaW52b2NhdGlvbklkEhsKCXRhcmdldF9pZBgCIAEoCVIIdGFyZ2V0SWQS
KQoQY29uZmlndXJhdGlvbl9pZBgDIAEoCVIPY29uZmlndXJhdGlvbklkOoEB6kF+CityZXN1
bHRzdG9yZS5nb29nbGVhcGlzLmNvbS9Db25maWd1cmVkVGFyZ2V0Ek9pbnZvY2F0aW9ucy97
aW52b2NhdGlvbn0vdGFyZ2V0cy97dGFyZ2V0fS9jb25maWd1cmVkVGFyZ2V0cy97Y29uZmln
dXJlZF90YXJnZXR9IrQBChhDb25maWd1cmVkVGVzdEF0dHJpYnV0ZXMSJgoPdG90YWxfcnVu
X2NvdW50GAIgASgFUg10b3RhbFJ1bkNvdW50EioKEXRvdGFsX3NoYXJkX2NvdW50GAMgASgF
Ug90b3RhbFNoYXJkQ291bnQSRAoQdGltZW91dF9kdXJhdGlvbhgFIAEoCzIZLmdvb2dsZS5w
cm90b2J1Zi5EdXJhdGlvblIPdGltZW91dER1cmF0aW9uQogBCiJjb20uZ29vZ2xlLmRldnRv
b2xzLnJlc3VsdHN0b3JlLnYyQhVDb25maWd1cmVkVGFyZ2V0UHJvdG9QAVpJZ29vZ2xlLmdv
bGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9kZXZ0b29scy9yZXN1bHRzdG9yZS92Mjty
ZXN1bHRzdG9yZUqjGgoGEgQOAF4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAnCgkKAgMAEgMSACMKCQoCAwESAxMANQoJCgIDAhIDFAAzCgkKAgMDEgMV
ACgKCAoBCBIDFwBgCgkKAggLEgMXAGAKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQA2
CgkKAggIEgMZADYKCAoBCBIDGgA7CgkKAggBEgMaADsKpQIKAgQAEgQhAFEBGpgCIEVhY2gg
Q29uZmlndXJlZFRhcmdldCByZXByZXNlbnRzIGRhdGEgZm9yIGEgZ2l2ZW4gY29uZmlndXJh
dGlvbiBvZiBhIGdpdmVuCiB0YXJnZXQgaW4gYSBnaXZlbiBJbnZvY2F0aW9uLgogRXZlcnkg
Q29uZmlndXJlZFRhcmdldCBzaG91bGQgaGF2ZSBhdCBsZWFzdCBvbmUgQWN0aW9uIGFzIGEg
Y2hpbGQgcmVzb3VyY2UKIGJlZm9yZSB0aGUgaW52b2NhdGlvbiBpcyBmaW5hbGl6ZWQuIFJl
ZmVyIHRvIHRoZSBBY3Rpb24ncyBkb2N1bWVudGF0aW9uIGZvcgogbW9yZSBpbmZvIG9uIHRo
aXMuCgoKCgMEAAESAyEIGAoLCgMEAAcSBCICJQQKDQoFBAAHnQgSBCICJQQKTgoEBAADABIE
KAIxAxpAIFRoZSByZXNvdXJjZSBJRCBjb21wb25lbnRzIHRoYXQgaWRlbnRpZnkgdGhlIENv
bmZpZ3VyZWRUYXJnZXQuCgoMCgUEAAMAARIDKAoMCiMKBgQAAwACABIDKgQdGhQgVGhlIElu
dm9jYXRpb24gSUQuCgoOCgcEAAMAAgAFEgMqBAoKDgoHBAADAAIAARIDKgsYCg4KBwQAAwAC
AAMSAyobHAofCgYEAAMAAgESAy0EGRoQIFRoZSBUYXJnZXQgSUQuCgoOCgcEAAMAAgEFEgMt
BAoKDgoHBAADAAIBARIDLQsUCg4KBwQAAwACAQMSAy0XGAomCgYEAAMAAgISAzAEIBoXIFRo
ZSBDb25maWd1cmF0aW9uIElELgoKDgoHBAADAAICBRIDMAQKCg4KBwQAAwACAgESAzALGwoO
CgcEAAMAAgIDEgMwHh8K/AEKBAQAAgASAzcCEhruASBUaGUgcmVzb3VyY2UgbmFtZS4gIEl0
cyBmb3JtYXQgbXVzdCBiZToKIGludm9jYXRpb25zLyR7SU5WT0NBVElPTl9JRH0vdGFyZ2V0
cy8ke3VybF9lbmNvZGUoVEFSR0VUX0lEKX0vY29uZmlndXJlZFRhcmdldHMvJHt1cmxfZW5j
b2RlKENPTkZJR19JRCl9CiB3aGVyZSAke0NPTkZJR19JRH0gbXVzdCBtYXRjaCB0aGUgSUQg
b2YgYW4gZXhpc3RpbmcgQ29uZmlndXJhdGlvbiB1bmRlcgogdGhpcyBJbnZvY2F0aW9uLgoK
DAoFBAACAAUSAzcCCAoMCgUEAAIAARIDNwkNCgwKBQQAAgADEgM3EBEKhwEKBAQAAgESAzsC
DBp6IFRoZSByZXNvdXJjZSBJRCBjb21wb25lbnRzIHRoYXQgaWRlbnRpZnkgdGhlIENvbmZp
Z3VyZWRUYXJnZXQuIFRoZXkgbXVzdAogbWF0Y2ggdGhlIHJlc291cmNlIG5hbWUgYWZ0ZXIg
cHJvcGVyIGVuY29kaW5nLgoKDAoFBAACAQYSAzsCBAoMCgUEAAIBARIDOwUHCgwKBQQAAgED
EgM7CgsKqQEKBAQAAgISA0ACKRqbASBUaGUgYWdncmVnYXRlIHN0YXR1cyBmb3IgdGhpcyBj
b25maWd1cmF0aW9uIG9mIHRoaXMgdGFyZ2V0LiBJZiB0ZXN0aW5nCiB3YXMgbm90IHJlcXVl
c3RlZCwgc2V0IHRoaXMgdG8gdGhlIGJ1aWxkIHN0YXR1cyAoZS5nLiBCVUlMVCBvcgogRkFJ
TEVEX1RPX0JVSUxEKS4KCgwKBQQAAgIGEgNAAhIKDAoFBAACAgESA0ATJAoMCgUEAAICAxID
QCcoCk4KBAQAAgMSA0MCFBpBIENhcHR1cmVzIHRoZSBzdGFydCB0aW1lIGFuZCBkdXJhdGlv
biBvZiB0aGlzIGNvbmZpZ3VyZWQgdGFyZ2V0LgoKDAoFBAACAwYSA0MCCAoMCgUEAAIDARID
QwkPCgwKBQQAAgMDEgNDEhMKQgoEBAACBBIDRgIvGjUgVGVzdCBzcGVjaWZpYyBhdHRyaWJ1
dGVzIGZvciB0aGlzIENvbmZpZ3VyZWRUYXJnZXQuCgoMCgUEAAIEBhIDRgIaCgwKBQQAAgQB
EgNGGyoKDAoFBAACBAMSA0YtLgrBAQoEBAACBRIDSwIjGrMBIEFyYml0cmFyeSBuYW1lLXZh
bHVlIHBhaXJzLgogVGhpcyBpcyBpbXBsZW1lbnRlZCBhcyBhIG11bHRpLW1hcC4gTXVsdGlw
bGUgcHJvcGVydGllcyBhcmUgYWxsb3dlZCB3aXRoCiB0aGUgc2FtZSBrZXkuIFByb3BlcnRp
ZXMgd2lsbCBiZSByZXR1cm5lZCBpbiBsZXhpY29ncmFwaGljYWwgb3JkZXIgYnkga2V5LgoK
DAoFBAACBQQSA0sCCgoMCgUEAAIFBhIDSwsTCgwKBQQAAgUBEgNLFB4KDAoFBAACBQMSA0sh
IgrfAQoEBAACBhIDUAIaGtEBIEEgbGlzdCBvZiBmaWxlIHJlZmVyZW5jZXMgZm9yIGNvbmZp
Z3VyZWQgdGFyZ2V0IGxldmVsIGZpbGVzLgogVGhlIGZpbGUgSURzIG11c3QgYmUgdW5pcXVl
IHdpdGhpbiB0aGlzIGxpc3QuIER1cGxpY2F0ZSBmaWxlIElEcyB3aWxsCiByZXN1bHQgaW4g
YW4gZXJyb3IuIEZpbGVzIHdpbGwgYmUgcmV0dXJuZWQgaW4gbGV4aWNvZ3JhcGhpY2FsIG9y
ZGVyIGJ5IElELgoKDAoFBAACBgQSA1ACCgoMCgUEAAIGBhIDUAsPCgwKBQQAAgYBEgNQEBUK
DAoFBAACBgMSA1AYGQpWCgIEARIEVABeARpKIEF0dHJpYnV0ZXMgdGhhdCBhcHBseSBvbmx5
IHRvIHRlc3QgYWN0aW9ucyB1bmRlciB0aGlzIGNvbmZpZ3VyZWQgdGFyZ2V0LgoKCgoDBAEB
EgNUCCAKiwEKBAQBAgASA1cCHBp+IFRvdGFsIG51bWJlciBvZiB0ZXN0IHJ1bnMuIEZvciBl
eGFtcGxlLCBpbiBiYXplbCB0aGlzIGlzIHNwZWNpZmllZCB3aXRoCiAtLXJ1bnNfcGVyX3Rl
c3QuIFplcm8gaWYgcnVuc19wZXJfdGVzdCBpcyBub3QgdXNlZC4KCgwKBQQBAgAFEgNXAgcK
DAoFBAECAAESA1cIFwoMCgUEAQIAAxIDVxobClIKBAQBAgESA1oCHhpFIFRvdGFsIG51bWJl
ciBvZiB0ZXN0IHNoYXJkcy4gWmVybyBpZiBzaGFyZCBjb3VudCB3YXMgbm90IHNwZWNpZmll
ZC4KCgwKBQQBAgEFEgNaAgcKDAoFBAECAQESA1oIGQoMCgUEAQIBAxIDWhwdCi8KBAQBAgIS
A10CMBoiIEhvdyBsb25nIHRlc3QgaXMgYWxsb3dlZCB0byBydW4uCgoMCgUEAQICBhIDXQIa
CgwKBQQBAgIBEgNdGysKDAoFBAECAgMSA10uL2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTarget ===
    # Fields for ConfiguredTarget
    # Field: name Type: 9 ()
    # Field: id Type: 11 (.google.devtools.resultstore.v2.ConfiguredTarget.Id)
    # Field: status_attributes Type: 11 (.google.devtools.resultstore.v2.StatusAttributes)
    # Field: timing Type: 11 (.google.devtools.resultstore.v2.Timing)
    # Field: test_attributes Type: 11 (.google.devtools.resultstore.v2.ConfiguredTestAttributes)
    # Field: properties Type: 11 (.google.devtools.resultstore.v2.Property)
    # Field: files Type: 11 (.google.devtools.resultstore.v2.File)

# === Message: Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTestAttributes ===
    # Fields for ConfiguredTestAttributes
    # Field: total_run_count Type: 5 ()
    # Field: total_shard_count Type: 5 ()
    # Field: timeout_duration Type: 11 (.google.protobuf.Duration)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Resultstore::V2::ConfiguredTarget - Compiled Protocol Buffers messages for google/devtools/resultstore/v2/configured_target.proto

=head1 SYNOPSIS

    use Google::Devtools::Resultstore::V2::ConfiguredTarget;

    my $msg = Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTarget->new({
        name => $name,
        id => $id,
        status_attributes => $status_attributes,
        timing => $timing,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTarget->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/resultstore/v2/configured_target.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTarget

Each ConfiguredTarget represents data for a given configuration of a given
target in a given Invocation.
Every ConfiguredTarget should have at least one Action as a child resource
before the invocation is finalized. Refer to the Action's documentation for
more info on this.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name.  Its format must be:
invocations/${INVOCATION_ID}/targets/${url_encode(TARGET_ID)}/configuredTargets/${url_encode(CONFIG_ID)}
where ${CONFIG_ID} must match the ID of an existing Configuration under
this Invocation.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTarget::Id>)

The resource ID components that identify the ConfiguredTarget. They must
match the resource name after proper encoding.

=item * C<< $msg->status_attributes() >> / C<< $msg->status_attributes($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::StatusAttributes>)

The aggregate status for this configuration of this target. If testing
was not requested, set this to the build status (e.g. BUILT or
FAILED_TO_BUILD).

=item * C<< $msg->timing() >> / C<< $msg->timing($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::Timing>)

Captures the start time and duration of this configured target.

=item * C<< $msg->test_attributes() >> / C<< $msg->test_attributes($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTestAttributes>)

Test specific attributes for this ConfiguredTarget.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::Property>)

Arbitrary name-value pairs.
This is implemented as a multi-map. Multiple properties are allowed with
the same key. Properties will be returned in lexicographical order by key.

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::File::File>)

A list of file references for configured target level files.
The file IDs must be unique within this list. Duplicate file IDs will
result in an error. Files will be returned in lexicographical order by ID.

=back

=head2 Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTestAttributes

Attributes that apply only to test actions under this configured target.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->total_run_count() >> / C<< $msg->total_run_count($value) >>

Type: C<Int32>

Total number of test runs. For example, in bazel this is specified with
--runs_per_test. Zero if runs_per_test is not used.

=item * C<< $msg->total_shard_count() >> / C<< $msg->total_shard_count($value) >>

Type: C<Int32>

Total number of test shards. Zero if shard count was not specified.

=item * C<< $msg->timeout_duration() >> / C<< $msg->timeout_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

How long test is allowed to run.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Resultstore::V2::ConfiguredTarget::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
