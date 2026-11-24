package Google::Cloud::Databasecenter::V1beta::Affiliation;

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
CjRnb29nbGUvY2xvdWQvZGF0YWJhc2VjZW50ZXIvdjFiZXRhL2FmZmlsaWF0aW9uLnByb3Rv
EiJnb29nbGUuY2xvdWQuZGF0YWJhc2VjZW50ZXIudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvIqYECgtBZmZpbGlhdGlvbhIkCgtyZXNvdXJjZV9pZBgBIAEoCUID
4EEBUgpyZXNvdXJjZUlkEjEKEmZ1bGxfcmVzb3VyY2VfbmFtZRgCIAEoCUID4EEBUhBmdWxs
UmVzb3VyY2VOYW1lElgKCGxpbmVhZ2VzGAMgAygLMjcuZ29vZ2xlLmNsb3VkLmRhdGFiYXNl
Y2VudGVyLnYxYmV0YS5BZmZpbGlhdGlvbi5MaW5lYWdlQgPgQQFSCGxpbmVhZ2VzGtwBCgdM
aW5lYWdlEiIKCnNvdXJjZV9mcW4YASABKAlCA+BBAVIJc291cmNlRnFuEiIKCnRhcmdldF9m
cW4YAiABKAlCA+BBAVIJdGFyZ2V0RnFuEiQKC3Byb2Nlc3NfZnFuGAMgASgJQgPgQQFSCnBy
b2Nlc3NGcW4SYwoMcHJvY2Vzc190eXBlGAQgASgOMjsuZ29vZ2xlLmNsb3VkLmRhdGFiYXNl
Y2VudGVyLnYxYmV0YS5BZmZpbGlhdGlvbi5Qcm9jZXNzVHlwZUID4EEBUgtwcm9jZXNzVHlw
ZSKEAQoLUHJvY2Vzc1R5cGUSHAoYUFJPQ0VTU19UWVBFX1VOU1BFQ0lGSUVEEAASDAoIQ09N
UE9TRVIQARIOCgpEQVRBU1RSRUFNEAISDAoIREFUQUZMT1cQAxIMCghCSUdRVUVSWRAEEg8K
C0RBVEFfRlVTSU9OEAUSDAoIREFUQVBST0MQBkL+AQomY29tLmdvb2dsZS5jbG91ZC5kYXRh
YmFzZWNlbnRlci52MWJldGFCEEFmZmlsaWF0aW9uUHJvdG9QAVpOY2xvdWQuZ29vZ2xlLmNv
bS9nby9kYXRhYmFzZWNlbnRlci9hcGl2MWJldGEvZGF0YWJhc2VjZW50ZXJwYjtkYXRhYmFz
ZWNlbnRlcnBiqgIiR29vZ2xlLkNsb3VkLkRhdGFiYXNlQ2VudGVyLlYxQmV0YcoCIkdvb2ds
ZVxDbG91ZFxEYXRhYmFzZUNlbnRlclxWMWJldGHqAiVHb29nbGU6OkNsb3VkOjpEYXRhYmFz
ZUNlbnRlcjo6VjFiZXRhSsoVCgYSBA4AUgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQACsKCQoCAwASAxIAKQoICgEIEgMUAD8KCQoCCCUSAxQAPwoICgEI
EgMVAGUKCQoCCAsSAxUAZQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADEKCQoCCAgS
AxcAMQoICgEIEgMYAD8KCQoCCAESAxgAPwoICgEIEgMZAD8KCQoCCCkSAxkAPwoICgEIEgMa
AD4KCQoCCC0SAxoAPgozCgIEABIEHQBSARonIEFmZmlsaWF0aW9uIGluZm9ybWF0aW9uIG9m
IGEgcmVzb3VyY2UKCgoKAwQAARIDHQgTCoQBCgQEAAMAEgQgAi0DGnYgbGluZWFnZSBpbmZv
cm1hdGlvbiBvZiB0aGUgYWZmaWxpYXRlZCByZXNvdXJjZXMKIFRoaXMgY2FwdHVyZXMgc291
cmNlLCB0YXJnZXQgYW5kIHByb2Nlc3Mgd2hpY2ggY3JlYXRlZCB0aGUgbGluZWFnZS4KCgwK
BQQAAwABEgMgChEKNwoGBAADAAIAEgMiBEMaKCBPcHRpb25hbC4gRlFOIG9mIHNvdXJjZSB0
YWJsZSAvIGNvbHVtbgoKDgoHBAADAAIABRIDIgQKCg4KBwQAAwACAAESAyILFQoOCgcEAAMA
AgADEgMiGBkKDgoHBAADAAIACBIDIhpCChEKCgQAAwACAAicCAASAyIbQQo3CgYEAAMAAgES
AyUEQxooIE9wdGlvbmFsLiBGUU4gb2YgdGFyZ2V0IHRhYmxlIC8gY29sdW1uCgoOCgcEAAMA
AgEFEgMlBAoKDgoHBAADAAIBARIDJQsVCg4KBwQAAwACAQMSAyUYGQoOCgcEAAMAAgEIEgMl
GkIKEQoKBAADAAIBCJwIABIDJRtBCmMKBgQAAwACAhIDKQREGlQgT3B0aW9uYWwuIEZRTiBv
ZiBwcm9jZXNzIHdoaWNoIGNyZWF0ZWQgdGhlIGxpbmVhZ2UgaS5lLiBkYXRhcGxleCwKIGRh
dGFzdHJlYW0gZXRjLgoKDgoHBAADAAICBRIDKQQKCg4KBwQAAwACAgESAykLFgoOCgcEAAMA
AgIDEgMpGRoKDgoHBAADAAICCBIDKRtDChEKCgQAAwACAgicCAASAykcQgpFCgYEAAMAAgMS
AywESho2IE9wdGlvbmFsLiBUeXBlIG9mIHByb2Nlc3Mgd2hpY2ggY3JlYXRlZCB0aGUgbGlu
ZWFnZS4KCg4KBwQAAwACAwYSAywEDwoOCgcEAAMAAgMBEgMsEBwKDgoHBAADAAIDAxIDLB8g
Cg4KBwQAAwACAwgSAywhSQoRCgoEAAMAAgMInAgAEgMsIkgKOgoEBAAEABIEMAJFAxosIFR5
cGUgb2YgcHJvY2VzcyB3aGljaCBjcmVhdGVkIHRoZSBsaW5lYWdlLgoKDAoFBAAEAAESAzAH
EgoqCgYEAAQAAgASAzIEIRobIFVuc3BlY2lmaWVkIHByb2Nlc3MgdHlwZS4KCg4KBwQABAAC
AAESAzIEHAoOCgcEAAQAAgACEgMyHyAKJwoGBAAEAAIBEgM1BBEaGCBDb21wb3NlciBwcm9j
ZXNzIHR5cGUuCgoOCgcEAAQAAgEBEgM1BAwKDgoHBAAEAAIBAhIDNQ8QCikKBgQABAACAhID
OAQTGhogRGF0YXN0cmVhbSBwcm9jZXNzIHR5cGUuCgoOCgcEAAQAAgIBEgM4BA4KDgoHBAAE
AAICAhIDOBESCicKBgQABAACAxIDOwQRGhggRGF0YWZsb3cgcHJvY2VzcyB0eXBlLgoKDgoH
BAAEAAIDARIDOwQMCg4KBwQABAACAwISAzsPEAonCgYEAAQAAgQSAz4EERoYIEJpZ3F1ZXJ5
IHByb2Nlc3MgdHlwZS4KCg4KBwQABAACBAESAz4EDAoOCgcEAAQAAgQCEgM+DxAKKgoGBAAE
AAIFEgNBBBQaGyBEYXRhIGZ1c2lvbiBwcm9jZXNzIHR5cGUuCgoOCgcEAAQAAgUBEgNBBA8K
DgoHBAAEAAIFAhIDQRITCicKBgQABAACBhIDRAQRGhggRGF0YXByb2MgcHJvY2VzcyB0eXBl
LgoKDgoHBAAEAAIGARIDRAQMCg4KBwQABAACBgISA0QPEAo7CgQEAAIAEgNIAkIaLiBPcHRp
b25hbC4gcmVzb3VyY2UgaWQgb2YgYWZmaWxpYXRlZCByZXNvdXJjZQoKDAoFBAACAAUSA0gC
CAoMCgUEAAIAARIDSAkUCgwKBQQAAgADEgNIFxgKDAoFBAACAAgSA0gZQQoPCggEAAIACJwI
ABIDSBpACisKBAQAAgESA0sCSRoeIE9wdGlvbmFsLiBGdWxsIHJlc291cmNlIG5hbWUKCgwK
BQQAAgEFEgNLAggKDAoFBAACAQESA0sJGwoMCgUEAAIBAxIDSx4fCgwKBQQAAgEIEgNLIEgK
DwoIBAACAQicCAASA0shRwr0AQoEBAACAhIDUQJJGuYBIE9wdGlvbmFsLiBNdWx0aXBsZSBs
aW5lYWdlcyBjYW4gYmUgY3JlYXRlZCBmcm9tIGEgcmVzb3VyY2UuCiBGb3IgZXhhbXBsZSwg
YSByZXNvdXJjZSBjYW4gYmUgcmVwbGljYXRlZCB0byBtdWx0aXBsZSB0YXJnZXQgcmVzb3Vy
Y2VzLgogSW4gdGhpcyBjYXNlLCB0aGVyZSB3aWxsIGJlIG11bHRpcGxlIGxpbmVhZ2VzIGZv
ciB0aGUgcmVzb3VyY2UsIG9uZSBmb3IKIGVhY2ggdGFyZ2V0IHJlc291cmNlLgoKDAoFBAAC
AgQSA1ECCgoMCgUEAAICBhIDUQsSCgwKBQQAAgIBEgNRExsKDAoFBAACAgMSA1EeHwoMCgUE
AAICCBIDUSBICg8KCAQAAgIInAgAEgNRIUdiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Databasecenter::V1beta::Affiliation::Affiliation ===
    # Fields for Affiliation
    # Field: resource_id Type: 9 ()
    # Field: full_resource_name Type: 9 ()
    # Field: lineages Type: 11 (.google.cloud.databasecenter.v1beta.Affiliation.Lineage)

