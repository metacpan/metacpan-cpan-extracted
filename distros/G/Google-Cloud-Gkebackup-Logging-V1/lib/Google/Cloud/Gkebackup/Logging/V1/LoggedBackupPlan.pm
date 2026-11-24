package Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Gkebackup::Logging::V1::LoggedCommon };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvZ2tlYmFja3VwL2xvZ2dpbmcvdjEvbG9nZ2VkX2JhY2t1cF9wbGFu
LnByb3RvEiFnb29nbGUuY2xvdWQuZ2tlYmFja3VwLmxvZ2dpbmcudjEaNWdvb2dsZS9jbG91
ZC9na2ViYWNrdXAvbG9nZ2luZy92MS9sb2dnZWRfY29tbW9uLnByb3RvIo8KChBMb2dnZWRC
YWNrdXBQbGFuEiAKC2Rlc2NyaXB0aW9uGAEgASgJUgtkZXNjcmlwdGlvbhIYCgdjbHVzdGVy
GAIgASgJUgdjbHVzdGVyEm4KEHJldGVudGlvbl9wb2xpY3kYAyABKAsyQy5nb29nbGUuY2xv
dWQuZ2tlYmFja3VwLmxvZ2dpbmcudjEuTG9nZ2VkQmFja3VwUGxhbi5SZXRlbnRpb25Qb2xp
Y3lSD3JldGVudGlvblBvbGljeRJXCgZsYWJlbHMYBCADKAsyPy5nb29nbGUuY2xvdWQuZ2tl
YmFja3VwLmxvZ2dpbmcudjEuTG9nZ2VkQmFja3VwUGxhbi5MYWJlbHNFbnRyeVIGbGFiZWxz
EmUKD2JhY2t1cF9zY2hlZHVsZRgFIAEoCzI8Lmdvb2dsZS5jbG91ZC5na2ViYWNrdXAubG9n
Z2luZy52MS5Mb2dnZWRCYWNrdXBQbGFuLlNjaGVkdWxlUg5iYWNrdXBTY2hlZHVsZRIgCgtk
ZWFjdGl2YXRlZBgGIAEoCFILZGVhY3RpdmF0ZWQSZQoNYmFja3VwX2NvbmZpZxgHIAEoCzJA
Lmdvb2dsZS5jbG91ZC5na2ViYWNrdXAubG9nZ2luZy52MS5Mb2dnZWRCYWNrdXBQbGFuLkJh
Y2t1cENvbmZpZ1IMYmFja3VwQ29uZmlnEigKDnJwb19yaXNrX2xldmVsGAggASgFQgIYAVIM
cnBvUmlza0xldmVsGo4BCg9SZXRlbnRpb25Qb2xpY3kSNQoXYmFja3VwX2RlbGV0ZV9sb2Nr
X2RheXMYASABKAVSFGJhY2t1cERlbGV0ZUxvY2tEYXlzEiwKEmJhY2t1cF9yZXRhaW5fZGF5
cxgCIAEoBVIQYmFja3VwUmV0YWluRGF5cxIWCgZsb2NrZWQYAyABKAhSBmxvY2tlZBpHCghT
Y2hlZHVsZRIjCg1jcm9uX3NjaGVkdWxlGAEgASgJUgxjcm9uU2NoZWR1bGUSFgoGcGF1c2Vk
GAIgASgIUgZwYXVzZWQaxgMKDEJhY2t1cENvbmZpZxInCg5hbGxfbmFtZXNwYWNlcxgBIAEo
CEgAUg1hbGxOYW1lc3BhY2VzEmAKE3NlbGVjdGVkX25hbWVzcGFjZXMYAiABKAsyLS5nb29n
bGUuY2xvdWQuZ2tlYmFja3VwLmxvZ2dpbmcudjEuTmFtZXNwYWNlc0gAUhJzZWxlY3RlZE5h
bWVzcGFjZXMSaQoVc2VsZWN0ZWRfYXBwbGljYXRpb25zGAMgASgLMjIuZ29vZ2xlLmNsb3Vk
LmdrZWJhY2t1cC5sb2dnaW5nLnYxLk5hbWVzcGFjZWROYW1lc0gAUhRzZWxlY3RlZEFwcGxp
Y2F0aW9ucxIuChNpbmNsdWRlX3ZvbHVtZV9kYXRhGAQgASgIUhFpbmNsdWRlVm9sdW1lRGF0
YRInCg9pbmNsdWRlX3NlY3JldHMYBSABKAhSDmluY2x1ZGVTZWNyZXRzElcKDmVuY3J5cHRp
b25fa2V5GAYgASgLMjAuZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC5sb2dnaW5nLnYxLkVuY3J5
cHRpb25LZXlSDWVuY3J5cHRpb25LZXlCDgoMYmFja3VwX3Njb3BlGjkKC0xhYmVsc0VudHJ5
EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAFC7QEKIWdvb2ds
ZS5jbG91ZC5na2ViYWNrdXAubG9nZ2luZy52MUIVTG9nZ2VkQmFja3VwUGxhblByb3RvUAFa
P2Nsb3VkLmdvb2dsZS5jb20vZ28vZ2tlYmFja3VwL2xvZ2dpbmcvYXBpdjEvbG9nZ2luZ3Bi
O2xvZ2dpbmdwYqoCIUdvb2dsZS5DbG91ZC5Ha2VCYWNrdXAuTG9nZ2luZy5WMcoCIUdvb2ds
ZVxDbG91ZFxHa2VCYWNrdXBcTG9nZ2luZ1xWMeoCJUdvb2dsZTo6Q2xvdWQ6OkdrZUJhY2t1
cDo6TG9nZ2luZzo6VjFKnSEKBhIEDgBxAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAKgoJCgIDABIDEgA/CggKAQgSAxQAPgoJCgIIJRIDFAA+CggKAQgS
AxUAVgoJCgIICxIDFQBWCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcANgoJCgIICBID
FwA2CggKAQgSAxgAOgoJCgIIARIDGAA6CggKAQgSAxkAPwoJCgIIKRIDGQA/CggKAQgSAxoA
PgoJCgIILRIDGgA+CscBCgIEABIEHwBxARq6ASBCYWNrdXBQbGFuIGFzIHN0b3JlZCBpbiBQ
bGF0Zm9ybSBsb2cuIEl0J3MgdXNlZCB0byBsb2cgdGhlIGRldGFpbHMgb2YKIGEgY3JlYXRl
QmFja3VwUGxhbi91cGRhdGVCYWNrdXBQbGFuIHJlcXVlc3QsIHNvIG9ubHkgZmllbGRzIHRo
YXQgY2FuIGJlIHRha2VuCiBmcm9tIHVzZXIgaW5wdXQgYXJlIGluY2x1ZGVkIGhlcmUuCgoK
CgMEAAESAx8IGArzAQoEBAADABIEJAI0AxrkASBSZW50aW9uUG9saWN5IGlzIGFuIGlubmVy
IG1lc3NhZ2UgdHlwZSB0byBkZWZpbmU6CiAxLiBXaGVuIHRvIGF1dG9tYXRpY2FsbHkgZGVs
ZXRlIEJhY2t1cHMgY3JlYXRlZCB1bmRlciB0aGlzIEJhY2t1cFBsYW4KIDIuIEEgcGxhbiBs
ZXZlbCBtaW5pbXVtIEJhY2t1cCByZXRhaW4gZGF5cyB3aGljaCBibG9ja3MgZGVsZXRpb24K
IDMuIExvY2sgdG8gZGlzYWxsb3cgYW55IHBvbGljeSB1cGRhdGVzCgoMCgUEAAMAARIDJAoZ
CnEKBgQAAwACABIDJwQmGmIgTnVtYmVyIG9mIGRheXMgZHVyaW5nIHdoaWNoIGRlbGV0aW9u
IG9mIGEgQmFja3VwIGNyZWF0ZWQgdW5kZXIgdGhpcwogQmFja3VwUGxhbiB3aWxsIGJlIGJs
b2NrZWQuCgoOCgcEAAMAAgAFEgMnBAkKDgoHBAADAAIAARIDJwohCg4KBwQAAwACAAMSAyck
JQrcAQoGBAADAAIBEgMtBCEazAEgTnVtYmVyIG9mIGRheXMgYWZ0ZXIgd2hpY2ggdGhlIHNl
cnZpY2Ugd2lsbCBkZWxldGUgYSBCYWNrdXAuCiBJZiBzcGVjaWZpZWQsIGEgQmFja3VwIGNy
ZWF0ZWQgdW5kZXIgdGhpcyBCYWNrdXBQbGFuIHdpbGwgYmUKIGF1dG9tYXRpY2FsbHkgZGVs
ZXRlZCBhZnRlciBpdHMgYWdlIHJlYWNoZXMgY3JlYXRlX3RpbWUgKwogYmFja3VwX3JldGFp
bl9kYXlzLgoKDgoHBAADAAIBBRIDLQQJCg4KBwQAAwACAQESAy0KHAoOCgcEAAMAAgEDEgMt
HyAKzwEKBgQAAwACAhIDMwQUGr8BIEEgZmxhZyBkZW5vdGVzIHRoYXQgdGhlIHJldGVudGlv
biBwb2xpY3kgb2YgdGhpcyBCYWNrdXBQbGFuIGlzIGxvY2tlZC4KIElmIHNldCB0byBUcnVl
LCBubyBmdXJ0aGVyIHVwZGF0ZSBpcyBhbGxvd2VkIG9uIHRoaXMgcG9saWN5LCBpbmNsdWRp
bmcKIHRoZSAnbG9ja2VkJyBmaWVsZCBpdHNlbGYuCiBEZWZhdWx0IHRvIEZhbHNlLgoKDgoH
BAADAAICBRIDMwQICg4KBwQAAwACAgESAzMJDwoOCgcEAAMAAgIDEgMzEhMKSAoEBAADARIE
NwI9Axo6IFNjaGVkdWxlLCBhbiBpbm5lciBtZXNzYWdlIHR5cGUgZGVmaW5lcyBhIGNyb24g
c2NoZWR1bGUuCgoMCgUEAAMBARIDNwoSClUKBgQAAwECABIDOQQdGkYgQSBjcm9uIHN0eWxl
IHN0cmluZyBzY2hlZHVsZSBvbiB3aGljaCBhbiBvcGVyYXRpb24gd2lsbCBiZSBleGVjdXRl
ZC4KCg4KBwQAAwECAAUSAzkECgoOCgcEAAMBAgABEgM5CxgKDgoHBAADAQIAAxIDORscCjYK
BgQAAwECARIDPAQUGicgQSBmbGFnIHRvIHRvZ2dsZSBzY2hlZHVsZWQgb3BlcmF0aW9uLgoK
DgoHBAADAQIBBRIDPAQICg4KBwQAAwECAQESAzwJDwoOCgcEAAMBAgEDEgM8EhMKeAoEBAAD
AhIEQQJWAxpqIEJhY2t1cENvbmZpZywgYW4gaW5uZXIgbWVzc2FnZSB0eXBlIGRlZmluZXMg
dGhlIGNvbmZpZ3VyYXRpb24gb2YgY3JlYXRpbmcKIGEgYmFja3VwIGZyb20gdGhpcyBCYWNr
dXBQbGFuCgoMCgUEAAMCARIDQQoWCg4KBgQAAwIIABIEQgRLBQoOCgcEAAMCCAABEgNCChYK
NQoGBAADAgIAEgNEBh4aJiBJZiBzZXQgdG8gdHJ1ZSwgYmFja3VwIHdob2xlIGNsdXN0ZXIK
Cg4KBwQAAwICAAUSA0QGCgoOCgcEAAMCAgABEgNECxkKDgoHBAADAgIAAxIDRBwdCjYKBgQA
AwICARIDRwYpGicgSWYgc2V0LCBiYWNrdXAgdGhlIGxpc3Qgb2YgbmFtZXNwYWNlcwoKDgoH
BAADAgIBBhIDRwYQCg4KBwQAAwICAQESA0cRJAoOCgcEAAMCAgEDEgNHJygKOAoGBAADAgIC
EgNKBjAaKSBJZiBzZXQsIGJhY2t1cCB0aGUgbGlzdCBvZiBhcHBsaWNhdGlvbnMKCg4KBwQA
AwICAgYSA0oGFQoOCgcEAAMCAgIBEgNKFisKDgoHBAADAgICAxIDSi4vClEKBgQAAwICAxID
TgQhGkIgQSBib29sZWFuIGZsYWcgc3BlY2lmaWVzIHdoZXRoZXIgdm9sdW1lIGRhdGEgc2hv
dWxkIGJlIGJhY2tlZCB1cAoKDgoHBAADAgIDBRIDTgQICg4KBwQAAwICAwESA04JHAoOCgcE
AAMCAgMDEgNOHyAKTQoGBAADAgIEEgNRBB0aPiBBIGJvb2xlYW4gZmxhZyBzcGVjaWZpZXMg
d2hldGhlciBzZWNyZXRzIHNob3VsZCBiZSBiYWNrZWQgdXAKCg4KBwQAAwICBAUSA1EECAoO
CgcEAAMCAgQBEgNRCRgKDgoHBAADAgIEAxIDURscCoUBCgYEAAMCAgUSA1UEJRp2IEN1c3Rv
bSBlbmNyeXB0aW9uIGtleS4gRm9yIHByZXZpZXcsIHN1cHBvcnQgR0NQIEtNUyBvbmx5Lgog
VGhpcyBvbmx5IGNvbnRhaW5zIHRoZSBrZXkgbWV0YWRhdGEsIGFuZCBubyBrZXkgbWF0ZXJp
YWwuCgoOCgcEAAMCAgUGEgNVBBEKDgoHBAADAgIFARIDVRIgCg4KBwQAAwICBQMSA1UjJApF
CgQEAAIAEgNZAhkaOCBVc2VyIHNwZWNpZmllZCBkZXNjcmlwdGl2ZSBzdHJpbmcgZm9yIHRo
aXMgQmFja3VwUGxhbi4KCgwKBQQAAgAFEgNZAggKDAoFBAACAAESA1kJFAoMCgUEAAIAAxID
WRcYCksKBAQAAgESA1wCFRo+IEdDUCByZXNvdXJjZSBuYW1lIG9mIHRoZSBzb3VyY2UgY2x1
c3RlciBmb3IgdGhpcyBCYWNrdXBQbGFuLgoKDAoFBAACAQUSA1wCCAoMCgUEAAIBARIDXAkQ
CgwKBQQAAgEDEgNcExQKVAoEBAACAhIDXwInGkcgUmV0ZW50aW9uUG9saWN5IGdvdmVybnMg
bGlmZWN5Y2xlIG9mIEJhY2t1cHMgY3JlYXRlZCB1bmRlciB0aGlzIHBsYW4uCgoMCgUEAAIC
BhIDXwIRCgwKBQQAAgIBEgNfEiIKDAoFBAACAgMSA18lJgo3CgQEAAIDEgNiAiEaKiBBIHNl
dCBvZiBjdXN0b20gbGFiZWxzIHN1cHBsaWVkIGJ5IHVzZXIuCgoMCgUEAAIDBhIDYgIVCgwK
BQQAAgMBEgNiFhwKDAoFBAACAwMSA2IfIApHCgQEAAIEEgNlAh8aOiBEZWZpbmVzIHNjaGVk
dWxlZCBCYWNrdXAgY3JlYXRpb24gdW5kZXIgdGhpcyBCYWNrdXBQbGFuLgoKDAoFBAACBAYS
A2UCCgoMCgUEAAIEARIDZQsaCgwKBQQAAgQDEgNlHR4KRgoEBAACBRIDaAIXGjkgQSBmbGFn
IGluZGljYXRlcyB3aGV0aGVyIHRoZSBwbGFuIGhhcyBiZWVuIGRlYWN0aXZhdGVkLgoKDAoF
BAACBQUSA2gCBgoMCgUEAAIFARIDaAcSCgwKBQQAAgUDEgNoFRYKPwoEBAACBhIDawIhGjIg
RGVmaW5lcyBiYWNrdXAgY29uZmlndXJhdGlvbiBvZiB0aGlzIEJhY2t1cFBsYW4uCgoMCgUE
AAIGBhIDawIOCgwKBQQAAgYBEgNrDxwKDAoFBAACBgMSA2sfIArZAQoEBAACBxIDcAIvGssB
IEEgbnVtYmVyIHRoYXQgcmVwcmVzZW50cyB0aGUgY3VycmVudCByaXNrIGxldmVsIG9mIHRo
aXMgQmFja3VwUGxhbiBmcm9tIFJQTwogcGVyc3BlY3RpdmUgd2l0aCAxIGJlaW5nIG5vIHJp
c2sgYW5kIDUgYmVpbmcgaGlnaGVzdCByaXNrLgogRGVwcmVjYXRlZDogVXNlIExvZ2dlZEJh
Y2t1cFBsYW5NZXRhZGF0YS5ycG9fcmlza19sZXZlbCBpbnN0ZWFkLgoKDAoFBAACBwUSA3AC
BwoMCgUEAAIHARIDcAgWCgwKBQQAAgcDEgNwGRoKDAoFBAACBwgSA3AbLgoNCgYEAAIHCAMS
A3AcLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan ===
    # Fields for LoggedBackupPlan
    # Field: description Type: 9 ()
    # Field: cluster Type: 9 ()
    # Field: retention_policy Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedBackupPlan.RetentionPolicy)
    # Field: labels Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedBackupPlan.LabelsEntry)
    # Field: backup_schedule Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedBackupPlan.Schedule)
    # Field: deactivated Type: 8 ()
    # Field: backup_config Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedBackupPlan.BackupConfig)
    # Field: rpo_risk_level Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan - Compiled Protocol Buffers messages for google/cloud/gkebackup/logging/v1/logged_backup_plan.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan;

    my $msg = Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan->new({
        description => $description,
        cluster => $cluster,
        retention_policy => $retention_policy,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->description();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/logging/v1/logged_backup_plan.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan

BackupPlan as stored in Platform log. It's used to log the details of
a createBackupPlan/updateBackupPlan request, so only fields that can be taken
from user input are included here.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

User specified descriptive string for this BackupPlan.

=item * C<< $msg->cluster() >> / C<< $msg->cluster($value) >>

Type: C<String>

GCP resource name of the source cluster for this BackupPlan.

=item * C<< $msg->retention_policy() >> / C<< $msg->retention_policy($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::RetentionPolicy>)

RetentionPolicy governs lifecycle of Backups created under this plan.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::LabelsEntry>)

A set of custom labels supplied by user.

=item * C<< $msg->backup_schedule() >> / C<< $msg->backup_schedule($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::Schedule>)

Defines scheduled Backup creation under this BackupPlan.

=item * C<< $msg->deactivated() >> / C<< $msg->deactivated($value) >>

Type: C<Bool>

A flag indicates whether the plan has been deactivated.

=item * C<< $msg->backup_config() >> / C<< $msg->backup_config($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::BackupConfig>)

Defines backup configuration of this BackupPlan.

=item * C<< $msg->rpo_risk_level() >> / C<< $msg->rpo_risk_level($value) >>

Type: C<Int32>

A number that represents the current risk level of this BackupPlan from RPO
perspective with 1 being no risk and 5 being highest risk.
Deprecated: Use LoggedBackupPlanMetadata.rpo_risk_level instead.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