# Enum: Affiliation::ProcessType
our $Affiliation_PROCESS_TYPE_UNSPECIFIED = 0;
our $Affiliation_COMPOSER = 1;
our $Affiliation_DATASTREAM = 2;
our $Affiliation_DATAFLOW = 3;
our $Affiliation_BIGQUERY = 4;
our $Affiliation_DATA_FUSION = 5;
our $Affiliation_DATAPROC = 6;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Databasecenter::V1beta::Affiliation - Compiled Protocol Buffers messages for google/cloud/databasecenter/v1beta/affiliation.proto

=head1 SYNOPSIS

    use Google::Cloud::Databasecenter::V1beta::Affiliation;

    my $msg = Google::Cloud::Databasecenter::V1beta::Affiliation::Affiliation->new({
        resource_id => $resource_id,
        full_resource_name => $full_resource_name,
        lineages => $lineages,
    });

    # Read or update a field
    my $val = $msg->resource_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Databasecenter::V1beta::Affiliation::Affiliation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/databasecenter/v1beta/affiliation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Databasecenter::V1beta::Affiliation::Affiliation

Affiliation information of a resource

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_id() >> / C<< $msg->resource_id($value) >>

Type: C<String>

Optional. resource id of affiliated resource

=item * C<< $msg->full_resource_name() >> / C<< $msg->full_resource_name($value) >>

Type: C<String>

Optional. Full resource name

=item * C<< $msg->lineages() >> / C<< $msg->lineages($value) >>

Type: C<Message> (L<Google::Cloud::Databasecenter::V1beta::Affiliation::Affiliation::Lineage>)

Optional. Multiple lineages can be created from a resource.
For example, a resource can be replicated to multiple target resources.
In this case, there will be multiple lineages for the resource, one for
each target resource.

=back

=head3 Enum: Affiliation::ProcessType

=over 4

=item * C<PROCESS_TYPE_UNSPECIFIED> => C<0>

=item * C<COMPOSER> => C<1>

=item * C<DATASTREAM> => C<2>

=item * C<DATAFLOW> => C<3>

=item * C<BIGQUERY> => C<4>

=item * C<DATA_FUSION> => C<5>

=item * C<DATAPROC> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Databasecenter::V1beta::Affiliation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
